import 'package:flutter/material.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';

/// Result from password input bottom sheet
class PasswordInputResult {
  final String password;

  const PasswordInputResult(this.password);
}

/// Bottom sheet for password input during export/import
class PasswordInputBottomSheet extends StatefulWidget {
  /// Title displayed at the top
  final String title;

  /// Whether the password is optional (can be skipped)
  final bool isOptional;

  /// Optional metadata to display (for export)
  final int? mindsCount;
  final int? audioFilesCount;

  const PasswordInputBottomSheet({
    super.key,
    required this.title,
    this.isOptional = false,
    this.mindsCount,
    this.audioFilesCount,
  });

  /// Show the bottom sheet and return the password, or null if cancelled
  static Future<String?> show({
    required BuildContext context,
    required String title,
    bool isOptional = false,
    int? mindsCount,
    int? audioFilesCount,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: PasswordInputBottomSheet(
          title: title,
          isOptional: isOptional,
          mindsCount: mindsCount,
          audioFilesCount: audioFilesCount,
        ),
      ),
    );
  }

  @override
  State<PasswordInputBottomSheet> createState() => _PasswordInputBottomSheetState();
}

class _PasswordInputBottomSheetState extends State<PasswordInputBottomSheet> {
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final password = _passwordController.text;
    // Return the password (can be empty if optional)
    Navigator.of(context).pop(password);
  }

  void _onSkip() {
    // Return empty string to indicate "no password"
    Navigator.of(context).pop('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 24.0, left: 24.0, right: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Metadata info (if provided)
                if (widget.mindsCount != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${context.l10n.mindsToExport} - ${widget.mindsCount}', style: theme.textTheme.bodyMedium),
                        if (widget.audioFilesCount != null && widget.audioFilesCount! > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${context.l10n.audioFilesToExport} - ${widget.audioFilesCount}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: widget.mindsCount != null ? context.l10n.archivePassword : context.l10n.password,
                    hintText: context.l10n.enterPassword,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  onSubmitted: (_) => _onContinue(),
                ),

                const SizedBox(height: 24),

                // Continue button
                FilledButton(onPressed: _onContinue, child: Text(context.l10n.continue_)),

                // Skip button (if optional)
                if (widget.isOptional) ...[
                  const SizedBox(height: 8),
                  TextButton(onPressed: _onSkip, child: Text(context.l10n.skipPassword)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
