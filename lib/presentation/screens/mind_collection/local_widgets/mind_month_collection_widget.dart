import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:intl/intl.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/core/helpers/date_utils.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

// TODO: max font size for single emoji should be bigger
// FIXME: scroll positon when rotate screen
// FIXME: long scrolling

final class MindMonthCollectionWidget extends StatelessWidget {
  final Map<int, Iterable<Mind>> mindsByDayIndex;
  final ScrollController scrollController;
  final GridObserverController gridObserverController;
  final Function(int) onTap;

  const MindMonthCollectionWidget({
    super.key,
    required this.mindsByDayIndex,
    required this.scrollController,
    required this.gridObserverController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridViewObserver(
      controller: gridObserverController,
      child: GridView.builder(
        controller: scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
        itemCount: 99999999999,
        itemBuilder: (BuildContext context, int dayIndex) {
          final Iterable<Mind> dayMinds = mindsByDayIndex[dayIndex] ?? [];
          return GestureDetector(
            onTap: () => onTap(dayIndex),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(width: 0.05)),
              child: BoolWidget(
                condition: dayMinds.isEmpty,
                trueChild: _DayOfMonthWidget(dayIndex: dayIndex),
                falseChild: MindMonthDayWidget(dayMinds: dayMinds),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DayOfMonthWidget extends StatelessWidget {
  final int dayIndex;
  static final DateFormat _dayFormatter = DateFormat('d');

  const _DayOfMonthWidget({required this.dayIndex});

  @override
  Widget build(BuildContext context) {
    final date = DateUtils.getDateFromDayIndex(dayIndex);
    final dateText = _dayFormatter.format(date);
    return AutoSizeText(
      dateText,
      minFontSize: 1,
      maxFontSize: 64.0,
    );
  }
}

final class MindMonthDayWidget extends StatelessWidget {
  final Iterable<Mind> dayMinds;

  const MindMonthDayWidget({
    super.key,
    required this.dayMinds,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: AutoSizeText(
        dayMinds.map((mind) => mind.emoji).join(' '),
        style: TextStyle(fontSize: 64.0),
        textAlign: TextAlign.center,
        minFontSize: 8.0,
      ),
    );
  }
}
