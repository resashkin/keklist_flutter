part of '../../mind_collection_screen.dart';

final class _MindCollectionBody extends StatelessWidget {
  final bool isSearching;
  final List<Mind> searchResults;
  final VoidCallback hideKeyboard;
  final Function(int) onTapToDay;
  final Map<int, Iterable<Mind>> mindsByDayIndex;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final Function getNowDayIndex;
  final bool shouldShowTitles;
  final bool isMonthView;

  // Grid properties.
  final ScrollController monthGridScrollController;
  final GridObserverController monthGridObserverController;

  const _MindCollectionBody({
    required this.isSearching,
    required this.searchResults,
    required this.hideKeyboard,
    required this.onTapToDay,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.getNowDayIndex,
    required this.mindsByDayIndex,
    required this.shouldShowTitles,
    required this.isMonthView,
    required this.monthGridScrollController,
    required this.monthGridObserverController,
  });

  // static DateFormat _yearTitleFormatter(BuildContext context) =>
  //     DateFormat.y(Localizations.localeOf(context).languageCode);
  // static DateFormat _monthTitleFormatter(BuildContext context) =>
  //     DateFormat.MMMM(Localizations.localeOf(context).languageCode).addPattern('').addPattern('yyyy', '');

  @override
  Widget build(BuildContext context) {
    return BoolWidget(
      condition: isMonthView,
      trueChild: MindMonthCollectionWidget(
        onTap: onTapToDay,
        mindsByDayIndex: mindsByDayIndex,
        scrollController: monthGridScrollController,
        gridObserverController: monthGridObserverController,
      ),
      falseChild: BoolWidget(
        condition: !isSearching,
        trueChild: GestureDetector(
          onPanDown: (_) => hideKeyboard(),
          child: ScrollablePositionedList.builder(
            padding: const EdgeInsets.only(top: 16.0),
            itemCount: 99999999999,
            itemScrollController: itemScrollController,
            itemPositionsListener: itemPositionsListener,
            itemBuilder: (_, int dayIndex) {
              final Iterable<Mind> dayMinds = mindsByDayIndex[dayIndex]?.sortedBySortIndex() ?? [];
              final bool isToday = dayIndex == getNowDayIndex();
              final DateTime currentDayDateIndex = DateUtils.getDateFromDayIndex(dayIndex);
              final DateTime previousDayDateIndex = currentDayDateIndex.subtract(const Duration(days: 1));
              // final String currentDayYearTitle = _yearTitleFormatter(context).format(currentDayDateIndex);
              // final String previousDayYearTitle = _yearTitleFormatter(context).format(previousDayDateIndex);
              // final String currentDayMonthTitle = _monthTitleFormatter(context).format(currentDayDateIndex);
              // final String previousDayMonthTitle = _monthTitleFormatter(context).format(previousDayDateIndex);
              final int currentDayWeekNumber = _getWeekNumber(currentDayDateIndex);
              final int previousDayWeekNumber = _getWeekNumber(previousDayDateIndex);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: BoolWidget(
                      condition: shouldShowTitles,
                      trueChild: Column(
                        children: [
                          // BoolWidget(
                          //   condition: currentDayYearTitle != previousDayYearTitle,
                          //   trueChild: Text(
                          //     currentDayYearTitle,
                          //     style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                          //   ),
                          //   falseChild: const SizedBox.shrink(),
                          // ),
                          // BoolWidget(
                          //   condition: currentDayMonthTitle != previousDayMonthTitle,
                          //   trueChild: Text(
                          //     '${currentDayMonthTitle[0].toUpperCase()}${currentDayMonthTitle.substring(1)}',
                          //     style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                          //   ),
                          //   falseChild: const SizedBox.shrink(),
                          // ),
                          BoolWidget(
                            condition: currentDayWeekNumber != previousDayWeekNumber,
                            trueChild: Column(
                              children: [
                                const SizedBox(height: 12.0),
                                Text(
                                  '${context.l10n.week} #${_getWeekNumber(currentDayDateIndex)}',
                                  style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            falseChild: const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      falseChild: const SizedBox.shrink(),
                    ),
                  ),
                  Text(
                    DateFormatters.formatFullDate(currentDayDateIndex, Localizations.localeOf(context)),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
                  ),
                  const SizedBox(height: 4.0),
                  GestureDetector(
                    onTap: () => onTapToDay(dayIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: RoundedContainer(
                        border: isToday
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                                width: 2.0,
                              )
                            : null,
                        child: BoolWidget(
                          condition: dayMinds.isEmpty,
                          trueChild: MindCollectionEmptyStateWidget.noMinds(context: context),
                          falseChild: MindRowWidget(minds: dayMinds),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        falseChild: MindSearchResultListWidget(
          results: searchResults,
          onTapToMind: (mind) => () {
            hideKeyboard();
            onTapToDay(mind.dayIndex);
          },
        ),
      ),
    );
  }

  // FIXME: to not show week number in start of each year.

  int _getWeekNumber(DateTime date) {
    final DateTime firstDayOfYear = DateTime(date.year, 1, 1);
    final int dayOfYear = date.difference(firstDayOfYear).inDays;
    final int weekdayOfFirstDay = firstDayOfYear.weekday;
    final int weekNumber = ((dayOfYear + weekdayOfFirstDay) / 7).ceil();
    return weekNumber;
  }
}
