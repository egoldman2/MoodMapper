# MoodMapper

A comprehensive iOS mood tracking application that allows users to log their emotional state with location data, sync across devices using Firebase, and visualize their mood patterns on an interactive map.

## Features

### Core Functionality

#### Mood Tracking System
- **5-Point Mood Scale**: Record emotional state from 1 (sad) to 5 (euphoric)
- **Emoji Visualization**: Intuitive emoji representation (😞 😕 😐 🙂 😄)
- **Color-Coded System**: Visual color coding for quick mood identification
- **Timestamp Tracking**: Automatic date and time recording for each entry
- **Custom Notes**: Optional text notes to capture mood context and details
- **Mood History**: Complete chronological record of emotional patterns

#### Location Intelligence
- **Automatic GPS Capture**: Seamless location detection for each mood entry
- **Place Name Resolution**: Automatic conversion of coordinates to readable place names
- **Location-Based Insights**: Understand how different locations affect your mood

#### Interactive Map Visualization
- **Real-Time Map Display**: Live map showing all mood entries with custom markers
- **Color-Coded Markers**: Visual mood representation directly on the map
- **Interactive Markers**: Tap markers to view detailed mood information
- **Zoom and Pan Controls**: Full map navigation with gesture support
- **User Location Tracking**: Current location display

### User Interface & Experience

#### Modern Design System
- **SwiftUI Architecture**: Built with Apple's latest UI framework
- **Glassmorphism Effects**: Modern translucent design elements
- **Dark/Light Mode Support**: Automatic adaptation to system appearance
- **Smooth Animations**: Fluid transitions and micro-interactions

#### Navigation & Usability
- **Tab-Based Navigation**: Intuitive bottom tab bar for easy access
- **Swipe Gestures**: Natural swipe interactions for common actions
- **Quick Actions**: Fast mood entry with minimal taps

### Cloud & Synchronization

#### Real-Time Sync Engine
- **Bidirectional Synchronization**: Seamless data sync between devices
- **Conflict Resolution**: Intelligent merging of conflicting data
- **Offline Queue**: Automatic sync when connection is restored
- **Sync Status Indicators**: Clear visual feedback on sync status

#### Data Security & Privacy
- **End-to-End Encryption**: Secure data transmission and storage
- **User Authentication**: Secure email/password authentication
- **Secure Backup**: Encrypted cloud backup

### Technical Features

#### Performance & Reliability
- **Optimized Core Data**: Efficient local database
- **Data Integrity**: Comprehensive data validation

#### Error Handling & Recovery
- **Graceful Degradation**: App continues to function during network issues
- **Automatic Retry**: Smart retry mechanisms for failed operations
- **User Feedback**: Clear error messages and recovery suggestions
- **Data Recovery**: Automatic data recovery from sync conflicts
- **Offline Mode**: Full functionality without internet connection
- **Debug Logging**: Comprehensive logging for troubleshooting

## Setup Instructions

### Prerequisites
- iOS 26.0 or later
- Internet connection
- Location permissions

### Dependencies
The project uses Swift Package Manager for dependencies:
- Firebase/Auth
- Firebase/Firestore
- Firebase/Core
- CoreLocation
- MapKit

### Configuration

#### Location Services
- The app requires location permission to function properly
- Users will be prompted to grant location access on first launch
- Location data is used to associate mood entries with specific places

## Error Handling

### Core Data Errors
The app implements comprehensive error handling for Core Data operations:

```swift
// Automatic error handling for save operations
Utils.handleCoreDataSaveError(error, context: viewContext, operation: "save mood entry")

// Automatic error handling for fetch operations
Utils.handleCoreDataFetchError(error, operation: "fetch mood entries")
```

**Error Types Handled:**
- Save conflicts and validation errors
- Fetch request failures
- Context rollback on critical errors
- Data integrity violations

### Network Errors
Robust network error handling for Firebase operations:

```swift
// Network error handling
Utils.handleNetworkError(error, operation: "sync with Firebase")

// Firebase-specific error handling
Utils.handleFirebaseError(error, operation: "authentication")
```

**Error Types Handled:**
- Connection timeouts
- Authentication failures
- Firestore permission errors
- Sync conflicts and data corruption

### User Experience
- **Graceful Degradation**: App continues to function offline
- **User Feedback**: Clear error messages and loading states
- **Data Recovery**: Automatic retry mechanisms for failed operations
- **Conflict Resolution**: Smart merging of local and remote data

### Debugging Features
- **Comprehensive Logging**: Detailed error logs for development
- **Error Categorization**: Specific error types for easier debugging
- **Performance Monitoring**: Sync status and timing information
- **Data Validation**: Input validation with user-friendly error messages

## Testing

### Unit Tests
The project includes comprehensive unit tests covering:

- **Core Data Operations**: Save, fetch, and delete operations
- **Firebase Integration**: Authentication and sync functionality
- **Location Services**: GPS data handling and validation
- **Utility Functions**: Mood scoring and emoji mapping
- **Error Handling**: Error scenarios and recovery mechanisms

## Architecture

### Core Components
- **MoodMapperApp**: Main app entry point with dependency injection
- **PersistenceController**: Core Data stack management
- **FirestoreSyncService**: Cloud synchronization service
- **AuthenticationService**: User authentication management
- **LocationService**: GPS and location data handling

### Data Model
- **MoodEntry**: Core entity with mood score, location, timestamp, and notes
- **Cloud Sync**: Bidirectional synchronization with conflict resolution
- **Local Storage**: Core Data with FireBase integration

### Design Patterns
- **MVVM Architecture**: Clean separation of concerns
- **ObservableObject**: Reactive data binding
- **Dependency Injection**: Service layer abstraction
- **Repository Pattern**: Data access abstraction
