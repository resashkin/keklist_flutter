import 'package:flutter/material.dart';
import 'package:keklist/domain/services/entities/mind.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:keklist/presentation/core/widgets/rounded_container.dart';

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

    return RoundedContainer(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEmpty ? onTapEmpty : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                const SizedBox(height: 8),
                if (isEmpty)
                  Row(
                    children: [
                      Icon(Icons.add_circle_outline, size: 22, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.l10n.noMindsTodayTapToAdd,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final mind in minds)
                        Text(
                          mind.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
