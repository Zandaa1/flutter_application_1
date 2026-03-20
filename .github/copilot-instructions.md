AI Prompting Outline: Fleet Driver Flutter App

Project Context: Fleet Management System

This project is a comprehensive logistics and fleet management system for a company that rents out trucks. It consists of two main components communicating via REST APIs:

Web App (Admin Backend): Handled by the lead developer. Admins use this dashboard to assign drivers to routes, manage truck details/manifests, monitor live driver locations, handle accounting (fuel consumption), and chat with drivers.

Mobile App (Driver Frontend): Handled by you (the OJT student) using Flutter. Drivers use this app to:

Securely log in with strict device hardware binding (1 account = 1 specific phone).

View currently assigned job orders and routes.

Upload required pre-ride photos (truck condition, odometer, manifest).

Launch external navigation apps (Waze/Google Maps).

Continuously stream their GPS location to the admin dashboard every 60 seconds (background polling).

Upload fuel receipts and chat with admins mid-ride.

Upload final post-ride photos to complete the job.

This document provides a step-by-step prompt outline to build the Driver Mobile App module by module using an AI coding assistant.

---
description: Fleet Driver Flutter App - Pututchini System Mobile Frontend
---

# AI Prompting Outline: Fleet Driver Flutter App (Pututchini System)

## Project Context: Fleet Management System

This project is a comprehensive **logistics and fleet management system** (Pututchini) for a company that rents out trucks. It consists of multiple components communicating via REST APIs:

### **System Architecture**

```mermaid
flowchart LR
    %% Custom Styling
    classDef hub fill:#ffffff,stroke:#e67e22,stroke-width:5px,color:#333333,font-weight:bold;
    classDef actor fill:#f4f6f7,stroke:#2c3e50,stroke-width:2px,color:#2c3e50,rx:10;

    %% The Central Hub
    Hub(((fa:fa-network-wired Pututchini\nSystem Hub))):::hub

    %% The Actors / Entities
    Client[fa:fa-box-open Client]:::actor
    Admin[fa:fa-user-shield Admin]:::actor
    Driver[fa:fa-id-card Driver]:::actor
    Truck[fa:fa-truck-fast Truck]:::actor

    %% Connections & Data Flow
    Client <-->|1. Booking Requests & Communication| Hub
    Admin <-->|2. Web Platform:\nAssigns Trips, Accounts, & Manages Fleet| Hub
    Hub <-->|3. Mobile App:\nPre/Post Trip Uploads & SOS Alerts| Driver
    Truck -.->|4. Hardware Integration:\nLive GPS Location Pings (Every 5 mins)| Hub
```

### **System Components:**

1. **Web App (Admin Backend)** - Handled by lead developer
   - Dashboard for assigning drivers to routes
   - Truck management and manifest tracking
   - Live location monitoring of drivers
   - Fuel consumption accounting
   - Driver communication/chat

2. **Mobile App (Driver Frontend)** - *Your Flutter App* (This Project)
   - Drivers interact with this app while on duty
   - Real-time communication with dispatch

3. **Truck Hardware**
   - Sends GPS location pings every 5 minutes
   - Integrates with the system hub

---

## Driver Mobile App Features & Implementation Modules

### **Module 1: Authentication & Device Binding**
**Priority:** CRITICAL

#### Features:
- Secure login with OTP/token-based authentication
- Strict device hardware binding (1 account = 1 specific phone)
- Device fingerprinting (IMEI, device ID, hardware identifiers)
- Session management with token refresh

#### Implementation Notes:
- Use device_info_plus (already in pubspec.yaml) for hardware info
- Implement secure storage for authentication tokens
- Add device signature validation on backend
- Implement logout that invalidates device binding

---

### **Module 2: Job & Route Management**
**Priority:** HIGH

#### Features:
- View currently assigned job orders
- Display route details and navigation information
- Job status tracking (pending, in-progress, completed)
- Real-time job updates from admin

#### Implementation Notes:
- Create Job and Route data models
- Implement job list screen with pagination
- Add job detail screen with route preview
- WebSocket connection for real-time updates

---

### **Module 3: Pre-Ride Photo Upload**
**Priority:** HIGH

#### Features:
- Capture photos of truck condition
- Upload odometer readings (photo-based)
- Upload manifest photos
- Validation (all photos required before trip start)

#### Implementation Notes:
- Use image_picker_android plugin
- Implement camera preview and capture UI
- Create photo compression before upload
- Add upload progress indicator
- Store locally until confirmed by backend

---

### **Module 4: Navigation Integration**
**Priority:** MEDIUM

#### Features:
- Launch Waze with route coordinates
- Launch Google Maps with route coordinates
- Display route waypoints in-app preview

#### Implementation Notes:
- Use maps_launcher (already in pubspec.yaml)
- Parse waypoint coordinates from job data
- Add launch buttons in job detail screen
- Handle app not installed scenarios

---

### **Module 5: GPS Location Streaming & Background Service**
**Priority:** CRITICAL

#### Features:
- Stream GPS location to admin dashboard
- Background polling every 60 seconds (even when app minimized)
- Optimize battery consumption
- Handle poor connectivity scenarios

#### Implementation Notes:
- Use geolocator_android plugin (already in pubspec.yaml)
- Implement flutter_background_service (already in pubspec.yaml)
- Implement location buffering when offline
- Use foreground service with notification
- Handle permissions (location, battery)
- Implement GPS accuracy filtering

---

