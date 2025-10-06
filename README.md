# MoodMapper

A comprehensive iOS mood tracking application that allows users to log their emotional state with location data, sync across devices using Firebase, and visualize their mood patterns on an interactive map.

## Features

### Core Functionality
- **Mood Logging**: Record daily mood entries with 5-point scale (1-5)
- **Location Integration**: Automatically capture and store location data with each entry
- **Interactive Map**: Visualize mood entries on a map with color-coded markers
- **Cloud Synchronization**: Real-time sync across devices using Firebase Firestore
- **User Authentication**: Secure email/password authentication system
- **Data Persistence**: Local Core Data storage with CloudKit integration

### User Interface
- **Modern SwiftUI Design**: Clean, intuitive interface with glassmorphism effects
- **Tabbed Navigation**: Easy access to map view, home view, and settings
- **Mood Visualization**: Emoji-based mood representation with color coding
- **Quote Integration**: Inspirational quotes displayed on the map
- **Settings Management**: User preferences and account management

### Technical Features
- **Real-time Sync**: Bidirectional synchronization between local and cloud data
- **Offline Support**: Full functionality without internet connection
- **Error Handling**: Comprehensive error management and user feedback
- **Location Services**: GPS integration with permission handling
- **Data Validation**: Input validation and data integrity checks

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
