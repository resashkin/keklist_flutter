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

  const PasswordInputBottomSheet({
    super.key,
    required this.title,
    this.isOptional = false,
  });

  /// Show the bottom sheet and return the password, or null if cancelled
  static Future<String?> show({
    required BuildContext context,
    required String title,
    bool isOptional = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PasswordInputBottomSheet(
          title: title,
          isOptional: isOptional,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            widget.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Password field
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.l10n.password,
              hintText: context.l10n.enterPassword,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
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
          FilledButton(
            onPressed: _onContinue,
            child: Text(context.l10n.continue_),
          ),

          // Skip button (if optional)
          if (widget.isOptional) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _onSkip,
              child: Text(context.l10n.skipPassword),
            ),
          ],
        ],
      ),
    );
  }
}
