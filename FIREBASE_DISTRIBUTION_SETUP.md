# Firebase App Distribution Setup for Android

This guide will help you set up Firebase App Distribution for distributing Android builds to testers.

## Prerequisites

1. A Firebase project (create one at https://console.firebase.google.com)
2. Fastlane installed (already configured in this project)
3. Firebase CLI installed: `npm install -g firebase-tools`

## Setup Steps

### 1. Add Your App to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (or create a new one)
3. Click "Add app" and select Android
4. Register your app with package name: `com.sashkyn.emodzen`
5. Download the `google-services.json` file
6. Place it in `android/app/google-services.json`

### 2. Get Your Firebase App ID

1. In Firebase Console, go to Project Settings
2. Scroll down to "Your apps" section
3. Copy the App ID (looks like `1:123456789:android:abcdef123456`)
4. Save it - you'll need it for the next step

### 3. Set Up Environment Variables

Create or update `android/fastlane/.env` file:

```bash
FIREBASE_APP_ID=1:123456789:android:abcdef123456  # Your App ID from step 2
```

### 4. Authenticate with Firebase

Run this command to generate a CI token:

```bash
firebase login:ci
```

This will open a browser for authentication and generate a token. Save this token.

For local development, you can also use:

```bash
firebase login
```

### 5. Add Firebase Token to Environment

Add to `android/fastlane/.env`:

```bash
FIREBASE_APP_ID=1:123456789:android:abcdef123456
FIREBASE_TOKEN=your-token-from-step-4
```

**Important:** Add `.env` to `.gitignore` to keep credentials safe!

### 6. Create Tester Groups

1. Go to Firebase Console → App Distribution
2. Click "Testers & Groups"
3. Create a group called "testers" (or use a different name and update the Fastfile)
4. Add tester email addresses to the group

## Usage

### Basic Distribution

Distribute to the default "testers" group:

```bash
cd android
bundle exec fastlane distribute_firebase
```

### Distribution with Custom Release Notes

```bash
cd android
bundle exec fastlane distribute_firebase_with_notes notes:"Bug fixes and improvements"
```

### Distribution to Specific Groups

```bash
cd android
bundle exec fastlane distribute_firebase_with_notes notes:"New feature" groups:"beta-testers,internal"
```

### Distribution to Individual Testers

If you don't have groups set up yet, you can distribute directly to tester emails:

```bash
cd android
bundle exec fastlane distribute_firebase_with_notes notes:"New feature" testers:"email1@example.com,email2@example.com"
```

### Using the Helper Script

A convenience script is provided at `scripts/distribute_android.sh`:

```bash
# Simple distribution (no groups specified - upload only)
./scripts/distribute_android.sh

# With release notes (no groups specified - upload only)
./scripts/distribute_android.sh "Bug fixes and performance improvements"

# With custom groups
./scripts/distribute_android.sh "New feature" "beta-testers,qa-team"

# With individual testers (no groups)
./scripts/distribute_android.sh "New feature" "" "email1@example.com,email2@example.com"
```

## CI/CD Integration

For GitHub Actions or other CI systems, add these secrets:

- `FIREBASE_APP_ID`: Your Firebase App ID
- `FIREBASE_TOKEN`: Your Firebase CI token

Example GitHub Actions workflow:

```yaml
- name: Distribute to Firebase
  env:
    FIREBASE_APP_ID: ${{ secrets.FIREBASE_APP_ID }}
    FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
  run: |
    cd android
    bundle exec fastlane distribute_firebase_with_notes notes:"Build ${{ github.run_number }}"
```

## Troubleshooting

### "App not found" error

- Verify `FIREBASE_APP_ID` is correct
- Ensure `google-services.json` is in `android/app/`
- Check that the app is registered in Firebase Console

### Authentication errors

- Regenerate token with `firebase login:ci`
- For local development, try `firebase login` instead
- Verify `FIREBASE_TOKEN` is set correctly

### Build errors

- Ensure you have a valid signing configuration in `android/key.properties`
- Check that all dependencies are installed: `cd android && bundle install`

## File Structure

After setup, your Android directory should look like:

```
android/
├── app/
│   ├── google-services.json        # Firebase config (gitignored)
│   └── build.gradle.kts            # Updated with Firebase plugins
├── fastlane/
│   ├── .env                        # Environment variables (gitignored)
│   ├── Fastfile                    # Updated with distribution lanes
│   └── Appfile
└── settings.gradle.kts             # Updated with Firebase plugins
```

## Security Notes

**Never commit these files:**
- `android/app/google-services.json`
- `android/fastlane/.env`
- Any files containing Firebase tokens

Add to `.gitignore`:

```gitignore
# Firebase
android/app/google-services.json
android/fastlane/.env
**/firebase-debug.log
```

## Additional Resources

- [Firebase App Distribution Documentation](https://firebase.google.com/docs/app-distribution)
- [Fastlane Firebase App Distribution Plugin](https://docs.fastlane.tools/actions/firebase_app_distribution/)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
