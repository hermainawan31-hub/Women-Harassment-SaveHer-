#  SafeHer

### Empowering Women Through Smart Emergency Response Technology

<div align="center">

A comprehensive women safety application built with **Flutter** and **Firebase** that provides real-time emergency assistance through SOS alerts, live location sharing, emergency contact notifications, and audio evidence recording.

**Designed to provide help when every second matters.**

<br>

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge\&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge\&logo=firebase)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge\&logo=dart)
![Android](https://img.shields.io/badge/Android-Supported-3DDC84?style=for-the-badge\&logo=android)
![MIT](https://img.shields.io/badge/License-MIT-success?style=for-the-badge)

<br>

 Star this repository if you find it useful

</div>

---

#  Table of Contents

* About The Project
* Problem Statement
* Project Objectives
* Key Features
* Application Workflow
* Technology Stack
* System Architecture
* Database Design
* Installation
* Firebase Configuration
* Screenshots
* Testing
* Challenges Faced
* Future Enhancements
* Contributing
* License
* Developer
* Acknowledgements

---
# About The Project

SafeHer is a mobile safety solution developed to assist women during emergency situations.

The application combines modern mobile technologies with cloud-based services to provide immediate emergency response mechanisms. By automating critical actions such as location sharing, contact notification, and evidence recording, SafeHer reduces the time required to seek assistance during dangerous situations.

The project focuses on reliability, simplicity, and rapid response.

---

#  Problem Statement

In emergency situations, users often struggle to:

* Contact multiple people quickly
* Explain their location accurately
* Record evidence of incidents
* Access assistance immediately

Traditional communication methods can become difficult during stressful moments.

SafeHer solves these challenges by automating emergency response actions through a single SOS trigger.

---

#  Project Objectives

* Improve personal safety.
* Provide instant emergency assistance.
* Reduce response time during emergencies.
* Share live location with trusted contacts.
* Record emergency evidence automatically.
* Maintain emergency history records.
* Provide secure cloud-based storage.

---

# Key Features
## 🆘 Smart SOS Activation

A single button triggers the complete emergency workflow.

### Automatic Actions

* Capture GPS Coordinates
* Generate Maps Link
* Start Audio Recording
* Save Emergency Event
* Notify Trusted Contacts

---

## 📍 Live Location Tracking

Real-time location monitoring allows emergency contacts to know the user's exact position.

---

## 🎙️ Emergency Audio Recording

The application automatically records surrounding audio during emergency events and stores it securely.

---

## 👥 Emergency Contact Management

Users can:

* Add Contacts
* Edit Contacts
* Delete Contacts
* Manage Trusted Individuals

---

## 🔐 Secure Authentication

Firebase Authentication provides:

* Secure Login
* User Registration
* Session Management

---

## ☁️ Cloud Storage Integration

Emergency information is securely stored using:

* Cloud Firestore
* Firebase Storage

---

#  Application Workflow

```text
User Activates SOS
        │
        ▼
 Capture Current Location
        │
        ▼
 Create Emergency Event
        │
        ▼
 Start Audio Recording
        │
        ▼
 Generate Maps Link
        │
        ▼
 Notify Emergency Contacts
        │
        ▼
 Store Event In Firebase
```

---

# 🛠 Technology Stack

| Layer          | Technology                  |
| -------------- | --------------------------- |
| Framework      | Flutter                     |
| Language       | Dart                        |
| Backend        | Firebase                    |
| Database       | Cloud Firestore             |
| Storage        | Firebase Storage            |
| Authentication | Firebase Auth               |
| Maps           | OpenStreetMap               |
| Location       | Geolocator                  |
| Notifications  | Flutter Local Notifications |

---

# System Architecture

```text
Flutter Application
        │
        ├── Authentication Module
        ├── SOS Module
        ├── Contact Management
        ├── Recording Module
        └── Location Services

                │

                ▼

            Firebase

        ├── Authentication
        ├── Firestore
        └── Storage
```

---

#  Database Design

### Users Collection

Stores:

* User Information
* Medical Details
* Safety Profile

### Emergency Contacts Collection

Stores:

* Contact Name
* Phone Number
* Relationship

### SOS Events Collection

Stores:

* Timestamp
* Location
* Recording URL
* Emergency Status

---

#  Installation

```bash
git clone https://github.com/your-username/SafeHer.git

cd SafeHer

flutter pub get

flutter run
```

---

#  Firebase Configuration

1. Create Firebase Project
2. Enable Authentication
3. Enable Firestore
4. Enable Storage
5. Add Firebase Configuration Files
6. Run:

```bash
flutterfire configure
```

---

#  Screenshots

Add screenshots inside:

```text
documentation/screenshots/
```

Recommended Screens:

* Login Screen
* Home Screen
* SOS Screen
* Emergency Contacts
* Live Location
* Profile Screen

---

#  Testing

The application has been tested for:

| Test                  | Status |
| --------------------- | ------ |
| Registration          | ✅      |
| Login                 | ✅      |
| GPS Tracking          | ✅      |
| SOS Activation        | ✅      |
| Audio Recording       | ✅      |
| Firestore Integration | ✅      |
| Firebase Storage      | ✅      |

---

# Challenges Faced

### Location Tracking

Maintaining accurate location updates while reducing battery usage.

### Firebase Integration

Managing Authentication, Firestore, and Storage efficiently.

### Emergency Workflow

Synchronizing multiple emergency actions simultaneously.

### Audio Recording

Handling recording permissions and storage management.

---

# Future Enhancements

* Volume Button SOS Trigger
* Lock Screen Activation
* Voice-Based SOS
* Smart Watch Support
* AI Threat Detection
* Offline Emergency Alerts
* Multi-Language Support
* Family Monitoring Dashboard

---
# Contributing

Contributions are welcome.

1. Fork Repository
2. Create Feature Branch
3. Commit Changes
4. Push Changes
5. Open Pull Request

---

#  License

Distributed under the MIT License.

See LICENSE for more information.

---

# Developer

### Uzair Ali,Aqeel Khaliq,Hermain Shoukat

BS Software Engineering

Flutter Developer | Mobile Application Enthusiast

GitHub: https:https://github.com/uzair762

LinkedIn: https://www.linkedin.com/in/uzair-ali-3905463a0/
          https://www.linkedin.com/in/hermain-awan-413781326/
          https://www.linkedin.com/in/aqeel-khaliq-385a25382/

---

#  Acknowledgements

Special thanks to:

* Flutter Team
* Firebase Team
* OpenStreetMap Community
* Open Source Contributors
* COMSATS University Abbottabad

---

<div align="center">

##  SafeHer

### Because Safety Should Never Depend On How Fast You Can Ask For Help.

</div>
