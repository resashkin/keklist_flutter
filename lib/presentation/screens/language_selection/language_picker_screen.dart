import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keklist/domain/services/language_manager.dart';
import 'package:keklist/presentation/blocs/settings_bloc/settings_bloc.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/helpers/bloc_utils.dart';

final class LanguagePickerScreen extends StatefulWidget {
  const LanguagePickerScreen({super.key});

  @override
  State<LanguagePickerScreen> createState() => _LanguagePickerScreenState();
}

final class _LanguagePickerScreenState extends State<LanguagePickerScreen> {
  SupportedLanguage _currentLanguage = SupportedLanguage.english;

  @override
  void initState() {
    super.initState();
    // Get current language from settings
    final settingsBloc = context.read<SettingsBloc>();
    if (settingsBloc.state is SettingsDataState) {
      _currentLanguage = (settingsBloc.state as SettingsDataState).settings.language;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.selectLanguage)),
      body: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsDataState) {
            setState(() => _currentLanguage = state.settings.language);
          }
        },
        child: ListView.builder(
          itemCount: SupportedLanguage.values.length,
          itemBuilder: (context, index) {
            final language = SupportedLanguage.values[index];
            final isSelected = language == _currentLanguage;

            return ListTile(
              leading: Text(
                language.flag,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(language.displayName),
              trailing: isSelected ? const Icon(Icons.check) : null,
              onTap: () {
                if (!isSelected) {
                  sendEventToBloc<SettingsBloc>(SettingsChangeLanguage(language: language));
                }
              },
            );
          },
        ),
      ),
    );
  }
}
