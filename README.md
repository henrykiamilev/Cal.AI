# Calendar AI

A modern, AI-powered calendar app for iOS that helps you organize your schedule and achieve your goals.

## Features

### Core Calendar Features
- **Beautiful Calendar Views** - Day, Week, and Month views with smooth animations
- **Event Management** - Create, edit, and delete events with colors, locations, and reminders
- **Task Management** - Track tasks with priorities, categories, due dates, and subtasks
- **Recurring Events** - Support for daily, weekly, biweekly, monthly, and yearly recurrence

### AI-Powered Goal Scheduling (Premium)
- **Smart Goal Creation** - Define ambitious goals like "Become an investment banker" or "Lose 20 pounds"
- **AI Schedule Generation** - OpenAI GPT-4 creates personalized weekly schedules based on your goal
- **Adaptive Scheduling** - Schedules adjust based on your progress and completion rate
- **Progress Tracking** - Mark activities complete/incomplete and monitor your journey
- **Personalized Recommendations** - AI-powered tips to help you stay on track

### Security & Privacy
- **Secure Authentication** - Sign in with Apple + Email/Password options
- **Encrypted Storage** - Keychain for sensitive data, secure local storage
- **iCloud Sync** - CloudKit integration for encrypted cross-device sync
- **Data Export** - Export all your data anytime
- **No Data Leaks** - All data encrypted at rest and in transit

### Subscription
- **Free Tier** - Full calendar, events, and tasks functionality
- **Premium ($9.99/month)** - AI goal scheduling, adaptive plans, unlimited goals

## Technical Stack

- **Framework**: SwiftUI (iOS 17+)
- **Architecture**: MVVM with @Observable
- **Storage**:
  - Local: JSON files in Documents directory
  - Cloud: CloudKit (private database)
  - Secrets: iOS Keychain
- **AI**: OpenAI GPT-4 API
- **Payments**: StoreKit 2
- **Authentication**: AuthenticationServices (Sign in with Apple)

## Project Structure

```
CalAI/
├── CalAIApp.swift              # App entry point
├── ContentView.swift           # Main tab view
├── Info.plist                  # App configuration
├── CalAI.entitlements          # App capabilities
├── Assets.xcassets/            # App icons and colors
│
├── Models/
│   ├── EventModel.swift        # Calendar events
│   ├── TaskModel.swift         # Tasks and subtasks
│   ├── GoalModel.swift         # Goals, milestones, AI schedules
│   └── UserModel.swift         # User profile and preferences
│
├── Views/
│   ├── Calendar/
│   │   ├── CalendarView.swift      # Main calendar view
│   │   ├── DayView.swift           # Day view
│   │   ├── WeekView.swift          # Week view
│   │   ├── MonthView.swift         # Month view
│   │   ├── AddEventView.swift      # Create event
│   │   └── EventDetailView.swift   # View/edit event
│   │
│   ├── Tasks/
│   │   ├── TaskListView.swift      # Task list
│   │   └── AddTaskView.swift       # Create task
│   │
│   ├── Goals/
│   │   ├── GoalListView.swift      # Goals list
│   │   ├── AddGoalView.swift       # Create goal
│   │   ├── GoalDetailView.swift    # Goal details
│   │   ├── AIGoalView.swift        # AI schedule setup
│   │   ├── AIScheduleView.swift    # View AI schedule
│   │   └── ProgressView.swift      # Progress tracking
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift      # App settings
│   │   └── ProfileView.swift       # User profile
│   │
│   ├── Onboarding/
│   │   ├── OnboardingView.swift    # Welcome screens
│   │   └── LoginView.swift         # Authentication
│   │
│   └── Subscription/
│       └── SubscriptionView.swift  # Premium upgrade
│
├── Services/
│   ├── AIService.swift             # OpenAI integration
│   ├── DataManager.swift           # Data persistence
│   ├── SubscriptionManager.swift   # StoreKit handling
│   ├── AuthenticationManager.swift # Auth handling
│   ├── KeychainManager.swift       # Secure storage
│   └── CloudKitManager.swift       # iCloud sync
│
└── Utilities/
    ├── Extensions.swift            # Swift extensions
    ├── Theme.swift                 # Design system
    └── Components.swift            # Reusable UI components
```

## Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ device or simulator
- Apple Developer account (for Sign in with Apple & CloudKit)
- OpenAI API key (for AI features)

### Configuration

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Cal.AI
   ```

2. **Open in Xcode**
   ```bash
   open CalAI.xcodeproj
   ```

3. **Configure Signing**
   - Open project settings
   - Select your development team
   - Update bundle identifier if needed

4. **Set up Capabilities** (in Xcode > Signing & Capabilities)
   - Sign in with Apple
   - iCloud (CloudKit)
   - Push Notifications
   - Keychain Sharing

5. **Configure CloudKit**
   - Go to CloudKit Dashboard
   - Create container: `iCloud.com.calai.app`
   - Set up record types (CalendarEvent, Task, Goal, UserProfile)

6. **Set up StoreKit**
   - Configure in App Store Connect
   - Product ID: `com.calai.premium.monthly`
   - Price: $9.99/month

7. **OpenAI API Key**
   The API key is stored securely in Keychain. For production, use a backend proxy to protect API keys.

## Security Considerations

### Data Protection
- All user data stored locally is in the app's sandboxed container
- Sensitive data (API keys, auth tokens) stored in Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
- CloudKit data is encrypted at rest and in transit
- No plain-text passwords stored anywhere

### API Security
- OpenAI API calls use HTTPS with TLS 1.2+
- API key stored in Keychain, never in code or logs
- For production, consider using a backend proxy to protect API keys

### Authentication
- Sign in with Apple provides secure, privacy-focused auth
- Email/password auth connects to your secure backend
- Session tokens stored in Keychain

## Production Checklist

Before releasing to App Store:

- [ ] Connect email auth to real backend authentication
- [ ] Set up OpenAI API key via secure backend proxy
- [ ] Configure production CloudKit container
- [ ] Set up App Store Connect with subscription product
- [ ] Add Terms of Service and Privacy Policy URLs
- [ ] Generate app icons (1024x1024 required)
- [ ] Test subscription flow with sandbox accounts
- [ ] Configure push notifications for reminders
- [ ] Implement proper error tracking/analytics

## License

MIT License - See LICENSE file for details.

## Support

For support, email support@calendarai.app
