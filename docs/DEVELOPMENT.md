# Development Guide

This guide covers common development tasks and best practices for keklist.

## Table of Contents

- [Getting Started](#getting-started)
- [Common Tasks](#common-tasks)
- [Code Style](#code-style)
- [Testing](#testing)
- [Debugging](#debugging)
- [CI/CD](#cicd)

## Getting Started

### First Time Setup

1. **Install Flutter**:
   ```bash
   # Follow instructions at https://flutter.dev/docs/get-started/install
   flutter --version  # Should be 3.5.0+
   ```

2. **Clone and Setup**:
   ```bash
   git clone https://github.com/resashkin/keklist_flutter.git
   cd keklist_flutter
   flutter pub get
   ```

3. **Create Environment File**:
   ```bash
   touch dotenv
   # Add your API keys
   ```

4. **Generate Code**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   flutter gen-l10n
   ```

5. **Run**:
   ```bash
   flutter run
   ```

### IDE Setup

**VS Code:**

Install extensions:
- Flutter
- Dart
- Error Lens
- Better Comments

Recommended `settings.json`:
```json
{
  "dart.lineLength": 120,
  "editor.formatOnSave": true,
  "dart.previewFlutterUiGuides": true
}
```

**Android Studio:**

Install plugins:
- Flutter
- Dart

Enable auto-format on save:
Settings → Languages & Frameworks → Flutter → Format code on save

## Common Tasks

### Adding a New Screen

1. **Create screen file**:
   ```bash
   # lib/presentation/screens/my_feature/my_feature_screen.dart
   ```

2. **Create screen**:
   ```dart
   class MyFeatureScreen extends StatefulWidget {
     const MyFeatureScreen({super.key});

     @override
     State<MyFeatureScreen> createState() => _MyFeatureScreenState();
   }

   class _MyFeatureScreenState extends State<MyFeatureScreen> {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text('My Feature')),
         body: Center(child: Text('Content')),
       );
     }
   }
   ```

3. **Add navigation**:
   ```dart
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => MyFeatureScreen(),
     ),
   );
   ```

### Adding a New BLoC

1. **Create BLoC files**:
   ```bash
   lib/presentation/blocs/my_bloc/
   ├── my_bloc.dart
   ├── my_event.dart
   └── my_state.dart
   ```

2. **Define events** (`my_event.dart`):
   ```dart
   part of 'my_bloc.dart';

   sealed class MyEvent {
     const MyEvent();
   }

   final class MyLoadData extends MyEvent {}

   final class MyUpdateData extends MyEvent {
     final String data;
     const MyUpdateData({required this.data});
   }
   ```

3. **Define states** (`my_state.dart`):
   ```dart
   part of 'my_bloc.dart';

   sealed class MyState {
     const MyState();
   }

   final class MyInitial extends MyState {}

   final class MyLoading extends MyState {}

   final class MyLoaded extends MyState {
     final String data;
     const MyLoaded({required this.data});
   }

   final class MyError extends MyState {
     final String message;
     const MyError({required this.message});
   }
   ```

4. **Implement BLoC** (`my_bloc.dart`):
   ```dart
   import 'package:bloc/bloc.dart';

   part 'my_event.dart';
   part 'my_state.dart';

   class MyBloc extends Bloc<MyEvent, MyState> {
     MyBloc() : super(MyInitial()) {
       on<MyLoadData>(_onLoadData);
       on<MyUpdateData>(_onUpdateData);
     }

     Future<void> _onLoadData(MyLoadData event, Emitter<MyState> emit) async {
       emit(MyLoading());
       try {
         // Load data
         emit(MyLoaded(data: 'loaded'));
       } catch (e) {
         emit(MyError(message: e.toString()));
       }
     }

     Future<void> _onUpdateData(MyUpdateData event, Emitter<MyState> emit) async {
       // Update logic
     }
   }
   ```

5. **Provide BLoC**:
   ```dart
   BlocProvider(
     create: (context) => MyBloc()..add(MyLoadData()),
     child: MyScreen(),
   )
   ```

6. **Use in Widget**:
   ```dart
   BlocBuilder<MyBloc, MyState>(
     builder: (context, state) {
       if (state is MyLoading) {
         return CircularProgressIndicator();
       }
       if (state is MyLoaded) {
         return Text(state.data);
       }
       if (state is MyError) {
         return Text('Error: ${state.message}');
       }
       return SizedBox.shrink();
     },
   )
   ```

### Adding a New Repository

1. **Create repository interface**:
   ```dart
   // lib/domain/repositories/my_data/my_data_repository.dart
   abstract class MyDataRepository {
     Stream<List<MyData>> get stream;
     Future<MyData> create({required MyData data});
     Future<void> update({required MyData data});
     Future<void> delete({required String id});
   }
   ```

2. **Create Hive object**:
   ```dart
   // lib/domain/repositories/my_data/object/my_data_object.dart
   import 'package:hive/hive.dart';

   part 'my_data_object.g.dart';

   @HiveType(typeId: 10) // Use unique typeId
   class MyDataObject extends HiveObject {
     @HiveField(0)
     late String id;

     @HiveField(1)
     late String value;

     MyDataObject();
   }
   ```

3. **Implement repository**:
   ```dart
   // lib/domain/repositories/my_data/my_data_hive_repository.dart
   class MyDataHiveRepository implements MyDataRepository {
     final Box<MyDataObject> _box;

     MyDataHiveRepository({required Box<MyDataObject> box}) : _box = box;

     @override
     Stream<List<MyData>> get stream => _box.watch().map((_) => /* ... */);

     @override
     Future<MyData> create({required MyData data}) async {
       await _box.put(data.id, data.toObject());
       return data;
     }

     // ... other methods
   }
   ```

4. **Register in DI**:
   ```dart
   // lib/di/containers.dart
   injector.map<MyDataRepository>(
     (i) => MyDataHiveRepository(
       box: Hive.box<MyDataObject>('my_data'),
     ),
     isSingleton: true,
   );
   ```

5. **Generate code**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

### Adding Localization

1. **Add to English source**:
   ```json
   // lib/l10n/app_en.arb
   {
     "myNewKey": "Hello {name}!",
     "@myNewKey": {
       "description": "Greeting with name",
       "placeholders": {
         "name": {
           "type": "String"
         }
       }
     }
   }
   ```

2. **Add to other languages**:
   ```json
   // lib/l10n/app_ru.arb
   {
     "myNewKey": "Привет, {name}!"
   }
   ```

3. **Generate**:
   ```bash
   flutter gen-l10n
   ```

4. **Use**:
   ```dart
   final l10n = AppLocalizations.of(context)!;
   Text(l10n.myNewKey('Alice'));
   ```

### Adding SVG Assets

1. **Add SVG file**:
   ```
   assets/images/my_icon.svg
   ```

2. **Update pubspec.yaml**:
   ```yaml
   flutter:
     assets:
       - assets/images/
   ```

3. **Use**:
   ```dart
   import 'package:flutter_svg/flutter_svg.dart';

   SvgPicture.asset('assets/images/my_icon.svg')
   ```

## Code Style

### General Principles

1. **Be Consistent**: Follow existing patterns
2. **Keep it Simple**: Don't over-engineer
3. **Write Readable Code**: Clear names, comments where needed
4. **Follow Dart Style**: Use `dart format`

### Naming

```dart
// Classes - PascalCase
class MindRepository {}

// Files - snake_case
// mind_repository.dart

// Variables & Functions - camelCase
final mindCount = 10;
void createMind() {}

// Constants - camelCase or SCREAMING_SNAKE_CASE
const maxMindsPerDay = 100;
const API_TIMEOUT = 5000;

// Private - prefix with _
String _privateMethod() {}
```

### File Structure

```dart
// 1. Imports (sorted: dart, flutter, packages, relative)
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bloc/bloc.dart';
import 'package:hive/hive.dart';

import '../domain/mind.dart';
import 'mind_widget.dart';

// 2. Part statements
part 'mind_event.dart';
part 'mind_state.dart';

// 3. Class
class MindBloc extends Bloc<MindEvent, MindState> {
  // ...
}
```

### Widget Structure

```dart
class MyWidget extends StatelessWidget {
  // 1. Fields (const, final, then mutable)
  final String title;
  final VoidCallback? onTap;

  // 2. Constructor
  const MyWidget({
    super.key,
    required this.title,
    this.onTap,
  });

  // 3. Build method
  @override
  Widget build(BuildContext context) {
    return Container(/* ... */);
  }

  // 4. Private helper methods
  void _handleTap() {
    onTap?.call();
  }
}
```

### Comments

```dart
// Good: Explain WHY, not WHAT
// Calculate day index to group minds by date across timezones
final dayIndex = (timestamp + offset) ~/ millisecondsInDay;

// Bad: States the obvious
// Divide timestamp by milliseconds in day
final dayIndex = timestamp ~/ millisecondsInDay;

// Good: Document public APIs
/// Creates a new mind with the given [note] and [emoji].
///
/// Throws [MindException] if the note is empty.
Future<Mind> createMind({required String note, required String emoji});
```

## Testing

### Unit Tests

```dart
// test/domain/mind_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:keklist/domain/services/entities/mind.dart';

void main() {
  group('Mind', () {
    test('should create mind with valid data', () {
      final mind = Mind(
        id: '123',
        note: 'Test',
        emoji: '😊',
        dayIndex: 19000,
        creationDate: DateTime.now(),
        sortIndex: 0,
        rootId: null,
      );

      expect(mind.note, 'Test');
      expect(mind.emoji, '😊');
    });

    test('should copy with new values', () {
      final mind = Mind(/* ... */);
      final updated = mind.copyWith(note: 'Updated');

      expect(updated.note, 'Updated');
      expect(updated.emoji, mind.emoji); // Unchanged
    });
  });
}
```

### Widget Tests

```dart
// test/presentation/widgets/mind_widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:keklist/presentation/core/widgets/mind_widget.dart';

void main() {
  testWidgets('MindWidget displays emoji and note', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MindWidget(
          emoji: '😊',
          note: 'Test mind',
        ),
      ),
    );

    expect(find.text('😊'), findsOneWidget);
    expect(find.text('Test mind'), findsOneWidget);
  });
}
```

### Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/domain/mind_test.dart

# With coverage
flutter test --coverage
```

