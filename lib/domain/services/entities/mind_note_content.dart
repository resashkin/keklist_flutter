const String kMindAudioTag = 'kekaudio';

sealed class BaseMindNotePiece {
  const BaseMindNotePiece();

  T map<T>({
    required T Function(MindNoteText text) text,
    required T Function(MindNoteAudio audio) audio,
    required T Function() unknown,
  }) {
    final BaseMindNotePiece self = this;
    if (self is MindNoteText) {
      return text(self);
    }
    if (self is MindNoteAudio) {
      return audio(self);
    }
    return unknown();
  }
}

final class MindNoteText extends BaseMindNotePiece {
  const MindNoteText(this.value);

  final String value;

  bool get isEmpty => value.isEmpty;

  @override
  String toString() => 'MindNoteText($value)';
}

final class MindNoteAudio extends BaseMindNotePiece {
  const MindNoteAudio({
    required this.appRelativeAbsoulutePath,
    this.durationSeconds,
  });

  final String appRelativeAbsoulutePath;
  final double? durationSeconds; // null for legacy format

  bool get isEmpty => appRelativeAbsoulutePath.trim().isEmpty;
  bool get hasDuration => durationSeconds != null;

  Duration? get duration => durationSeconds != null
      ? Duration(milliseconds: (durationSeconds! * 1000).round())
      : null;

  @override
  String toString() => 'MindNoteAudio($appRelativeAbsoulutePath${hasDuration ? ', duration: ${durationSeconds}s' : ''})';
}

final class MindNoteContent {
  List<MindNoteAudio> get audioPieces => _pieces.whereType<MindNoteAudio>().toList(growable: false);
  bool get hasAudio => audioPieces.isNotEmpty;

  const MindNoteContent._(this._pieces);

  factory MindNoteContent.empty() => const MindNoteContent._([]);

  factory MindNoteContent.fromPieces(List<BaseMindNotePiece> pieces) =>
      MindNoteContent._(pieces);

  factory MindNoteContent.parse(String note) {
    if (note.isEmpty) {
      return const MindNoteContent._([]);
    }

    final List<BaseMindNotePiece> pieces = [];

    // New format: <kekaudio path="..." duration="..."/>
    final RegExp newFormatRegExp = RegExp(
      '<$kMindAudioTag\\s+path="([^"]+)"\\s+duration="([^"]+)"\\s*/>',
      caseSensitive: false,
    );

    // Old format: <kekaudio>...</kekaudio>
    final RegExp oldFormatRegExp = RegExp(
      '<$kMindAudioTag>(.*?)</$kMindAudioTag>',
      caseSensitive: false,
      dotAll: true,
    );

    // Collect all matches (both old and new formats) with their positions
    final List<_AudioMatch> allMatches = [];

    // Find new format matches
    for (final match in newFormatRegExp.allMatches(note)) {
      final path = match.group(1)?.trim() ?? '';
      final durationStr = match.group(2)?.trim() ?? '';
      final duration = double.tryParse(durationStr);
      if (path.isNotEmpty && duration != null) {
        allMatches.add(_AudioMatch(
          start: match.start,
          end: match.end,
          audio: MindNoteAudio(
            appRelativeAbsoulutePath: path,
            durationSeconds: duration,
          ),
        ));
      }
    }

    // Find old format matches
    for (final match in oldFormatRegExp.allMatches(note)) {
      final path = match.group(1)?.trim() ?? '';
      if (path.isNotEmpty) {
        allMatches.add(_AudioMatch(
          start: match.start,
          end: match.end,
          audio: MindNoteAudio(
            appRelativeAbsoulutePath: path,
            durationSeconds: null, // Legacy format has no duration
          ),
        ));
      }
    }

    // Sort matches by position
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    // Build pieces list
    int cursor = 0;
    for (final match in allMatches) {
      if (match.start > cursor) {
        pieces.add(MindNoteText(note.substring(cursor, match.start)));
      }
      pieces.add(match.audio);
      cursor = match.end;
    }
    if (cursor < note.length) {
      pieces.add(MindNoteText(note.substring(cursor)));
    }

    return MindNoteContent._(pieces);
  }

  final List<BaseMindNotePiece> _pieces;
  List<BaseMindNotePiece> get pieces => List.unmodifiable(_pieces);
  String get plainText => _pieces.whereType<MindNoteText>().map((MindNoteText piece) => piece.value).join();

  String toRawNoteString() => _pieces
      .map(
        (BaseMindNotePiece piece) => piece.map(
          text: (MindNoteText textPiece) => textPiece.value,
          audio: (MindNoteAudio audioPiece) {
            if (audioPiece.hasDuration) {
              // New format with duration
              return '<$kMindAudioTag path="${audioPiece.appRelativeAbsoulutePath}" duration="${audioPiece.durationSeconds}"/>';
            } else {
              // Legacy format for backward compatibility
              return '<$kMindAudioTag>${audioPiece.appRelativeAbsoulutePath}</$kMindAudioTag>';
            }
          },
          unknown: () => '',
        ),
      )
      .join();

  MindNoteContent copyWithAppendedAudio(String path, {String? separator, double? durationSeconds}) {
    final List<BaseMindNotePiece> updated = List<BaseMindNotePiece>.of(_pieces);
    if (separator != null && separator.isNotEmpty) {
      updated.add(MindNoteText(separator));
    }
    updated.add(MindNoteAudio(
      appRelativeAbsoulutePath: path,
      durationSeconds: durationSeconds,
    ));
    return MindNoteContent._(updated);
  }

  MindNoteContent copyWithAppendedText(String value) {
    if (value.isEmpty) {
      return this;
    }
    final List<BaseMindNotePiece> updated = List<BaseMindNotePiece>.of(_pieces);
    updated.add(MindNoteText(value));
    return MindNoteContent._(updated);
  }

  /// Convenience to create a new note from raw text with an optional audio path.
  factory MindNoteContent.fromTextAndAudio({required String text, Iterable<String> audioPaths = const []}) {
    final List<BaseMindNotePiece> pieces = [
      if (text.isNotEmpty) MindNoteText(text),
      ...audioPaths
          .where((path) => path.trim().isNotEmpty)
          .map((path) => MindNoteAudio(appRelativeAbsoulutePath: path.trim())),
    ];
    return MindNoteContent._(pieces);
  }

  @override
  String toString() => 'MindNoteContent($_pieces)';
}

/// Helper class to track audio matches during parsing
class _AudioMatch {
  final int start;
  final int end;
  final MindNoteAudio audio;

  _AudioMatch({
    required this.start,
    required this.end,
    required this.audio,
  });
}
