import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:full_swipe_back_gesture/full_swipe_back_gesture.dart';
import 'package:gap/gap.dart';
import 'package:keklist/presentation/blocs/user_profile_bloc/user_profile_bloc.dart';
import 'package:keklist/presentation/core/dispose_bag.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';
import 'package:keklist/presentation/core/screen/kek_screen_state.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/screens/settings/settings_screen.dart';

// TODO: fill empty sections

final class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

final class _UserProfileScreenState extends KekWidgetState<UserProfileScreen> {
  UserProfileState _userProfileState = UserProfileState(
    nickname: null,
    folders: [],
  );

  @override
  void initState() {
    super.initState();

    context
        .read<UserProfileBloc>()
        .stream
        .listen((state) => setState(() => _userProfileState = state))
        .disposed(by: this);

    context.read<UserProfileBloc>().add(UserProfileGet());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Gap(16.0),
              _UserAvatarPlaceholder(character: _userProfileState.nickname?[0].toUpperCase() ?? 'A'),
              const Gap(8.0),
              GestureDetector(
                child: BoolWidget(
                  condition: _userProfileState.nickname != null && _userProfileState.nickname!.isNotEmpty,
                  trueChild: _UserName(name: '@${_userProfileState.nickname}'),
                  falseChild: const _UserName(name: 'Enter your nickname...'),
                ),
                onTap: () => _showChangeUserName(),
              ),
              const Gap(16.0),
              // const Text(
              //   'Folders',
              //   textAlign: TextAlign.center,
              //   style: TextStyle(
              //     fontSize: 16.0,
              //     fontWeight: FontWeight.w500,
              //     color: Colors.grey,
              //   ),
              // ),
              // _MindsChipsWidget(
              //   minds: _userProfileState.folders,
              //   onCreate: () => _showMindCreator(initialEmoji: '🙂'),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeUserName() async {
    final List<String>? dialogValues = await showTextInputDialog(
      context: context,
      title: context.l10n.updateYourNickname,
      autoSubmit: true,
      textFields: [
        DialogTextField(
          initialText: _userProfileState.nickname,
          hintText: context.l10n.yourNickname,
          prefixText: '@',
          autocorrect: false,
          keyboardType: TextInputType.text,
        )
      ],
    );
    if (dialogValues?.firstOrNull == null) {
      return;
    }
    sendEventToBloc<UserProfileBloc>(UserProfileUpdateNickName(nickName: dialogValues!.first));
  }

  void _showSettings() {
    Navigator.push(
      context,
      BackSwipePageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}

final class _UserName extends StatelessWidget {
  const _UserName({
    required String name,
  }) : _name = name;

  final String _name;

  @override
  Widget build(BuildContext context) {
    return Text(
      _name,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

final class _UserAvatarPlaceholder extends StatelessWidget {
  final String _character;

  const _UserAvatarPlaceholder({required String character}) : _character = character;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        const CircleAvatar(
          radius: 80.0,
          backgroundColor: Colors.blueAccent,
        ),
        Text(
          _character,
          style: const TextStyle(fontSize: 64.0),
        ),
      ],
    );
  }
}
