import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';
import 'package:photo_manager/photo_manager.dart';

final class SourcesBottomSheet extends StatelessWidget {
  final bool isPhotoVideoEnabled;
  final ValueChanged<bool> onPhotoVideoToggled;
  final VoidCallback? onPhotoVideoSettings;
  final bool isWeatherEnabled;
  final ValueChanged<bool> onWeatherToggled;
  final VoidCallback? onWeatherSettings;
  final bool isMediaFolderEnabled;
  final ValueChanged<bool> onMediaFolderToggled;
  final VoidCallback? onMediaFolderSettings;

  const SourcesBottomSheet({
    super.key,
    required this.isPhotoVideoEnabled,
    required this.onPhotoVideoToggled,
    this.onPhotoVideoSettings,
    required this.isWeatherEnabled,
    required this.onWeatherToggled,
    this.onWeatherSettings,
    required this.isMediaFolderEnabled,
    required this.onMediaFolderToggled,
    this.onMediaFolderSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text(
              context.l10n.sources,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          _SourceItem(
            icon: Icons.emoji_emotions,
            title: context.l10n.sourcesMinds,
            subtitle: context.l10n.sourcesMindsSubtitle,
            checked: true,
            enabled: false,
          ),
          if (!Platform.isAndroid)
            _SourceItem(
              icon: Icons.photo_library,
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
              onSettings: onPhotoVideoSettings,
            ),
          if (Platform.isAndroid)
            _SourceItem(
              icon: Icons.folder_open,
              title: context.l10n.sourcesMediaFolder,
              subtitle: context.l10n.sourcesMediaFolderSubtitle,
              checked: isMediaFolderEnabled,
              enabled: true,
              onTap: () => onMediaFolderToggled(!isMediaFolderEnabled),
              onSettings: onMediaFolderSettings,
            ),
          _SourceItem(
            icon: Icons.cloud,
            title: context.l10n.sourcesWeather,
            subtitle: context.l10n.sourcesWeatherSubtitle,
            checked: isWeatherEnabled,
            enabled: true,
            showProBadge: true,
            onTap: () => onWeatherToggled(!isWeatherEnabled),
            onSettings: isWeatherEnabled ? onWeatherSettings : null,
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
  final bool showProBadge;
  final VoidCallback? onTap;
  final VoidCallback? onSettings;

  const _SourceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.enabled,
    this.showProBadge = false,
    this.onTap,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final Color mutedColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
    final Color subtitleColor = enabled
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : mutedColor;
    return ListTile(
      dense: true,
      horizontalTitleGap: 16.0,
      leading: Icon(icon, color: enabled ? null : mutedColor),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: enabled ? null : TextStyle(color: mutedColor)),
          if (showProBadge) ...[
            const Gap(6.0),
            _ProBadge(),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtitleColor),
      ),
      trailing: onSettings != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.settings, size: 20),
                  onPressed: onSettings,
                ),
                Switch.adaptive(
                  value: checked,
                  onChanged: enabled ? (_) => onTap?.call() : null,
                ),
              ],
            )
          : Switch.adaptive(
              value: checked,
              onChanged: enabled ? (_) => onTap?.call() : null,
            ),
      onTap: enabled ? onTap : null,
    );
  }
}

final class _ProBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFFB800), width: 1.2),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          fontSize: 9.0,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFFB800),
          height: 1.2,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
