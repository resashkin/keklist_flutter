import 'package:flutter/material.dart';

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
            'Sources',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        _SourceItem(
          icon: Icons.emoji_emotions_outlined,
          title: 'Minds',
          subtitle: 'Your thoughts and moments',
          checked: true,
          enabled: false,
        ),
        _SourceItem(
          icon: Icons.photo_library_outlined,
          title: 'Photo & video',
          subtitle: 'Device photos and videos for this day',
          checked: isPhotoVideoEnabled,
          enabled: true,
          onTap: () => onPhotoVideoToggled(!isPhotoVideoEnabled),
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
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        checked ? Icons.check_circle : Icons.circle_outlined,
        color: checked
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: enabled ? onTap : null,
    );
  }
}
