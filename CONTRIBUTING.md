# Contributing to keklist

First off, thank you for considering contributing to keklist! It's people like you that make keklist such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by mutual respect and professionalism. Be kind and constructive in your interactions.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** to demonstrate the steps
- **Describe the behavior you observed** and what you expected
- **Include screenshots** if relevant
- **Include your environment details**: OS, Flutter version, device

**Bug Report Template:**

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
- Device: [e.g. iPhone 12, Pixel 5]
- OS: [e.g. iOS 15.0, Android 12]
- App Version: [e.g. 4.1.1]
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a step-by-step description** of the suggested enhancement
- **Explain why this enhancement would be useful**
- **Include mockups or examples** if applicable

### Pull Requests

1. **Fork the repository** and create your branch from `master`
2. **Follow the coding style** used throughout the project
3. **Write meaningful commit messages**
4. **Add tests** if you're adding new functionality
5. **Update documentation** as needed
6. **Ensure the test suite passes**
7. **Make sure your code lints** (`dart format lib/`)

**PR Checklist:**

- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code where necessary
- [ ] I have updated the documentation accordingly
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works
- [ ] New and existing tests pass locally

## Development Setup

See the [README.md](README.md#how-to-build) for detailed setup instructions.

Quick start:

```bash
git clone https://github.com/resashkin/keklist_flutter.git
cd keklist_flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Coding Guidelines

### Dart Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `dart format lib/` before committing
- Run `flutter analyze` to check for issues

### Architecture

- **BLoC Pattern**: Use BLoC/Cubit for state management
- **Repository Pattern**: Data access through repositories
- **Dependency Injection**: Use the DI container in `lib/di/`

### File Organization

```
lib/
├── domain/           # Business logic, entities, repositories
├── presentation/     # UI layer (screens, widgets, blocs)
├── di/              # Dependency injection
└── native/          # Platform-specific code
```

### Naming Conventions

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `camelCase` or `SCREAMING_SNAKE_CASE` for compile-time constants
- **Private members**: prefix with `_`

### Localization

When adding new strings:

1. Add to `lib/l10n/app_en.arb` (English is the source)
2. Add translations to other `.arb` files
3. Run `flutter gen-l10n`
4. Use via `AppLocalizations.of(context)!.yourKey`

**Example:**

```json
{
  "yourKey": "Your text here",
  "@yourKey": {
    "description": "Description of what this string is for"
  }
}
```

### State Management

- Use **BLoC** for complex state management
- Use **Cubit** for simpler state management
- Keep business logic in BLoCs/Cubits, not in widgets

### Testing

- Write unit tests for business logic
- Write widget tests for UI components
- Place tests in `test/` directory mirroring `lib/` structure

## Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests after the first line

**Good commit messages:**

```
Add onboarding flow for new users

- Create interactive 4-page onboarding screen
- Add localized content for English and Russian
- Create custom SVG illustrations
- Implement sample minds creation

Closes #123
```

## Branch Naming

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `refactor/description` - Code refactoring

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

## Questions?

Feel free to reach out:
- Telegram: [@resashkin](https://t.me/resashkin)
- Email: sashkn2@gmail.com

Thank you for contributing! 🚀
