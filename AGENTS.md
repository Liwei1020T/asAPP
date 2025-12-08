<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# Repository Guidelines

## Project Structure & Module Organization
- `lib/` uses Clean Architecture: `core/` (config, constants, router, theme, utils, widgets), `data/` (models, repositories), `features/` (auth, dashboard, classes, attendance, salary, timeline, etc.), and `main.dart` as entrypoint.
- `assets/` holds static resources; `local_storage/` stores uploaded files for local testing; `supabase/*.sql` contains schema fixes and RLS updates.
- `documentation/` keeps reference docs; `test/` contains unit/widget tests; platform and build outputs live under `android/`, `web/`, `windows/`, and `build/`.

## Build, Test, and Development Commands
- `flutter pub get` installs dependencies.
- `flutter analyze` enforces static analysis (uses flutter_lints).
- `dart format lib test` applies standard Dart formatting (2-space indent).
- `flutter test` or `flutter test --coverage` runs unit/widget suites and produces coverage data.
- `flutter run -d chrome --web-port=8080` serves the PWA locally.
- `flutter build web` produces an optimized web bundle for deployment.

## Coding Style & Naming Conventions
- Follow analyzer guidance from `analysis_options.yaml` (flutter_lints); prefer `const` widgets, avoid unused imports, and keep functions small and pure where possible.
- Naming: classes/enums in `PascalCase`, methods/variables in `camelCase`, files in `snake_case.dart` (e.g., `session_repository.dart`), widgets end with `*Widget` or domain-specific nouns.
- Keep line length reasonable (~100 chars), organize imports (dart -> package -> project), and document non-obvious logic with brief comments.

## Testing Guidelines
- Place tests under `test/feature_name/` with filenames matching source files (`classes_page_test.dart`).
- Use `flutter_test` and fakes for Supabase-bound logic; prefer rendering widgets with meaningful testable keys.
- Run `flutter test` before pushing; use `flutter test --coverage` when touching business logic or data access.

## Commit & Pull Request Guidelines
- Use conventional prefixes seen in history (`feat:`, `fix:`, `refactor:`); keep subjects in present tense and under ~72 chars.
- Include concise PR descriptions, linked issues/tasks, and notes on Supabase SQL updates when applicable.
- Attach screenshots/GIFs for UI changes (responsive views) and mention any new env or storage requirements.
- Ensure docs stay in sync: update `README.md`, `documentation/`, or SQL scripts when behavior/config changes.

## Configuration & Security Tips
- Supply `SUPABASE_URL` and `SUPABASE_ANON_KEY` in your local config (`lib/main.dart`); never commit secrets or production keys.
- Run `dataSetUp.sql` once per environment and apply fix scripts under `supabase/` in the listed order.
- For local uploads, serve `local_storage/` via an HTTP server (e.g., `python3 -m http.server 9000 --directory local_storage`) and avoid storing sensitive assets.
