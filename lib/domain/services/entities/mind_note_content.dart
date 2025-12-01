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
  const MindNoteAudio({required this.appRelativeAbsoulutePath});

  final String appRelativeAbsoulutePath;

  bool get isEmpty => appRelativeAbsoulutePath.trim().isEmpty;

  @override
  String toString() => 'MindNoteAudio($appRelativeAbsoulutePath)';
}

final class MindNoteContent {
  List<MindNoteAudio> get audioPieces => _pieces.whereType<MindNoteAudio>().toList(growable: false);
  bool get hasAudio => audioPieces.isNotEmpty;

  const MindNoteContent._(this._pieces);

  factory MindNoteContent.empty() => const MindNoteContent._([]);

  factory MindNoteContent.parse(String note) {
    if (note.isEmpty) {
      return const MindNoteContent._([]);
    }

    final List<BaseMindNotePiece> pieces = [];
    final RegExp tagRegExp = RegExp('<$kMindAudioTag>(.*?)</$kMindAudioTag>', caseSensitive: false, dotAll: true);

    int cursor = 0;
    final Iterable<RegExpMatch> matches = tagRegExp.allMatches(note);

    for (final RegExpMatch match in matches) {
      if (match.start > cursor) {
        pieces.add(MindNoteText(note.substring(cursor, match.start)));
      }
      final String rawPath = match.group(1) ?? '';
      final String trimmedPath = rawPath.trim();
      if (trimmedPath.isNotEmpty) {
        pieces.add(MindNoteAudio(appRelativeAbsoulutePath: trimmedPath));
      }
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
          audio: (MindNoteAudio audioPiece) =>
              '<$kMindAudioTag>${audioPiece.appRelativeAbsoulutePath}</$kMindAudioTag>',
          unknown: () => '',
        ),
      )
      .join();

  MindNoteContent copyWithAppendedAudio(String path, {String? separator}) {
    final List<BaseMindNotePiece> updated = List<BaseMindNotePiece>.of(_pieces);
    if (separator != null && separator.isNotEmpty) {
      updated.add(MindNoteText(separator));
    }
    updated.add(MindNoteAudio(appRelativeAbsoulutePath: path));
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
