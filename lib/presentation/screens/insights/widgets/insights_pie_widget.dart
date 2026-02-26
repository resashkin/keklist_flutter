import 'dart:collection';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:keklist/presentation/core/helpers/mind_utils.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/core/widgets/my_chip_widget.dart';
import 'package:keklist/presentation/core/widgets/rounded_container.dart';
import 'package:keklist/presentation/core/widgets/sensitive_widget.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/screens/mind_collection/local_widgets/mind_collection_empty_day_widget.dart';
import 'package:keklist/domain/period.dart';
import 'package:keklist/presentation/screens/digest/mind_universal_list_screen.dart';
import 'package:keklist/presentation/screens/mind_info/mind_info_screen.dart';

// Improvements:
// Переключатель по количеству символов
// По частоте использования
// Цвета - более приятно рандомизированные - попросить ChatGPT сгенерить для каждого эмодзика
// Показывать за конкретный день лучше, а то получается как то много, либо поменять с пая на что нибудь еще

// REMOVE enum InsightsPieWidgetChoice and use PeriodType global enum instead

final class InsightsPieWidget extends StatefulWidget {
  final List<Mind> allMinds;

  const InsightsPieWidget({super.key, required this.allMinds});

  @override
  State<InsightsPieWidget> createState() => _InsightsPieWidgetState();
}

final class _InsightsPieWidgetState extends State<InsightsPieWidget> {
  final List<PeriodType> _choices = PeriodType.values;
  int _selectedChoiceIndex = 0;
  String? _selectedEmoji;

