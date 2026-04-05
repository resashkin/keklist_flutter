import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:keklist/native/android/media_folder_channel.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';

final class MediaFolderSettingsBottomSheet extends StatelessWidget {
  final String? initialFolderPath;
  final bool isRecursive;
  final void Function(String folderPath) onFolderPicked;
  final ValueChanged<bool> onRecursiveChanged;

  const MediaFolderSettingsBottomSheet({
    super.key,
    required this.initialFolderPath,
    required this.isRecursive,
    required this.onFolderPicked,
    required this.onRecursiveChanged,
  });

  String _displayPath(String? path) {
    if (path == null) return 'No folder selected';
    if (Platform.isAndroid) {
      // Decode SAF URI to a human-readable form
      final decoded = Uri.decodeFull(path);
      final match = RegExp(r'primary[:%]3A(.+)$').firstMatch(decoded);
      if (match != null) return '/${match.group(1)}';
      return decoded;
    }
    return path;
  }

  Future<void> _pickFolder(BuildContext context) async {
    final String? picked;
    if (Platform.isAndroid) {
      picked = await MediaFolderChannel.openDocumentTree();
    } else {
      picked = await getDirectoryPath();
    }
    if (picked != null) {
      onFolderPicked(picked);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.mediaFolderSettings, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16.0),
              Text(
                'Current folder:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4.0),
              Text(
                _displayPath(initialFolderPath),
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8.0),
              SwitchListTile.adaptive(
                title: const Text('Include subfolders'),
                value: isRecursive,
                onChanged: onRecursiveChanged,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8.0),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _pickFolder(context),
                  child: const Text('Pick Folder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