## Debugging

### Flutter DevTools

```bash
flutter run
# Then press 'v' in terminal to open DevTools
```

### Debug Prints

```dart
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  print('Debug: mind created with id ${mind.id}');
}
```

### Logging

```dart
import 'package:keklist/keklist_app.dart';

logarte.log('Info message');
logarte.error('Error occurred');
```

### BLoC Logging

Already configured in `main.dart`:

```dart
class _LoggerBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    print('onChange: ${bloc.state}');
  }
}
```

## CI/CD

### GitHub Actions

The project uses GitHub Actions for CI:

- **Build APK**: Automatically builds Android APK on push
- **Location**: `.github/workflows/build-apk.yml`

### Manual Release Process

1. **Update version** in `pubspec.yaml`:
   ```yaml
   version: 4.2.0+76
   ```

2. **Update CHANGELOG.md**

3. **Commit changes**:
   ```bash
   git add pubspec.yaml CHANGELOG.md
   git commit -m "Release v4.2.0"
   git tag v4.2.0
   git push origin master --tags
   ```

4. **Build release**:
   ```bash
   # Android
   flutter build appbundle --release

   # iOS
   flutter build ios --release
   ```

5. **Upload to stores**

## Performance Tips

1. **Use `const` constructors** where possible
2. **Avoid rebuilding entire trees** - use specific BlocBuilders
3. **Profile before optimizing** - use DevTools
4. **Lazy load data** - don't load everything at once
5. **Dispose controllers** - prevent memory leaks

## Useful Commands

```bash
# Clean build artifacts
flutter clean

# Update dependencies
flutter pub upgrade

# Analyze code
flutter analyze

# Format code
dart format lib/

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Generate localizations
flutter gen-l10n

# Run on specific device
flutter devices
flutter run -d <device-id>

# Build release APK
flutter build apk --release

# Check Flutter setup
flutter doctor -v
```

## Troubleshooting

### "Hive not initialized"
```bash
dart run build_runner build --delete-conflicting-outputs
```

### "Localization not found"
```bash
flutter gen-l10n
flutter clean
flutter run
```

### "Build failed after merge"
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

For more help, reach out on [Telegram](https://t.me/resashkin) or email sashkn2@gmail.com