  @override
  Widget build(BuildContext context) {
    final PeriodType selectedPeriod = _choices[_selectedChoiceIndex];
    final List<Mind> choiceMinds = selectedPeriod.filterMinds(widget.allMinds);
    final HashMap<String, int> intervalChoiceMap = HashMap<String, int>();

    for (final Mind mind in choiceMinds) {
      final int noteLength = mind.plainNote.length;
      if (intervalChoiceMap.containsKey(mind.emoji)) {
        intervalChoiceMap[mind.emoji] = intervalChoiceMap[mind.emoji]! + noteLength;
      } else {
        intervalChoiceMap[mind.emoji] = noteLength;
      }
    }

    final List<PieChartSectionData> pieSections = _getPieSections(choiceMap: intervalChoiceMap);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RoundedContainer(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(context.l10n.spectrum, style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500)),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_choices.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: MyChipWidget(
                      isSelected: _selectedChoiceIndex == index,
                      onSelect: (bool selected) {
                        setState(() {
                          _selectedChoiceIndex = index;
                        });
                      },
                      selectedColor: Theme.of(context).colorScheme.primary,
                      child: SensitiveWidget(
                        child: Text(
                          _choices[index].localizedTitle(context),
                          style: TextStyle(
                            fontSize: 14.0,
                            color: _selectedChoiceIndex == index
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(
              height: 350,
              child: BoolWidget(
                condition: pieSections.isNotEmpty,
                trueChild: SensitiveWidget(
                  child: PieChart(
                    PieChartData(
                      sections: pieSections,
                      centerSpaceRadius: 0,
                      sectionsSpace: 0,
                      startDegreeOffset: 0,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null ||
                              event is! FlTapUpEvent) {
                            return;
                          }
                          final int touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          final sortedEntries = intervalChoiceMap.entries
                              .sortedByProperty((e) => e.value, reversed: true)
                              .toList();
                          if (touchedIndex >= 0 && touchedIndex < sortedEntries.length) {
                            final tappedEmoji = sortedEntries[touchedIndex].key;
                            setState(() {
                              if (_selectedEmoji != tappedEmoji) {
                                _selectedEmoji = tappedEmoji;
                              } else {
                                _selectedEmoji = null;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    curve: Curves.bounceInOut,
                  ),
                ),
                falseChild: Center(
                  child: MindCollectionEmptyStateWidget.noMinds(context: context, text: context.l10n.noMindsForPeriod),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: intervalChoiceMap.entries.sortedByProperty((e) => e.value, reversed: true).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: MyChipWidget(
                      isSelected: _selectedEmoji == entry.key,
                      onSelect: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedEmoji = entry.key;
                          } else {
                            _selectedEmoji = null;
                          }
                        });
                      },
                      selectedColor: _colorFromEmoji(entry.key),
                      child: SensitiveWidget(child: Text(entry.key, style: const TextStyle(fontSize: 24.0))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8.0),
            Center(
              child: TextButton(
                onPressed: () {
                  final PeriodType selectedPeriod = _choices[_selectedChoiceIndex];
                  final String? selectedEmoji = _selectedEmoji;
                  Navigator.of(context).push(
                    SwipeablePageRoute(
                      builder: (context) => MindUniversalListScreen(
                        allMinds: widget.allMinds,
                        filterFunction: (mind) {
                          final bool periodMatch = selectedPeriod.filterMinds([mind]).isNotEmpty;
                          final bool emojiMatch = selectedEmoji == null || mind.emoji == selectedEmoji;
                          return periodMatch && emojiMatch;
                        },
                        title: context.l10n.minds,
                        emptyStateMessage: context.l10n.noMindsForPeriod,
                        onSelectMind: (mind) {
                          Navigator.of(context).push(
                            SwipeablePageRoute(
                              builder: (context) => MindInfoScreen(rootMind: mind, allMinds: widget.allMinds),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                child: Text(
                  '${context.l10n.showMindsForPeriod(_choices[_selectedChoiceIndex].localizedTitle(context).toLowerCase())} (${_getFilteredMindsCount()})',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16.0, color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieSections({required HashMap<String, int> choiceMap}) {
    final int allValues = choiceMap.values.map((e) => e).fold<int>(0, (a, b) => a + b);
    // Sort descending by value for both pie and chips
    final sortedEntries = choiceMap.entries.sortedByProperty((e) => e.value, reversed: true).toList();
    return sortedEntries.map((entry) {
      final currentValue = choiceMap.entries
          .where((element) => element.key == entry.key)
          .map((e) => e.value)
          .fold<int>(0, (a, b) => a + b);
      final double percentValue = 100 * currentValue / allValues;
      final bool shouldShowTitle = percentValue >= 6;

      final bool isSelected = entry.key == _selectedEmoji;
      return PieChartSectionData(
        color: _colorFromEmoji(entry.key),
        showTitle: shouldShowTitle,
        value: percentValue,
        title: percentValue.toStringAsFixed(1),
        radius: isSelected ? 170 : 150,
        titleStyle: TextStyle(fontSize: isSelected ? 17.0 : 15.0, fontWeight: FontWeight.bold, color: Colors.white),
        titlePositionPercentageOffset: 0.75,
        badgeWidget: BoolWidget(
          condition: shouldShowTitle,
          trueChild: Text(entry.key, style: const TextStyle(fontSize: 22.0)),
          falseChild: const SizedBox.shrink(),
        ),
        badgePositionPercentageOffset: 0.50,
      );
    }).toList();
  }

  Color _colorFromEmoji(String emoji) {
    final int codePoint = emoji.codeUnits.first + emoji.codeUnits.last;
    final Random random = Random(codePoint);
    return Color.fromARGB(255, random.nextInt(256), random.nextInt(256), random.nextInt(256));
  }

  int _getFilteredMindsCount() {
    final PeriodType selectedPeriod = _choices[_selectedChoiceIndex];
    final String? selectedEmoji = _selectedEmoji;
    return selectedPeriod.filterMinds(widget.allMinds).where((mind) {
      final bool periodMatch = selectedPeriod.filterMinds([mind]).isNotEmpty;
      final bool emojiMatch = selectedEmoji == null || mind.emoji == selectedEmoji;
      return periodMatch && emojiMatch;
    }).length;
  }
}
