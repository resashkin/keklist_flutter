# Quick Start Guide

Get keklist running locally in 5 minutes!

## Prerequisites

- Flutter SDK 3.5.0+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Git

## Installation

```bash
# 1. Clone the repository
git clone https://github.com/resashkin/keklist_flutter.git
cd keklist_flutter

# 2. Install dependencies
flutter pub get

# 3. Create environment file
touch dotenv
echo "REVENUE_CAT_TEST_API_KEY=your_test_key" >> dotenv
echo "REVENUE_CAT_PROD_API_KEY=your_prod_key" >> dotenv

# 4. Generate code
dart run build_runner build --delete-conflicting-outputs

# 5. Generate localizations
flutter gen-l10n

# 6. Run the app
flutter run
```

## That's it! 🎉

The app should now be running on your device/emulator.

## Next Steps

- **Read the Architecture**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Development Guide**: [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)

## Common Issues

**"dart: command not found"**
```bash
flutter doctor  # Verify Flutter is installed and in PATH
```

**Build errors**
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

**Localization errors**
```bash
flutter gen-l10n
```

## Need Help?

- 📱 Telegram: [@resashkin](https://t.me/resashkin)
- 📧 Email: sashkn2@gmail.com
- 🐛 Issues: [GitHub Issues](https://github.com/resashkin/keklist_flutter/issues)

---

Happy coding! 💚
