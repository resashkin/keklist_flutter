import 'package:flutter/material.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:photo_manager/photo_manager.dart';

final class SourcesBottomSheet extends StatelessWidget {
  final bool isPhotoVideoEnabled;
  final ValueChanged<bool> onPhotoVideoToggled;

  const SourcesBottomSheet({
    super.key,
    required this.isPhotoVideoEnabled,
    required this.onPhotoVideoToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            context.l10n.sources,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        _SourceItem(
          icon: Icons.emoji_emotions_outlined,
          title: context.l10n.sourcesMinds,
          subtitle: context.l10n.sourcesMindsSubtitle,
          checked: true,
          enabled: false,
        ),
        _SourceItem(
          icon: Icons.photo_library_outlined,
          title: context.l10n.sourcesPhotoVideo,
          subtitle: context.l10n.sourcesPhotoVideoSubtitle,
          checked: isPhotoVideoEnabled,
          enabled: true,
          onTap: () {
            final bool newValue = !isPhotoVideoEnabled;
            if (!newValue) {
              onPhotoVideoToggled(false);
              return;
            }
            PhotoManager.requestPermissionExtend().then((permission) {
              if (permission.isAuth) {
                onPhotoVideoToggled(true);
              } else {
                PhotoManager.openSetting();
              }
            });
          },
        ),
        SafeArea(child: const SizedBox(height: 8.0)),
      ],
    ),
    );
  }
}

final class _SourceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool checked;
  final bool enabled;
  final VoidCallback? onTap;

  const _SourceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color mutedColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
    final Color subtitleColor = enabled
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : mutedColor;
    return ListTile(
      titleAlignment: ListTileTitleAlignment.top,
      horizontalTitleGap: 8.0,
      leading: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Icon(icon, color: enabled ? null : mutedColor),
      ),
      title: Text(title, style: enabled ? null : TextStyle(color: mutedColor)),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtitleColor),
      ),
      trailing: Switch.adaptive(
        value: checked,
        onChanged: enabled ? (_) => onTap?.call() : null,
      ),
      onTap: enabled ? onTap : null,
    );
  }
}