### **Module 6: Fuel Receipt Upload**
**Priority:** MEDIUM

#### Features:
- Capture fuel receipt photos during trip
- Upload multiple receipts in one trip
- Associate receipts with tank fills
- Fuel consumption tracking

#### Implementation Notes:
- Single or multi-image selection
- Image compression and batch upload
- Store upload metadata (timestamp, location, amount)
- Show upload history for current trip

---

### **Module 7: Real-Time Chat with Admin**
**Priority:** MEDIUM

#### Features:
- Send text messages to admin/dispatch
- Receive messages from admin
- Message history
- Notifications for new messages

#### Implementation Notes:
- Implement WebSocket connection for real-time messaging
- Use local database for message caching
- Implement offline message queuing
- Add typing indicators (optional)

---

### **Module 8: Post-Ride Photo Upload & Trip Completion**
**Priority:** HIGH

#### Features:
- Capture final trip photos (truck condition after delivery)
- Verify odometer readings match manifest
- Mark trip as complete
- Generate trip summary

#### Implementation Notes:
- Similar to pre-ride photo module
- Add completion confirmation dialog
- Upload all remaining data before completion
- Sync with backend trip status

---

### **Module 9: SOS Alerts & Emergency Communication**
**Priority:** HIGH

#### Features:
- Quick SOS button for emergencies
- Send emergency location to admin
- Call dispatcher directly
- Emergency contact information

#### Implementation Notes:
- Prominent SOS button in main screen
- One-tap emergency alert with location
- Send push notification to admin
- Log all SOS events

---

## Data Models

```dart
// Job/Order
class Job {
  String id;
  String truckId;
  String status; // pending, in_progress, completed
  DateTime startTime;
  DateTime? endTime;
  Route route;
  List<Photo> preRidePhotos;
  List<Photo> postRidePhotos;
  List<FuelReceipt> fuelReceipts;
}

// Route
class Route {
  String id;
  List<Location> waypoints;
  Location pickup;
  Location delivery;
  double distance;
  int estimatedDuration;
}

// Photo
class Photo {
  String id;
  String jobId;
  String type; // pre_condition, odometer, manifest, post_condition
  String filePath;
  DateTime timestamp;
  Location location;
  bool uploaded;
}

// Location
class Location {
  double latitude;
  double longitude;
  double accuracy;
  DateTime timestamp;
}

// Chat Message
class Message {
  String id;
  String senderId;
  String recipientId;
  String content;
  DateTime timestamp;
  bool read;
}

// Fuel Receipt
class FuelReceipt {
  String id;
  String jobId;
  double amount;
  String filePath;
  DateTime timestamp;
  Location location;
}
```

---

## API Endpoints (Reference)

```
POST   /api/auth/login                    - Driver login
POST   /api/auth/device-binding           - Register device binding
GET    /api/jobs/assigned                 - Get assigned jobs
GET    /api/jobs/:id                      - Get job details
PUT    /api/jobs/:id/status               - Update job status
POST   /api/photos/upload                 - Upload photos
POST   /api/location/stream                - Stream location (WebSocket)
POST   /api/messages/send                 - Send chat message
GET    /api/messages/:jobId               - Get chat history
POST   /api/emergency/sos                 - Send SOS alert
```

---

## Key Technical Requirements

### Performance & Optimization
- Minimize battery drain from GPS polling
- Implement efficient image compression
- Cache job data locally
- Implement smart sync strategy

### Security
- Encrypt sensitive data at rest
- Use secure HTTP only
- Implement certificate pinning
- Validate device binding on every request
- Sanitize user inputs

### Reliability
- Offline-first architecture for photos/data
- Automatic retry for failed uploads
- Background sync service
- Error logging and reporting

### User Experience
- Clear indication of upload progress
- Offline mode indicators
- Intuitive navigation
- Accessibility considerations (dark mode, text sizes)

---

## Development Workflow

1. **Setup**: Configure development environment, API endpoints
2. **Module-by-Module**: Build and test each feature independently
3. **Integration**: Integrate with backend REST APIs
4. **Testing**: Unit tests, widget tests, integration tests
5. **Deployment**: Beta testing, production release

---

## File Structure Reference

```
lib/
  ├── main.dart
  ├── models/
  │   ├── job.dart
  │   ├── route.dart
  │   ├── location.dart
  │   ├── message.dart
  │   └── photo.dart
  ├── screens/
  │   ├── auth/
  │   ├── jobs/
  │   ├── trip/
  │   ├── chat/
  │   └── settings/
  ├── services/
  │   ├── api_service.dart
  │   ├── location_service.dart
  │   ├── photo_service.dart
  │   └── message_service.dart
  └── utils/
      ├── constants.dart
      └── helpers.dart
```

---

## Dependencies Already Included

- `device_info_plus` - Hardware device information
- `geolocator_android` - GPS location services
- `flutter_background_service_android` - Background service execution
- `flutter_local_notifications` - Local notifications
- `image_picker_android` - Camera/gallery access
- `permission_handler_android` - Permission management
- `package_info_plus` - App info
- `url_launcher_android` - Open external apps
- `maps_launcher` - Launch Maps/Waze
- `path_provider_android` - File storage paths

---

## Next Steps

1. Review and approve this architecture
2. Start with Module 1 (Authentication)
3. Implement core data models
4. Build screens module by module
5. Integrate with backend API
6. Conduct thorough testing

---

**Note:** This is a living document. Update it as requirements change and new modules are completed.

