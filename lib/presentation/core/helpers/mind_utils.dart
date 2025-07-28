import 'package:keklist/domain/services/entities/mind.dart';

final class MindUtils {
  static const int millisecondsInDay = 1000 * 60 * 60 * 24;

  static int getDayIndex({required DateTime from}) =>
      (from.millisecondsSinceEpoch + from.timeZoneOffset.inMilliseconds) ~/ millisecondsInDay;

  static int getTodayIndex() => MindUtils.getDayIndex(from: DateTime.now());

  static DateTime getDateFromDayIndex(int dayIndex) =>
      DateTime.fromMillisecondsSinceEpoch(millisecondsInDay * dayIndex);

  static List<Mind> findMindsByDayIndex({
    required int dayIndex,
    required Iterable<Mind> allMinds,
  }) =>
      allMinds
          .where((item) => dayIndex == item.dayIndex)
          .where((item) => item.rootId == null)
          .sortedByProperty((it) => it.sortIndex)
          .toList();

  static List<Mind> findTodayMinds({required List<Mind> allMinds}) {
    return findMindsByDayIndex(
      dayIndex: getTodayIndex(),
      allMinds: allMinds,
    );
  }

  static List<Mind> getSortedMindsBySortIndex({required List<Mind> allMinds}) =>
      allMinds.sortedByProperty((it) => it.sortIndex);

  static List<Mind> findMindsByRootId({
    required String rootId,
    required Iterable<Mind> allMinds,
  }) =>
      allMinds.where((item) => rootId == item.rootId).sortedByProperty((it) => it.sortIndex);

  static List<Mind> findYesterdayMinds({required List<Mind> allMinds}) {
    final int yesterdayIndex = MindUtils.getDayIndex(from: DateTime.now()) - 1;
    return findMindsByDayIndex(
      dayIndex: yesterdayIndex,
      allMinds: allMinds,
    );
  }

  static List<Mind> findThisWeekMinds({required List<Mind> allMinds}) {
    final DateTime now = DateTime.now();
    final int todayIndex = getDayIndex(from: now);
    final DateTime weekStart = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final int weekStartIndex = getDayIndex(from: weekStart);
    return allMinds.where((item) => item.dayIndex >= weekStartIndex && item.dayIndex <= todayIndex).toList();
  }

  static List<Mind> findThisMonthMinds({required List<Mind> allMinds}) {
    final DateTime now = DateTime.now();
    final int todayIndex = getDayIndex(from: now);
    final DateTime monthStart = DateTime(now.year, now.month, 1);
    final int monthStartIndex = getDayIndex(from: monthStart);
    return allMinds.where((item) => item.dayIndex >= monthStartIndex && item.dayIndex <= todayIndex).toList();
  }

  static List<Mind> findThisYearMinds({required List<Mind> allMinds}) {
    final DateTime now = DateTime.now();
    final int todayIndex = getDayIndex(from: now);
    final DateTime yearStart = DateTime(now.year, 1, 1);
    final int yearStartIndex = getDayIndex(from: yearStart);
    return allMinds.where((item) => item.dayIndex >= yearStartIndex && item.dayIndex <= todayIndex).toList();
  }

  static List<Mind> findMindsByEmoji({
    required String emoji,
    required Iterable<Mind> allMinds,
  }) =>
      allMinds.where((item) => emoji == item.emoji).sortedByProperty((it) => it.sortIndex).toList();

  static Map<String, int> convertToMindCountMap({required List<Mind> minds}) {
    Map<String, int> mindCountMap = {};
    Map<String, int> childCountMap = {};

    for (Mind mind in minds.where(
      (element) => element.rootId != null,
    )) {
      final String parentId = mind.rootId!;

      if (childCountMap.containsKey(parentId)) {
        childCountMap[parentId] = childCountMap[parentId]! + 1;
      } else {
        childCountMap[parentId] = 1;
      }
    }

    for (Mind mind in minds) {
      final mindId = mind.id;
      final count = childCountMap[mindId] ?? 0;
      mindCountMap[mindId] = count;
    }

    return mindCountMap;
  }

  static Map<String, List<Mind>> convertToMindChildren({required List<Mind> minds}) {
    Map<String, List<Mind>> mindChildrenMap = {};

    for (Mind mind in minds.where(
      (element) => element.rootId != null,
    )) {
      final String parentId = mind.rootId!;

      if (mindChildrenMap.containsKey(parentId)) {
        mindChildrenMap[parentId]!.add(mind);
      } else {
        mindChildrenMap[parentId] = [mind];
      }
    }

    return mindChildrenMap;
  }

  static List<Mind> findLastTwoWeeksMinds({required List<Mind> allMinds}) {
    final DateTime now = DateTime.now();
    final int todayIndex = getDayIndex(from: now);
    // Start from Monday two weeks ago
    final DateTime thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final DateTime twoWeeksAgoMonday = thisWeekStart.subtract(const Duration(days: 7));
    final int twoWeeksAgoMondayIndex = getDayIndex(from: twoWeeksAgoMonday);
    return allMinds.where((item) => item.dayIndex >= twoWeeksAgoMondayIndex && item.dayIndex <= todayIndex).toList();
  }
}

// NOTE: Sorted by.

extension ListIterable<E> on Iterable<E> {
  List<E> sortedByProperty(Comparable Function(E e) key, {bool reversed = false}) => toList()
    ..sort(
      (a, b) {
        if (reversed) {
          return key(b).compareTo(key(a));
        } else {
          return key(a).compareTo(key(b));
        }
      },
    );
}

extension MindListIndexSortExtension on Iterable<Mind> {
  List<Mind> sortedBySortIndex() => sortedByProperty((it) => it.sortIndex);
}

extension MindListCreationDateSortExtension on Iterable<Mind> {
  List<Mind> sortedByCreationDate() => sortedByProperty((it) => it.creationDate);
}
