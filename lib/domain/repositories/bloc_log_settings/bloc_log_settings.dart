final class BlocLogSettings {
  final bool verbose;
  final Set<String> silenced;
  final Set<String> knownBlocs;

  const BlocLogSettings({
    required this.verbose,
    required this.silenced,
    required this.knownBlocs,
  });

  const BlocLogSettings.initial()
      : verbose = false,
        silenced = const {},
        knownBlocs = const {};

  BlocLogSettings copyWith({
    bool? verbose,
    Set<String>? silenced,
    Set<String>? knownBlocs,
  }) {
    return BlocLogSettings(
      verbose: verbose ?? this.verbose,
      silenced: silenced ?? this.silenced,
      knownBlocs: knownBlocs ?? this.knownBlocs,
    );
  }
}
