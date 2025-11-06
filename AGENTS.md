# Repository Guidelines

## Project Structure & Module Organization
- Source screens live under `lib/view/`, view models in `lib/view_model/`, and Firebase access under `lib/repository/` and `lib/data_source/`.
- Shared widgets and theming sit in `lib/component/`; keep reusable pieces there instead of duplicating in views.
- Tests mirror features in `test/`, while platform shells reside in `android/`, `ios/`, and `web/`.
- Store visual assets in `assets/images/` and `assets/animations/`, and define fonts in `pubspec.yaml`.

## Build, Test, and Development Commands
- `flutter pub get` installs Dart and Flutter dependencies after changes to `pubspec.yaml`.
- `flutter run -d <device_id>` launches the app on a connected simulator or device for manual verification.
- `flutter test` executes the unit and widget suites under `test/`; run before committing.
- `flutter build apk --release` generates a distributable Android package; ensure CI passes beforehand.

## Coding Style & Naming Conventions
- Follow the `flutter_lints` configuration in `analysis_options.yaml`; keep indentation at two spaces.
- Use PascalCase for widgets/classes, lowerCamelCase for variables and methods, and snake_case file names (e.g., `plan_view_model.dart`).
- Run `dart format lib test` prior to review, and confirm `flutter analyze` completes without issues.

## Testing Guidelines
- Prefer `testWidgets` for UI flows and fake repositories for deterministic view model tests.
- Mirror feature folders (e.g., `test/view/home/home_page_test.dart`) to keep coverage aligned with production code.
- Execute `flutter test --coverage` before releases and review `coverage/lcov.info` for regressions in budget and plan features.

## Commit & Pull Request Guidelines
- Format commits as `YYYY/MM/DD <short summary>` and scope each change to one logical update.
- Reference related issues in the commit body and note affected screens when altering UI.
- PRs should explain context, attach screenshots or recordings for visual changes, and include `flutter test` output or other validation evidence.

## Security & Configuration Tips
- Never commit secrets beyond generated Firebase shells (`google-services.json`, `GoogleService-Info.plist`).
- Regenerate `lib/firebase_options.dart` via `flutterfire configure` when environments change, and document new runtime flags.
