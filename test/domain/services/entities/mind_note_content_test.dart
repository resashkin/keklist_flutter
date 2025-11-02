import 'package:flutter_test/flutter_test.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/domain/services/entities/mind_note_content.dart';

void main() {
  group('MindNoteContent parsing', () {
    test('parses plain text without tags', () {
      const String note = 'Just a simple thought.';

      final MindNoteContent content = MindNoteContent.parse(note);

      expect(content.pieces.length, 1);
      expect(content.plainText, note);
      expect(content.audioPieces, isEmpty);
      expect(content.toRawNoteString(), note);
    });

    test('parses single audio tag with surrounding text', () {
      const String rawNote = 'Hello <kekaudio>/storage/audio_1.m4a</kekaudio>world';

      final MindNoteContent content = MindNoteContent.parse(rawNote);

      expect(content.pieces.length, 3);
      expect(content.pieces[0], isA<MindNoteText>());
      expect(content.pieces[1], isA<MindNoteAudio>());
      expect(content.pieces[2], isA<MindNoteText>());
      expect(content.plainText, 'Hello world');
      expect(content.audioPieces.single.appRelativeAbsoulutePath, '/storage/audio_1.m4a');
      expect(content.toRawNoteString(), rawNote);
    });

    test('multiple audio tags keep their order', () {
      const String rawNote =
          'Intro<kekaudio> /storage/audio_a.m4a </kekaudio>middle<kekaudio>/storage/audio_b.m4a</kekaudio>outro';

      final MindNoteContent content = MindNoteContent.parse(rawNote);

      expect(content.audioPieces.length, 2);
      expect(content.audioPieces.first.appRelativeAbsoulutePath, '/storage/audio_a.m4a');
      expect(content.audioPieces.last.appRelativeAbsoulutePath, '/storage/audio_b.m4a');
      expect(content.plainText, 'Intromiddleoutro');
      expect(
          content.toRawNoteString(),
          'Intro<kekaudio>/storage/audio_a.m4a</kekaudio>middle'
          '<kekaudio>/storage/audio_b.m4a</kekaudio>outro');
    });

    test('appendAudio adds new tag and optional separator', () {
      const String rawNote = 'Note body';
      final MindNoteContent content = MindNoteContent.parse(rawNote);

      final MindNoteContent updated = content.copyWithAppendedAudio('/app/audio/new_note.m4a', separator: '\n');

      expect(updated.audioPieces.single.appRelativeAbsoulutePath, '/app/audio/new_note.m4a');
      expect(updated.toRawNoteString(), 'Note body\n<kekaudio>/app/audio/new_note.m4a</kekaudio>');
    });
  });

  group('Mind note helpers', () {
    Mind buildMind(String note) => Mind(
          id: '1',
          emoji: '🙂',
          note: note,
          dayIndex: 0,
          creationDate: DateTime(2024),
          sortIndex: 0,
          rootId: null,
        );

    test('plainNote hides audio tags', () {
      final Mind mind = buildMind('Hello<kekaudio>/audio/path.m4a</kekaudio>World');

      expect(mind.plainNote, 'HelloWorld');
      expect(mind.audioNotes.length, 1);
    });

    test('appendAudioNote produces new mind with appended audio tag', () {
      final Mind mind = buildMind('Initial');

      final Mind updated = mind.appendAudioNote('/files/audio_2.m4a', separator: '\n');

      expect(updated.note, 'Initial\n<kekaudio>/files/audio_2.m4a</kekaudio>');
      expect(updated.audioNotes.single.appRelativeAbsoulutePath, '/files/audio_2.m4a');
    });
  });
}
