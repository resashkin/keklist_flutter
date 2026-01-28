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

    test('appendAudio with duration adds new format tag', () {
      const String rawNote = 'Note body';
      final MindNoteContent content = MindNoteContent.parse(rawNote);

      final MindNoteContent updated = content.copyWithAppendedAudio(
        '/app/audio/new_note.m4a',
        separator: '\n',
        durationSeconds: 30.5,
      );

      expect(updated.audioPieces.single.appRelativeAbsoulutePath, '/app/audio/new_note.m4a');
      expect(updated.audioPieces.single.durationSeconds, 30.5);
      expect(updated.audioPieces.single.hasDuration, true);
      expect(updated.toRawNoteString(), 'Note body\n<kekaudio path="/app/audio/new_note.m4a" duration="30.5"/>');
    });

    test('parses new format audio tag with duration', () {
      const String rawNote = 'Hello <kekaudio path="/storage/audio_1.m4a" duration="45.5"/>world';

      final MindNoteContent content = MindNoteContent.parse(rawNote);

      expect(content.pieces.length, 3);
      expect(content.pieces[0], isA<MindNoteText>());
      expect(content.pieces[1], isA<MindNoteAudio>());
      expect(content.pieces[2], isA<MindNoteText>());
      expect(content.plainText, 'Hello world');

      final audio = content.audioPieces.single;
      expect(audio.appRelativeAbsoulutePath, '/storage/audio_1.m4a');
      expect(audio.hasDuration, true);
      expect(audio.durationSeconds, 45.5);
      expect(audio.duration?.inMilliseconds, 45500);
    });

    test('parses mixed old and new format audio tags', () {
      const String rawNote =
          'Start<kekaudio>/old/audio.m4a</kekaudio>middle'
          '<kekaudio path="/new/audio.m4a" duration="30.0"/>end';

      final MindNoteContent content = MindNoteContent.parse(rawNote);

      expect(content.audioPieces.length, 2);

      final oldAudio = content.audioPieces[0];
      expect(oldAudio.appRelativeAbsoulutePath, '/old/audio.m4a');
      expect(oldAudio.hasDuration, false);
      expect(oldAudio.durationSeconds, null);

      final newAudio = content.audioPieces[1];
      expect(newAudio.appRelativeAbsoulutePath, '/new/audio.m4a');
      expect(newAudio.hasDuration, true);
      expect(newAudio.durationSeconds, 30.0);

      expect(content.plainText, 'Startmiddleend');
    });

    test('serializes old format audio without duration', () {
      final content = MindNoteContent.fromPieces([
        const MindNoteText('Hello '),
        const MindNoteAudio(
          appRelativeAbsoulutePath: '/audio/file.m4a',
          durationSeconds: null,
        ),
        const MindNoteText(' world'),
      ]);

      expect(
        content.toRawNoteString(),
        'Hello <kekaudio>/audio/file.m4a</kekaudio> world',
      );
    });

    test('serializes new format audio with duration', () {
      final content = MindNoteContent.fromPieces([
        const MindNoteText('Hello '),
        const MindNoteAudio(
          appRelativeAbsoulutePath: '/audio/file.m4a',
          durationSeconds: 123.45,
        ),
        const MindNoteText(' world'),
      ]);

      expect(
        content.toRawNoteString(),
        'Hello <kekaudio path="/audio/file.m4a" duration="123.45"/> world',
      );
    });

    test('round-trip: parse old format → serialize → parse', () {
      const String original = 'Text<kekaudio>/audio/path.m4a</kekaudio>more';

      final parsed1 = MindNoteContent.parse(original);
      final serialized = parsed1.toRawNoteString();
      final parsed2 = MindNoteContent.parse(serialized);

      expect(serialized, original);
      expect(parsed2.plainText, parsed1.plainText);
      expect(parsed2.audioPieces.length, 1);
      expect(parsed2.audioPieces.first.appRelativeAbsoulutePath, '/audio/path.m4a');
      expect(parsed2.audioPieces.first.hasDuration, false);
    });

    test('round-trip: parse new format → serialize → parse', () {
      const String original = 'Text<kekaudio path="/audio/path.m4a" duration="60.5"/>more';

      final parsed1 = MindNoteContent.parse(original);
      final serialized = parsed1.toRawNoteString();
      final parsed2 = MindNoteContent.parse(serialized);

      expect(serialized, original);
      expect(parsed2.plainText, parsed1.plainText);
      expect(parsed2.audioPieces.length, 1);
      expect(parsed2.audioPieces.first.appRelativeAbsoulutePath, '/audio/path.m4a');
      expect(parsed2.audioPieces.first.hasDuration, true);
      expect(parsed2.audioPieces.first.durationSeconds, 60.5);
    });

    test('round-trip: parse mixed formats → serialize → parse', () {
      const String original =
          'A<kekaudio>/old.m4a</kekaudio>B'
          '<kekaudio path="/new.m4a" duration="15.0"/>C';

      final parsed1 = MindNoteContent.parse(original);
      final serialized = parsed1.toRawNoteString();
      final parsed2 = MindNoteContent.parse(serialized);

      expect(serialized, original);
      expect(parsed2.plainText, 'ABC');
      expect(parsed2.audioPieces.length, 2);
      expect(parsed2.audioPieces[0].hasDuration, false);
      expect(parsed2.audioPieces[1].hasDuration, true);
      expect(parsed2.audioPieces[1].durationSeconds, 15.0);
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

    test('appendAudioNote with duration produces new mind with new format audio tag', () {
      final Mind mind = buildMind('Initial');

      final Mind updated = mind.appendAudioNote('/files/audio_2.m4a', separator: '\n', durationSeconds: 42.3);

      expect(updated.note, 'Initial\n<kekaudio path="/files/audio_2.m4a" duration="42.3"/>');
      expect(updated.audioNotes.single.appRelativeAbsoulutePath, '/files/audio_2.m4a');
      expect(updated.audioNotes.single.durationSeconds, 42.3);
      expect(updated.audioNotes.single.hasDuration, true);
    });
  });
}
