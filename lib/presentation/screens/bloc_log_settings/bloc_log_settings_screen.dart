import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:keklist/domain/repositories/bloc_log_settings/bloc_log_settings.dart';
import 'package:keklist/domain/repositories/bloc_log_settings/bloc_log_settings_repository.dart';
import 'package:settings_ui/settings_ui.dart';

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
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('Format'),
            tiles: [
              SettingsTile.switchTile(
                title: const Text('Verbose payload'),
                description: const Text(
                  'Append a truncated state payload to each log line. Off: type names only.',
                ),
                initialValue: _settings.verbose,
                onToggle: (value) => _repository.setVerbose(value),
              ),
            ],
          ),
          SettingsSection(
            title: Text('Silence per BLoC (${sortedKnownBlocs.length})'),
            tiles: sortedKnownBlocs.isEmpty
                ? [
                    SettingsTile(
                      title: const Text('No BLoCs observed yet'),
                      description: const Text(
                        'Enable BLoC Logs in the Debug Menu and interact with the app — discovered BLoCs will appear here.',
                      ),
                    ),
                  ]
                : sortedKnownBlocs.map((blocName) {
                    final bool isSilenced = _settings.silenced.contains(blocName);
                    return SettingsTile.switchTile(
                      title: Text(blocName),
                      initialValue: isSilenced,
                      onToggle: (value) => _repository.setSilenced(blocName, value),
                    );
                  }).toList(),
          ),
        ],
      ),
    );
  }
}
