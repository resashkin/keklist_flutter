import 'package:flutter/material.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:gap/gap.dart';
import 'package:keklist/presentation/screens/mind_day_collection/widgets/day_media_tile/day_media_preview_cubit.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

final class DayMediaTileWidget extends StatelessWidget {
  final DayMediaPreviewData data;
  final VoidCallback onTap;

  const DayMediaTileWidget({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.sourcesPhotoVideo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (data.total > 0) ...[
                        Text(
                          '${data.total}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                        const Gap(4.0),
                      ],
                      const Icon(Icons.arrow_forward_ios, size: 16.0),
                    ],
                  ),
                ],
              ),
              const Gap(8.0),
              if (data.assets.isEmpty)
                Center(
                  child: Text(
                    context.l10n.noPhotosForDay,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    const double gap = 4.0;
                    final double size =
                        (constraints.maxWidth - gap * (data.assets.length - 1)) / data.assets.length;
                    final int thumbSize = (size * MediaQuery.devicePixelRatioOf(context)).round();
                    return Row(
                      spacing: gap,
                      children: data.assets
                          .map(
                            (asset) => ClipRRect(
                              borderRadius: BorderRadius.circular(6.0),
                              child: AssetEntityImage(
                                asset,
                                isOriginal: false,
                                thumbnailSize: ThumbnailSize.square(thumbSize),
                                fit: BoxFit.cover,
                                width: size,
                                height: size,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
