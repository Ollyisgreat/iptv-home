# TV Home

- `TVHome/`: Fire TV launcher (Android, WebView UI in `app/src/main/assets/index.html`).
  Build: `./gradlew assembleDebug` (JDK 17), install with `adb install -r app/build/outputs/apk/debug/app-debug.apk`.
- `Roku/`: Roku app (BrightScript / SceneGraph). Zip the folder contents (`manifest`, `source`, `components`, `images`, `fonts`)
  and upload through the Roku developer installer.
