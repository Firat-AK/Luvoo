# Luvoo - Dating App MVP

A Flutter-based dating app focused on meaningful connections. Built with Firebase backend.

## Features

- 🔐 Email/password authentication
- 👤 User profiles with photos and bios
- 🔍 Discovery feed (scrollable list)
- ❤️ Like and comment on profiles
- 💬 Real-time chat with matches
- 🎯 Auto-match creation on mutual likes

## Tech Stack

- **Frontend**: Flutter (Dart)
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Backend**: Firebase
  - Authentication
  - Firestore (NoSQL DB)
  - Storage (images)

## Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Firebase CLI
- Android Studio / Xcode
- Git

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/luvoo.git
   cd luvoo
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Create a Firebase project:
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create a new project
   - Enable Authentication (Email/Password)
   - Create a Firestore database
   - Enable Storage
   - Add Android/iOS apps and download config files

4. Configure Firebase:
   - Place `google-services.json` in `android/app/`
   - Place `GoogleService-Info.plist` in `ios/Runner/`
   - Update Firebase rules for Firestore and Storage

5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   ├── services/         # Firebase services
│   └── widgets/          # Reusable widgets
├── features/
│   ├── auth/             # Authentication
│   ├── profile/          # User profiles
│   ├── discovery/        # User discovery
│   └── chat/             # Messaging
├── models/               # Data models
├── routes/               # App routing
└── main.dart            # App entry
```

## Firebase Rules

### Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /likes/{userId}/liked/{targetId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /matches/{matchId} {
      allow read: if request.auth != null && 
        (resource.data.userA == request.auth.uid || 
         resource.data.userB == request.auth.uid);
      allow create: if request.auth != null;
    }
    
    match /messages/{matchId}/messages/{messageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Storage

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for the backend services
- All contributors and users of the app
