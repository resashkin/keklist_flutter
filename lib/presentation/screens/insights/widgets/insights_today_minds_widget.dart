import 'package:flutter/material.dart';
import 'package:keklist/presentation/screens/mind_collection/local_widgets/mind_row_widget.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/core/widgets/rounded_container.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';

// TODO: добавить дату
// TODO: возможность перехода на источник

class InsightsTodayMindsWidget extends StatefulWidget {
  final List<Mind> todayMinds;

  const InsightsTodayMindsWidget({
    super.key,
    required this.todayMinds,
  });

  @override
  State<InsightsTodayMindsWidget> createState() => _InsightsTodayMindsWidgetState();
}

class _InsightsTodayMindsWidgetState extends State<InsightsTodayMindsWidget> {
  @override
  Widget build(BuildContext context) {
    int listLenght = widget.todayMinds.length;
    if (listLenght == 0) {
      return Container();
    }

    return BoolWidget(
      condition: widget.todayMinds.isNotEmpty,
      falseChild: Container(),
      trueChild: Padding(
        padding: const EdgeInsets.all(8.0),
        child: RoundedContainer(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  context.l10n.todayMinds,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              MindRowWidget(minds: widget.todayMinds),
            ],
          ),
        ),
      ),
    );
  }
}
