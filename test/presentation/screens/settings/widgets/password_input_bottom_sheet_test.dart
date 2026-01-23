import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:keklist/l10n/app_localizations.dart';
import 'package:keklist/presentation/screens/settings/widgets/password_input_bottom_sheet.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('PasswordInputBottomSheet', () {
    testWidgets('renders password field correctly', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          const PasswordInputBottomSheet(
            title: 'Test Title',
            isConfirmationRequired: false,
            isOptional: false,
          ),
        ),
      );

      // Assert
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('shows confirmation field when required', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          const PasswordInputBottomSheet(
            title: 'Test Title',
            isConfirmationRequired: true,
            isOptional: false,
          ),
        ),
      );

      // Assert
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('shows skip button when optional', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          const PasswordInputBottomSheet(
            title: 'Test Title',
            isConfirmationRequired: false,
            isOptional: true,
          ),
        ),
      );

      // Assert
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          const PasswordInputBottomSheet(
            title: 'Test Title',
            isConfirmationRequired: false,
            isOptional: false,
          ),
        ),
      );

      // Find the password field
      final passwordField = tester.widget<TextField>(find.byType(TextField).first);
      expect(passwordField.obscureText, true);

      // Act - Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Assert
      final passwordFieldAfter = tester.widget<TextField>(find.byType(TextField).first);
      expect(passwordFieldAfter.obscureText, false);
    });

    testWidgets('validates password confirmation', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          const PasswordInputBottomSheet(
            title: 'Test Title',
            isConfirmationRequired: true,
            isOptional: false,
          ),
        ),
      );

      // Act - Enter different passwords
      await tester.enterText(find.byType(TextField).first, 'password123');
      await tester.enterText(find.byType(TextField).last, 'different');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Assert - Error message should be shown
      expect(find.textContaining('do not match', findRichText: true), findsOneWidget);
    });

    testWidgets('returns password when continue is tapped with matching passwords', (tester) async {
      // Arrange
      String? returnedPassword;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
          ],
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    returnedPassword = await PasswordInputBottomSheet.show(
                      context: context,
                      title: 'Test',
                      isConfirmationRequired: true,
                      isOptional: false,
                    );
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Act - Enter matching passwords
      await tester.enterText(find.byType(TextField).first, 'password123');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Assert
      expect(returnedPassword, 'password123');
    });

    testWidgets('returns empty string when skip is tapped', (tester) async {
      // Arrange
      String? returnedPassword;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
          ],
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    returnedPassword = await PasswordInputBottomSheet.show(
                      context: context,
                      title: 'Test',
                      isConfirmationRequired: false,
                      isOptional: true,
                    );
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Act - Tap skip button
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      // Assert
      expect(returnedPassword, '');
    });

    testWidgets('returns null when cancelled', (tester) async {
      // Arrange
      String? returnedPassword = 'initial';
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
          ],
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    returnedPassword = await PasswordInputBottomSheet.show(
                      context: context,
                      title: 'Test',
                      isConfirmationRequired: false,
                      isOptional: false,
                    );
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Act - Dismiss by tapping outside (simulate back button)
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Assert
      expect(returnedPassword, isNull);
    });

    testWidgets('clears error message when user types', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          const PasswordInputBottomSheet(
            title: 'Test Title',
            isConfirmationRequired: true,
            isOptional: false,
          ),
        ),
      );

      // Act - Enter different passwords to trigger error
      await tester.enterText(find.byType(TextField).first, 'password123');
      await tester.enterText(find.byType(TextField).last, 'different');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify error is shown
      expect(find.textContaining('do not match', findRichText: true), findsOneWidget);

      // Act - Type in confirm field
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.pumpAndSettle();

      // Assert - Error should be cleared
      expect(find.textContaining('do not match', findRichText: true), findsNothing);
    });

    testWidgets('accepts empty password when optional', (tester) async {
      // Arrange
      String? returnedPassword;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
          ],
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    returnedPassword = await PasswordInputBottomSheet.show(
                      context: context,
                      title: 'Test',
                      isConfirmationRequired: false,
                      isOptional: true,
                    );
                  },
                  child: const Text('Show'),
                ),
              );
            },
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Act - Don't enter any password, just tap continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Assert - Should return empty string
      expect(returnedPassword, '');
    });

    testWidgets('shows appropriate description for export', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          const PasswordInputBottomSheet(
            title: 'Test Title',
            isConfirmationRequired: true,
            isOptional: true,
          ),
        ),
      );

      // Assert - Should show export description
      expect(find.textContaining('encrypt', findRichText: true), findsOneWidget);
    });

    testWidgets('shows appropriate description for import', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        createTestWidget(
          const PasswordInputBottomSheet(
            title: 'Test Title',
            isConfirmationRequired: false,
            isOptional: false,
          ),
        ),
      );

      // Assert - Should show import description
      expect(find.textContaining('password-protected', findRichText: true), findsOneWidget);
    });
  });
}
