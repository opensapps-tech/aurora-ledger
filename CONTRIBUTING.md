# Contributing to Aurora Ledger

## Principles

Every contribution must respect the three core constraints:

1. **Zero infrastructure** — no servers, no accounts, no telemetry introduced
2. **Constant-time crypto** — no home-grown crypto; libsodium only
3. **CRDT correctness** — all merge policy changes need a written proof of convergence

## Development setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

## Code generation

Aurora uses `drift` (database) and `freezed` (data classes) with `build_runner`.
After changing any `@DriftDatabase`, `@DriftAccessor`, `@freezed`, or `@riverpod` annotated files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Branching

- `main` — production, protected, requires PR + CI green
- `develop` — integration branch
- Feature branches: `feature/short-description`
- Bug fixes: `fix/short-description`

## PR checklist

- [ ] `flutter analyze` passes
- [ ] `dart format` applied
- [ ] Tests added or updated
- [ ] No new server/network dependencies
- [ ] CHANGELOG.md updated
