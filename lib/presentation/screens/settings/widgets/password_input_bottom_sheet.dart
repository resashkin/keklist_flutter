import 'package:flutter/material.dart';
import 'package:keklist/presentation/core/extensions/localization_extensions.dart';

/// Result from password input bottom sheet
class PasswordInputResult {
  final String password;

  const PasswordInputResult(this.password);
}

/// Bottom sheet for password input during export/import
/// Shows password field with optional confirmation for export
class PasswordInputBottomSheet extends StatefulWidget {
  /// Title displayed at the top
  final String title;

  /// Whether to show confirmation field (for export)
  final bool isConfirmationRequired;

  /// Whether the password is optional (can be skipped)
  final bool isOptional;

  const PasswordInputBottomSheet({
    super.key,
    required this.title,
    this.isConfirmationRequired = false,
    this.isOptional = false,
  });

  /// Show the bottom sheet and return the password, or null if cancelled
  static Future<String?> show({
    required BuildContext context,
    required String title,
    bool isConfirmationRequired = false,
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
          isConfirmationRequired: isConfirmationRequired,
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
  final _confirmController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    // Validate if confirmation is required
    if (widget.isConfirmationRequired && password != confirm) {
      setState(() {
        _errorMessage = context.l10n.passwordsDoNotMatch;
      });
      return;
    }

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

          const SizedBox(height: 8),

          // Description
          if (widget.isConfirmationRequired)
            Text(
              context.l10n.exportPasswordDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            )
          else
            Text(
              context.l10n.importPasswordDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
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
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
            onSubmitted: widget.isConfirmationRequired ? null : (_) => _onContinue(),
          ),

          // Confirmation field (for export)
          if (widget.isConfirmationRequired) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: !_isConfirmVisible,
              decoration: InputDecoration(
                labelText: context.l10n.confirmPassword,
                hintText: context.l10n.reenterPassword,
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmVisible = !_isConfirmVisible;
                    });
                  },
                ),
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
              onSubmitted: (_) => _onContinue(),
            ),
          ],

          // Error message (if not in field)
          if (_errorMessage != null && !widget.isConfirmationRequired) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],

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
