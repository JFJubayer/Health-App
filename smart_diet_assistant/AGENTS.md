# AGENTS.md — Smart Diet Assistant

## Build / Lint / Test Commands

```bash
# Install dependencies
flutter pub get

# Run static analysis (linter)
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run code generation (Hive adapters, etc.)
dart run build_runner build

# Watch mode for code generation
dart run build_runner watch

# Run the app on connected device/emulator
flutter run

# Build APK
flutter build apk
```

Lint rules come from `package:flutter_lints/flutter.yaml` (default Flutter lint set). Custom rules can be added in `analysis_options.yaml` under `linter.rules`.

## Code Style Guidelines

### Imports & Ordering
- Group imports: (1) Dart SDK, (2) Flutter/Package imports, (3) Project imports
- Separate groups with a blank line
- Use relative imports for project files (e.g., `'../models/user_model.dart'`)
- Use package imports for external packages (e.g., `'package:flutter/material.dart'`)

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/diet_service.dart';
```

### Naming Conventions
- **Classes/enums/mixins**: PascalCase (`UserModel`, `MealType`, `DietService`)
- **Files**: snake_case (`user_model.dart`, `diet_service.dart`)
- **Variables/fields/methods**: camelCase
- **Private members**: prefix with underscore (`_user`, `_isLoading`, `_buildHeader()`)
- **Constants**: camelCase, prefixed with `_key` for private (`_keyUser`, `_keyMeals`)
- **Enum values**: lowercase (`breakfast`, `lunch`, `dinner`)
- **Booleans**: prefix with `is` or `has` where possible (`isLoading`, `isConsumed`, `isFasting`)

### Types & Null Safety
- Use explicit type annotations on public API surfaces
- Use nullable types with `?` suffix (`UserModel?`, `DateTime?`)
- Use `final` for immutable fields, `var` for local variables only when type is obvious
- Prefer `const` constructors where possible (`const InputScreen({super.key})`)
- Use `required` named parameters for model constructors
- Use default values for optional parameters (`this.conditions = const []`)

### Formatting
- 2-space indentation (Dart default)
- Use trailing commas to trigger auto-formatter for multi-line expressions
- Run `dart format .` before committing

### Error Handling
- Use `try/catch/finally` for async initialization and risky operations
- Log errors with `debugPrint('message: $e')` and include stack trace
- Graceful fallbacks: `??` operator with sensible defaults
- Avoid rethrowing raw errors; handle at the Provider level and surface via state
- Do NOT use `print()` — use `debugPrint()` instead (respects log filtering)

### Architecture & Patterns
- **Models**: Pure data classes with `toMap()` / `factory fromMap()` for serialization
- **Hive entities**: Annotate with `@HiveType(typeId: N)` and `@HiveField(N)`, generate `.g.dart` via `build_runner`
- **Providers**: Extend `ChangeNotifier`, expose private fields via public getters, call `notifyListeners()` after mutations
- **Services**: Static methods grouped by domain (`DietService`, `HealthService`, `PersistenceService`)
- **Screens**: `StatefulWidget` with private `_State` class, decompose `build()` into `_build*()` helper methods
- **Animations**: Use `flutter_animate` extension methods (`.animate().fadeIn()`) on widgets

### Project Structure
```
lib/
  main.dart                 # App entry point, Hive init, Provider setup
  models/                   # Data models & Hive entities
  providers/                # ChangeNotifier state management
  screens/                  # Full-page UI screens
  services/                 # Business logic & persistence
  utils/                    # Shared utilities (theme)
  widgets/                  # Reusable widget components
test/                       # Flutter widget/unit tests
```

### Guidelines for AI Agents
- When adding models, follow the existing `toMap()`/`fromMap()` pattern
- When adding Hive entities, create the `.g.dart` by running `dart run build_runner build`
- When adding Provider state, follow `ChangeNotifier` + private field + getter pattern
- When adding screens, use `StatefulWidget` with private `_State` class
- When adding services, use `static` methods grouped in a class
- Use `debugPrint` for logging, never `print`
- Use `Provider.of<T>(context, listen: false)` for event-driven reads, `Consumer<T>` or `context.watch<T>()` for reactive rebuilds
- All UI text should be wrapped in `GoogleFonts.outfit()` for the primary font
- Use Material 3 (MaterialApp with `useMaterial3: true`)
- Use `Theme.of(context).colorScheme.*` for colors, avoid hardcoded colors
