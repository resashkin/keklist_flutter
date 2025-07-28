import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/core/helpers/mind_utils.dart';

enum PeriodType {
  today,
  yesterday,
  thisWeek,
  lastTwoWeeks,
  thisMonth,
  thisYear,
}

extension PeriodTypeExtension on PeriodType {
  String get localizedTitle {
    switch (this) {
      case PeriodType.today:
        return 'Today';
      case PeriodType.yesterday:
        return 'Yesterday';
      case PeriodType.thisWeek:
        return 'This week';
      case PeriodType.lastTwoWeeks:
        return 'Last 2 weeks';
      case PeriodType.thisMonth:
        return 'This month';
      case PeriodType.thisYear:
        return 'This year';
    }
  }

  List<Mind> filterMinds(List<Mind> allMinds) {
    switch (this) {
      case PeriodType.today:
        return MindUtils.findTodayMinds(allMinds: allMinds);
      case PeriodType.yesterday:
        return MindUtils.findYesterdayMinds(allMinds: allMinds);
      case PeriodType.thisWeek:
        return MindUtils.findThisWeekMinds(allMinds: allMinds);
      case PeriodType.lastTwoWeeks:
        return MindUtils.findLastTwoWeeksMinds(allMinds: allMinds);
      case PeriodType.thisMonth:
        return MindUtils.findThisMonthMinds(allMinds: allMinds);
      case PeriodType.thisYear:
        return MindUtils.findThisYearMinds(allMinds: allMinds);
    }
  }
}
