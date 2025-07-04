import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:keklist/presentation/core/helpers/platform_utils.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:keklist/presentation/blocs/settings_bloc/settings_bloc.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/screens/auth/widgets/auth_button.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:keklist/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'package:keklist/domain/constants.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';

final class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  AuthScreenState createState() => AuthScreenState();
}

final class AuthScreenState extends State<AuthScreen> with DisposeBag {
  final TextEditingController _loginTextEditingController = TextEditingController();
  final TextEditingController _passwordTextEditingController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    subscribeToBloc<AuthBloc>(
      onNewState: (state) {
        switch (state) {
          case AuthCurrentState status when status.isLoggedIn:
            _dismiss();
        }
      },
    )?.disposed(by: this);

    subscribeToBloc<SettingsBloc>(
      onNewState: (state) {
        if (state is SettingsDataState && state.settings.isOfflineMode) {
          _dismiss();
        }
      },
    )?.disposed(by: this);
  }

  void _dismiss() {
    cancelSubscriptions(); // TODO: what the point?
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: ModalScrollController.of(context),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Material(
          child: Stack(
            children: [
              // cross button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _dismiss,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16.0),
                  Text(
                    'Sign up',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16.0),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      validator: MultiValidator(
                        [
                          EmailValidator(errorText: 'Enter a valid email address'),
                          MinLengthValidator(4, errorText: 'Please enter email'),
                        ],
                      ).call,
                      controller: _loginTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(8),
                        border: const UnderlineInputBorder(),
                        hintText: 'Email',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                    onPressed: () async {
                      if (_loginTextEditingController.text == KeklistConstants.demoAccountEmail) {
                        _displayTextInputDialog(
                          context,
                          onPressed: () {
                            context.read<AuthBloc>().add(
                                  AuthLoginWithEmailAndPassword(
                                    email: _loginTextEditingController.text,
                                    password: _passwordTextEditingController.text,
                                  ),
                                );
                          },
                        );
                        return;
                      }
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }
                      context.read<AuthBloc>().add(AuthLoginWithEmail(_loginTextEditingController.text));
                      // TODO: показать алерт на экшен в блоке.
                      // showOkAlertDialog(
                      //   context: context,
                      //   title: 'Success',
                      //   message: 'Please, go to your email app and open magic link',
                      // );

                      final List<String>? result = await showTextInputDialog(
                        title: 'Enter code from email - ${_loginTextEditingController.text}',
                        autoSubmit: true,
                        okLabel: 'Verify',
                        context: context,
                        textFields: [
                          DialogTextField(
                            autocorrect: false,
                            keyboardType: TextInputType.number,
                          )
                        ],
                      );

                      if (result != null && result.first.isNotEmpty) {
                        sendEventToBloc<AuthBloc>(
                          AuthVerifyOTP(
                            email: _loginTextEditingController.text,
                            token: result.first,
                          ),
                        );
                      }
                    },
                    child: SizedBox(
                      width: 100,
                      height: 44,
                      child: Center(
                          child: Text(
                        'Get magic link',
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                      )),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Text(
                    'or continue with social networks:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BoolWidget(
                        condition: DeviceUtils.safeGetPlatform() == SupportedPlatform.iOS,
                        trueChild: Row(
                          children: [
                            AuthButton(
                              onTap: () => sendEventToBloc<AuthBloc>(AuthLoginWithSocialNetwork.apple()),
                              type: AuthButtonType.apple,
                            ),
                            const SizedBox(width: 16.0),
                          ],
                        ),
                        falseChild: const SizedBox.shrink(),
                      ),
                      AuthButton(
                        onTap: () => sendEventToBloc<AuthBloc>(AuthLoginWithSocialNetwork.google()),
                        type: AuthButtonType.google,
                      ),
                      const SizedBox(width: 16.0),
                      AuthButton(
                        onTap: () => sendEventToBloc<AuthBloc>(AuthLoginWithSocialNetwork.facebook()),
                        type: AuthButtonType.facebook,
                      ),
                      const SizedBox(width: 16.0),
                    ],
                  ),
                  const SizedBox(height: 32.0),
                  TextButton(
                    onPressed: () => launchUrlString(KeklistConstants.termsOfUseURL),
                    child: Text(
                      'Terms of use',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    cancelSubscriptions();
  }

  Future<void> _displayTextInputDialog(
    BuildContext context, {
    required VoidCallback onPressed,
  }) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Password'),
          content: TextField(
            controller: _passwordTextEditingController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(
              hintText: "Enter password",
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: onPressed,
              ),
            ),
          ),
        );
      },
    );
  }
}
