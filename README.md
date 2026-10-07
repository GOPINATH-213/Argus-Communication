# Argus Communication

Argus Communication is a premium, interactive Flutter-based English speaking coach specifically tailored for Tamil learners. The application leverages Google's Gemini generative AI model directly on the client side to guide users through real-world speech scenarios, provide custom corrections, translate explanation details into Tamil, and track user growth over time.

---

## Key Features

1. **Interactive Real-life Scenarios**: Rehearse English speaking in structured situations such as a Job Interview, Hotel Booking, Railway Station, or General Practice.
2. **Dynamic AI Feedback**: Uses the Gemini API to analyze speech, give positive coaching, provide grammatical corrections, and write helpful explanations in Tamil.
3. **Speech-to-Text & Text-to-Speech**: Hands-free conversation experience where learners tap the mic to speak and listen to the AI coach.
4. **Daily Practice Alarm**: Custom timezone-aware local notification reminders to prompt users to practice and maintain their daily streak.
5. **Usage Limits**: Automatically limits users to 20 conversation turns per day to control API costs, while preserving the turn limit counter across profile resets.
6. **Analytics & History**: Track grammar, fluency, and confidence scores visually over time with interactive growth charts, and view complete transcript histories.

---

## Getting Started

### Prerequisites

Ensure you have the following installed on your machine:
* **Flutter SDK**: `^3.10.7`
* **Dart SDK**: `^3.0.0`
* **Android Studio / Xcode** (for compiling to emulator or physical device)

---

### Installation & Configuration

#### 1. Clone the Repository
```bash
git clone <repository_url>
cd "Argus Communication"
```

#### 2. Configure Environment Variables
Create a file named `.env` in the root directory (`/`) of the project. This file is excluded from version control to protect your credentials. Add the following line:

```env
GEMINI_API_KEY=AIzaSyAwcdEa0l9IMVUTbOF92ssUOaA494ekDDw
```
> **Note**: Replace the value above with your personal Google AI Studio Gemini API key. The application uses the `google_generative_ai` SDK to load this key at runtime via `flutter_dotenv`.

#### 3. Install Dependencies
Run the command below to fetch all required packages (including local notifications, database wrappers, and speech handlers):
```bash
flutter pub get
```

#### 4. Run Code Generation (Optional)
If you modify any local Hive database models or adapters, run the build generator:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 5. Run the Application
Start the development server or compile the app to a connected device:
```bash
flutter run
```

---

## Permissions & Device Configuration

The app requires specific device permissions for a smooth experience:

### Android
Permissions are declared in `android/app/src/main/AndroidManifest.xml`:
* `RECORD_AUDIO` - Required to record voice responses.
* `POST_NOTIFICATIONS` - Required to trigger daily practice alarms (Android 13+).
* `SCHEDULE_EXACT_ALARM` - Required to trigger practice reminders exactly on schedule.
* `RECEIVE_BOOT_COMPLETED` - Reschedules the daily practice alarms automatically after device reboots.

### iOS
Permissions are declared in `ios/Runner/Info.plist`:
* `NSMicrophoneUsageDescription` - Description of why the app accesses the microphone.
* `NSSpeechRecognitionUsageDescription` - Description of why the app uses speech recognition.

---

## Project Structure

* `lib/main.dart` - Entrypoint of the app. Initializes environment configurations, local database storage, and notifications.
* `lib/core/`
  * `network/api_client.dart` - Handles direct Gemini generative models, prompt instructions, and response parsing.
  * `storage/hive_service.dart` - Local persistent storage manager (handles profiles, streaks, historical turns, and daily limit tracking).
  * `notifications/notification_service.dart` - Timezone-aware local reminder scheduling.
  * `theme/app_theme.dart` - Premium dark theme palette (Navy, Gold, Charcoal).
* `lib/features/`
  * `onboarding/` - Welcome, splash, and user profile creation screens.
  * `chat/` - Practice conversational UI, audio listeners, and text-to-speech providers.
  * `home/` - Dashboard layout containing the Practice scenarios, Progress charts, History transcripts, and settings panel.
