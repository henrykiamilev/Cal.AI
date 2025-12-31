# Cal.AI - AI-Powered Calendar App

Cal.AI is a modern iOS calendar application with AI-powered goal planning capabilities. It helps users organize their schedule, track tasks, and achieve their goals with personalized AI-generated roadmaps.

## Features

### Core Calendar
- **Month/Day Views**: Clean, intuitive calendar interface with monthly grid and daily timeline views
- **Event Management**: Create, edit, and delete events with categories, colors, locations, and reminders
- **Recurring Events**: Support for daily, weekly, monthly, and yearly recurrence patterns

### Task Management
- **Task Tracking**: Manage tasks with priorities, due dates, and categories
- **Smart Filters**: View all, today, upcoming, overdue, or completed tasks
- **Quick Actions**: Swipe to complete or delete tasks

### AI-Powered Goal Planning
- **Goal Creation**: Set personal, career, health, education, and other goals
- **AI Schedule Generation**: Get personalized, phased roadmaps to achieve your goals
- **Progress Tracking**: Track completion of AI-generated tasks and milestones
- **Adaptive Planning**: AI adjusts your schedule based on your progress

### User Experience
- **Modern UI**: Clean, minimalist SwiftUI design
- **Onboarding**: Guided setup to personalize the experience
- **Haptic Feedback**: Subtle haptics for a premium feel
- **Local Notifications**: Reminders for events, tasks, and AI-scheduled activities

### Security
- **Encrypted Storage**: All sensitive data is encrypted using AES-256
- **Keychain Integration**: Secure storage for API keys and credentials
- **File Protection**: iOS file protection for data at rest
- **No Data Leaks**: All data stays on device (except AI requests to OpenAI)

## Architecture

```
Cal.AI/
├── App/                    # App entry point and configuration
├── Core/
│   ├── Configuration/      # App configuration and constants
│   ├── Extensions/         # Swift extensions
│   └── Utilities/          # Keychain, Encryption, Haptics, Notifications
├── Data/
│   ├── CoreData/           # Core Data models and persistence
│   ├── Models/             # Domain models (Event, Task, Goal, etc.)
│   └── Repositories/       # Data access layer
├── Services/
│   ├── AI/                 # AI service integration (OpenAI)
│   └── Calendar/           # Calendar business logic
├── ViewModels/             # MVVM ViewModels
└── Views/
    ├── Components/         # Reusable UI components
    ├── Modifiers/          # Custom view modifiers
    └── Screens/            # Main app screens
```

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Setup
1. Clone the repository
2. Open the project in Xcode
3. Build and run on simulator or device

### AI Features
To enable AI-powered goal planning:
1. Get an OpenAI API key from [platform.openai.com](https://platform.openai.com)
2. Go to Settings → AI Settings → OpenAI API Key
3. Enter your API key

## Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Local data persistence with encryption
- **CryptoKit**: AES-256 encryption for sensitive data
- **Combine**: Reactive data binding
- **OpenAI API**: GPT-4 for AI-powered goal planning

## Security Considerations

- All data is stored locally on the device
- Sensitive data (AI schedules, user profiles) is encrypted at rest
- API keys are stored in the iOS Keychain
- No analytics or tracking
- AI requests are made directly to OpenAI (your data is subject to OpenAI's privacy policy)

## License

MIT License - See LICENSE file for details
