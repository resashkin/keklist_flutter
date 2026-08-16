import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:keklist/domain/repositories/bloc_log_settings/bloc_log_settings.dart';
import 'package:keklist/domain/repositories/bloc_log_settings/bloc_log_settings_repository.dart';
import 'package:keklist/presentation/core/widgets/settings/settings_section.dart';

final class BlocLogSettingsScreen extends StatefulWidget {
  const BlocLogSettingsScreen({super.key});

  @override
  State<BlocLogSettingsScreen> createState() => _BlocLogSettingsScreenState();
}

final class _BlocLogSettingsScreenState extends State<BlocLogSettingsScreen> {
  late final BlocLogSettingsRepository _repository;
  StreamSubscription<BlocLogSettings>? _subscription;
  BlocLogSettings _settings = const BlocLogSettings.initial();

  @override
  void initState() {
    super.initState();
    _repository = Injector().get<BlocLogSettingsRepository>();
    _settings = _repository.value;
    _subscription = _repository.stream.listen((next) {
      if (!mounted) return;
      setState(() => _settings = next);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> sortedKnownBlocs = _settings.knownBlocs.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('BLoC Log Settings')),
      body: SettingsListView(
        children: [
          const SettingsSectionHeader('Format'),
          SettingsSectionCard(
            children: [
              SwitchListTile(
                title: const Text('Verbose payload'),
                subtitle: const Text(
                  'Append a truncated state payload to each log line. Off: type names only.',
                ),
                value: _settings.verbose,
                onChanged: (value) => _repository.setVerbose(value),
              ),
            ],
          ),
          SettingsSectionHeader('Silence per BLoC (${sortedKnownBlocs.length})'),
          SettingsSectionCard(
            children: sortedKnownBlocs.isEmpty
                ? [
                    const ListTile(
                      title: Text('No BLoCs observed yet'),
                      subtitle: Text(
                        'Enable BLoC Logs in the Debug Menu and interact with the app — discovered BLoCs will appear here.',
                      ),
                    ),
                  ]
                : sortedKnownBlocs.map((blocName) {
                    final bool isSilenced = _settings.silenced.contains(blocName);
                    return SwitchListTile(
                      title: Text(blocName),
                      value: isSilenced,
                      onChanged: (value) => _repository.setSilenced(blocName, value),
                    );
                  }).toList(),
          ),
        ],
      ),
    );
  }
}
