
const String kMindAudioTag = 'kekaudio';

sealed class BaseMindNotePiece {
  const BaseMindNotePiece();

  T map<T>({
    required T Function(MindNoteText text) text,
    required T Function(MindNoteAudio audio) audio,
  }) {
    final BaseMindNotePiece self = this;
    if (self is MindNoteText) {
      return text(self);
    }
    if (self is MindNoteAudio) {
      return audio(self);
    }
    throw UnsupportedError('Unknown MindNotePiece: $self');
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

/// Parsed representation of the `Mind.note` string that keeps the original
/// ordering of text and embedded content (e.g. audio tags).
final class MindNoteContent {
  const MindNoteContent._(this._pieces);

  /// Factory that parses the raw note string into structured content.
  factory MindNoteContent.parse(String note) {
    if (note.isEmpty) {
      return const MindNoteContent._([]);
    }

    final List<BaseMindNotePiece> pieces = [];
    final RegExp tagRegExp = RegExp(
      '<$kMindAudioTag>(.*?)</$kMindAudioTag>',
      caseSensitive: false,
      dotAll: true,
    );

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

  /// All pieces in the order they appeared in the raw note string.
  List<BaseMindNotePiece> get pieces => List.unmodifiable(_pieces);

  /// Plain text concatenation of every `MindNoteText` piece.
  String get plainText => _pieces.whereType<MindNoteText>().map((MindNoteText piece) => piece.value).join();

  /// Embedded audio items extracted from the note.
  List<MindNoteAudio> get audioPieces => _pieces.whereType<MindNoteAudio>().toList(growable: false);

  /// Rebuilds a note string with `<kekaudio>` tags using the stored order.
  String toRawNoteString() => _pieces.map((BaseMindNotePiece piece) {
        return piece.map(
          text: (MindNoteText textPiece) => textPiece.value,
          audio: (MindNoteAudio audioPiece) =>
              '<$kMindAudioTag>${audioPiece.appRelativeAbsoulutePath}</$kMindAudioTag>',
        );
      }).join();

  /// Returns a new instance with an additional audio entry appended.
  MindNoteContent appendAudio(String path, {String? separator}) {
    final List<BaseMindNotePiece> updated = List<BaseMindNotePiece>.of(_pieces);

    if (separator != null && separator.isNotEmpty) {
      updated.add(MindNoteText(separator));
    }

    updated.add(MindNoteAudio(appRelativeAbsoulutePath: path));
    return MindNoteContent._(updated);
  }

  /// Returns `true` if at least one audio tag is present.
  bool get hasAudio => audioPieces.isNotEmpty;

  /// Suggests a reasonable default file name for the next audio recording,
  /// based on the amount of audio pieces currently in the note.
  // String buildNextAudioFileName({String prefix = 'mind_audio', String extension = 'm4a'}) {
  //   final String audioId = const Uuid().v4();
  //   return '${prefix}_$audioId.$extension';
  // }

  /// Convenience to create a new note from raw text with an optional audio path.
  factory MindNoteContent.fromTextAndAudio({
    required String text,
    Iterable<String> audioPaths = const [],
  }) {
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
