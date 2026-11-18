# Releasing Your Shop Admin

The panel ships two ways: the **web** build on Firebase Hosting (what most
admins use, on a laptop or tablet) and an **Android** app bundle. Both talk
to the same Firebase project as the shop, `nabilrayhanshopping`.

## Before the first release (one time)

1. **Register the apps in Firebase** (console → Project settings → Add app):
   Android `com.sbfrusho.yourshopadmin` with the debug and release SHA-1,
   and a web app. Then run `flutterfire configure` in this repo. It
   rewrites `lib/firebase_options.dart` and `android/app/google-services.json`.
   Until then CI patches the Android file and the web build uses the old
   web config.
2. **Deploy the backend** from the customer repo (`UTM_clothing_app`), with
   the Blaze plan and Storage enabled:
   `firebase deploy --only functions,firestore,storage`. The panel's
   cancel, disable-account and image-upload features need it.
3. **Admin accounts:** set `isAdmin: true` on each admin's `users/{uid}`
   document in the console. There is no sign-up.
4. **Config:** `cp env/example.json env/prod.json` (git-ignored) and set
   `APP_ENV` to `prod` and `FUNCTIONS_BASE_URL` to
   `https://asia-southeast1-nabilrayhanshopping.cloudfunctions.net`.

## Web (Firebase Hosting)

One time:

```sh
firebase login
firebase hosting:sites:create yourshop-admin     # any free site name
firebase target:apply hosting admin yourshop-admin   # if you chose another name
```

Then, in the Firebase console → Authentication → Settings → **Authorized
domains**, add `yourshop-admin.web.app` (and any custom domain), or sign-in
fails on the hosted panel.

Each release:

```sh
firebase deploy --only hosting:admin
```

`firebase.json` builds the release web app first (`predeploy`), serves
`build/web` with every path rewritten to `index.html` (so links like
`/orders/abc` work on reload), never caches HTML/JS (new versions show up
on the next load), and sends `noindex` plus framing and sniffing protection
headers. Preview before going live:

```sh
firebase hosting:channel:deploy preview --only admin --expires 7d
```

## Android

1. Create an upload keystore (one time) and back it up with its passwords:
   ```sh
   keytool -genkey -v -keystore ~/yourshop-admin-upload.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (git-ignored):
   ```properties
   storePassword=<store password>
   keyPassword=<key password>
   keyAlias=upload
   storeFile=/Users/<you>/yourshop-admin-upload.jks
   ```
   Without it, release builds are signed with the debug key (fine for local
   testing only).
3. Build:
   ```sh
   flutter build appbundle --release --dart-define-from-file=env/prod.json
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`.

The admin app is for staff, so publish it on Google Play as an **internal
testing** or **closed testing** track (invite admins by email), or install the
APK directly (`flutter build apk --release ...`). It doesn't need a public
store listing.

## Every release

- Bump `version:` in `pubspec.yaml` (`<name>+<code>`; the code must always go
  up for Android).
- Run the checks (format, analyze, tests) and regenerate and look at the
  screenshots: `flutter test tool/screenshots_test.dart --update-goldens`.
- Add an entry to [RELEASE_NOTES.md](RELEASE_NOTES.md).

## Icons and splash

Drawn in code from `BrandMarkPainter` (cream bag on charcoal, the shop's
mark inverted). After changing the mark or colours:

```sh
flutter test tool/generate_brand_assets_test.dart   # PNGs + web icons
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
