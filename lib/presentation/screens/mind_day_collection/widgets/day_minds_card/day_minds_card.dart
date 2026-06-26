import 'package:flutter/material.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/widgets/rounded_container.dart';
import 'package:keklist/presentation/screens/mind_collection/local_widgets/mind_collection_empty_day_widget.dart';
import 'package:keklist/presentation/screens/mind_collection/local_widgets/mind_row_widget.dart';

final class DayMindsCard extends StatelessWidget {
  final List<Mind> minds;
  final VoidCallback onTap;
  final VoidCallback onTapEmpty;

  const DayMindsCard({
    super.key,
    required this.minds,
    required this.onTap,
    required this.onTapEmpty,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = minds.isEmpty;
    final ThemeData theme = Theme.of(context);

    return GestureDetector(
      onTap: isEmpty ? onTapEmpty : onTap,
      child: RoundedContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(context.l10n.minds, style: theme.textTheme.titleMedium),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16.0),
                ],
              ),
              if (isEmpty)
                MindCollectionEmptyStateWidget.noMindsForDay(context: context)
              else
                Align(
                  alignment: Alignment.center,
                  child: MindRowWidget(minds: minds),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
