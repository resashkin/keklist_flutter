import 'dart:math';

import 'package:flutter/material.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/core/widgets/rounded_container.dart';
import 'package:keklist/presentation/core/widgets/sensitive_widget.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';

// TODO: добавить дату
// TODO: возможность перехода на источник

final class InsightsRandomMindWidget extends StatefulWidget {
  final List<Mind> allMinds;
  final Function(Mind) onTapToMind;

  const InsightsRandomMindWidget({
    super.key,
    required this.allMinds,
    required this.onTapToMind,
  });

  @override
  State<InsightsRandomMindWidget> createState() => _InsightsRandomMindWidgetState();
}

final class _InsightsRandomMindWidgetState extends State<InsightsRandomMindWidget> {
  final Random _random = Random();
  late int nextInt = _random.nextInt(widget.allMinds.length);
  // String? translatedText;

  @override
  Widget build(BuildContext context) {
    int listLenght = widget.allMinds.length;
    if (listLenght == 0) {
      return Container();
    }

    final Mind randomMind = widget.allMinds[nextInt];

    return GestureDetector(
      onTap: () => widget.onTapToMind(randomMind),
      onDoubleTap: () {
        setState(() {
          nextInt = _random.nextInt(listLenght);
        });
      },
      // onLongPress: () => {
      //   setState(() async {
      //     var translation = await randomMind.note.translate(to: 'en');
      //     final text = translation.text;
      //     translatedText = text;
      //   }),
      // },
      child: BoolWidget(
        condition: widget.allMinds.isNotEmpty,
        falseChild: Container(),
        trueChild: Padding(
          padding: const EdgeInsets.all(8.0),
          child: RoundedContainer(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    context.l10n.randomMind,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        randomMind.emoji,
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 8.0),
                      SensitiveWidget(
                        child: Text(
                          randomMind.note,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
