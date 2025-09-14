import 'package:flutter/material.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';

enum PeriodType {
  today,
  yesterday,
  thisWeek,
  lastTwoWeeks,
  thisMonth,
  thisYear,
}

extension PeriodTypeExtension on PeriodType {
  String localizedTitle(BuildContext context) {
    switch (this) {
      case PeriodType.today:
        return context.l10n.today;
      case PeriodType.yesterday:
        return context.l10n.yesterday;
      case PeriodType.thisWeek:
        return context.l10n.thisWeek;
      case PeriodType.lastTwoWeeks:
        return context.l10n.lastTwoWeeks;
      case PeriodType.thisMonth:
        return context.l10n.thisMonth;
      case PeriodType.thisYear:
        return context.l10n.thisYear;
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
