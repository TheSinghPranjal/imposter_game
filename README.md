# Find the Imposter

A playful pass-the-phone social deduction party game for Flutter.

## How it works

1. Add 3–20 player names  
2. Configure difficulty, imposters, and optional hints  
3. Pass the phone — each player long-presses to privately reveal their card  
4. Discuss and give clues **outside the app**  
5. Tap **Again!** for a fresh word and new imposters  

## Product rules baked in

- Imposters are never Player 1 or Player 2  
- Starting player is chosen independently of imposter selection  
- Imposters never see the secret word  
- Secrets hide when the app is backgrounded  

## Stack

- Flutter + Riverpod  
- Offline 600-word pack (`assets/data/imposter_words.json`)  
- SharedPreferences for settings  

## Run

```bash
flutter pub get
flutter run
flutter test
```

## Configuring AdMob for release

Debug and profile builds always request Google's sample ad units, so they show **Test Ad**. Release builds (`flutter build appbundle`, `flutter build ipa`, `flutter run --release`) request the production IDs in [`config/admob.json`](config/admob.json). That file is the only place to paste them. The publisher account is `pub-8661918790125012`.

This app does not have AdMob app or unit IDs yet. Every value in `config/admob.json` is a `TODO_…` placeholder, so a release build fails until they are replaced. There is no rewarded ad: nothing in the game trades a view for a reward.

Create the apps and ad units in AdMob, then replace each `TODO_…` value:

| JSON key | What to paste | Format | Where it is used |
| --- | --- | --- | --- |
| `ADMOB_ANDROID_APP_ID` | Android app → App settings → App ID | `ca-app-pub-8661918790125012~##########` | Android manifest app ID |
| `ADMOB_ANDROID_BANNER_ID` | Android banner ad unit | `ca-app-pub-8661918790125012/##########` | Home menu and the between-rounds screen |
| `ADMOB_ANDROID_INTERSTITIAL_ID` | Android interstitial ad unit | `ca-app-pub-8661918790125012/##########` | Between rounds, every 4th Again tap, at least 90 seconds apart |
| `ADMOB_IOS_APP_ID` | iOS app → App settings → App ID | `ca-app-pub-8661918790125012~##########` | Info.plist `GADApplicationIdentifier` |
| `ADMOB_IOS_BANNER_ID` | iOS banner ad unit | `ca-app-pub-8661918790125012/##########` | Home menu and the between-rounds screen |
| `ADMOB_IOS_INTERSTITIAL_ID` | iOS interstitial ad unit | `ca-app-pub-8661918790125012/##########` | Between rounds, every 4th Again tap, at least 90 seconds apart |

Register both apps under publisher `pub-8661918790125012`:

- Android package `com.the_lazy_bear_club.imposter_game`
- iOS bundle `com.thelazybearclub.imposterGame`

Where those values are applied:

- **Dart ad units** read `config/admob.json` (it is a bundled asset). You can override any key at compile time with `--dart-define` or `--dart-define-from-file=config/admob.json`. The keys are the same names as in the JSON file.
- **Android App ID** is injected into `AndroidManifest.xml` as `${admobAppId}`. Gradle reads `ADMOB_ANDROID_APP_ID` from the JSON for release, and Google's sample App ID for debug and profile.
- **iOS App ID** is `$(GAD_APPLICATION_IDENTIFIER)` in `ios/Runner/Info.plist`. Debug and profile xcconfigs pin the sample App ID. Release reads `ios/Flutter/AdMob.xcconfig`, which is generated from the JSON:

```bash
dart run tool/sync_admob.dart
```

Run that after every edit to the iOS App ID. A release iOS build fails if the xcconfig is stale.

Release builds also fail, instead of silently shipping test ads, when an ID is empty, still a `TODO_…` placeholder, or still one of Google's sample IDs (`ca-app-pub-3940256099942544…`):

- `flutter build appbundle` / `flutter build apk --release` runs `dart run tool/validate_admob.dart --android` before packaging.
- Xcode Release runs `tool/validate_admob_ios.sh`.
- The release app itself throws on startup if the current platform's IDs are still invalid.

Android can ship before the iOS IDs exist. The Android check only looks at the Android keys, and the iOS check only looks at the iOS keys.

Ads are not shown during the pass-the-phone role reveal. On launch, the app requests UMP consent before initializing Mobile Ads. If consent is not required, or the consent check fails or times out without an actual denial, Mobile Ads still starts. Ads stay off only when consent is required and the user has not granted it. If a privacy-options entry point is required, Settings shows **Ad privacy choices**.

### Verify a release build shows real ads

1. Paste the real IDs into `config/admob.json` and run `dart run tool/sync_admob.dart`.
2. Build a release artifact, for example `flutter build appbundle`. The command fails with `error: Release Android AdMob IDs are still sample values or placeholders` until the Android keys are real.
3. Install that release build (Play internal testing, or `flutter run --release` on a device). In logcat or the Xcode console, filter for `AdMob`. A good release log looks like `AdMob mode: RELEASE` and every unit starts with `ca-app-pub-8661918790125012/`.
4. Confirm the banner and interstitial creatives are **not** labeled Test Ad. New production units can take a while to fill; a no-fill is different from a Test Ad.
5. `flutter run` (debug) and `flutter run --profile` should still log `AdMob mode: TEST` and show Test Ad. Those builds keep Google's sample App ID even after you fill in the JSON.
