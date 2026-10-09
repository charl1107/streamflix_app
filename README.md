# streamflix_tv

A new Flutter project.

## Configuration (env.json)

The TMDB key lives in `env.json`, which is gitignored (only `env.json.example`
is tracked). It is bundled as an asset and loaded at startup in
`ApiConfig.load()`, so no `--dart-define` flag is needed:

```powershell
Copy-Item env.json.example env.json   # then fill in the real key
flutter run
```

If you *do* pass `--dart-define-from-file=env.json`, that value wins over the
bundled asset.

## Android TV

The manifest ships with a `LEANBACK_LAUNCHER` intent-filter, a TV banner and
`touchscreen required=false`, so it installs on Android TV devices as-is:

```powershell
flutter run --release -d <tv-device-id>
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
