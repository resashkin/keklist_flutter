# Quick Start Guide

Get keklist running locally in 5 minutes!

## Prerequisites

- Dart SDK ([Install Dart](https://dart.dev/get-dart))
- FVM (Flutter Version Manager) ([Install FVM](https://fvm.app))
- Git

**Note:** This project uses FVM to manage Flutter versions (currently 3.35.2).

## Installation

```bash
# 1. Clone the repository
git clone https://github.com/resashkin/keklist_flutter.git
cd keklist_flutter

# 2. Install FVM (if not already installed)
dart pub global activate fvm

# 3. Install Flutter with FVM
fvm install
fvm use

# 4. Install dependencies
fvm flutter pub get

# 5. Create environment file
touch dotenv
echo "REVENUE_CAT_TEST_API_KEY=your_test_key" >> dotenv
echo "REVENUE_CAT_PROD_API_KEY=your_prod_key" >> dotenv

# 6. Generate code
fvm dart run build_runner build --delete-conflicting-outputs

# 7. Generate localizations
fvm flutter gen-l10n

# 8. Run the app
fvm flutter run
```

## That's it! 🎉

The app should now be running on your device/emulator.

## Next Steps

- **Read the Architecture**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Development Guide**: [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)

## Common Issues

**"fvm: command not found"**
```bash
dart pub global activate fvm
# Add ~/.pub-cache/bin to your PATH
```

**"Flutter version mismatch"**
```bash
fvm install  # Install the correct Flutter version
fvm use      # Use it for the project
```

**Build errors**
```bash
fvm flutter clean
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
```

**Localization errors**
```bash
fvm flutter gen-l10n
```

## Need Help?

- 📱 Telegram: [@resashkin](https://t.me/resashkin)
- 📧 Email: sashkn2@gmail.com
- 🐛 Issues: [GitHub Issues](https://github.com/resashkin/keklist_flutter/issues)

---

Happy coding! 💚
