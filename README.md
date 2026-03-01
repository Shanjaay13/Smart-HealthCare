# MySejahtera Next Gen (MySJ) 🇲🇾✨

**MySejahtera Next Gen** is a futuristic reimagining of Malaysia's national health superapp. Built with **Flutter**, it moves beyond simple contact tracing to become a proactive, **AI-powered dedicated health companion** for every citizen.

---

## Vision
To create a seamless, intelligent, and human-centric health platform that anticipates needs rather than just reacting to them. MySNG combines **Generative AI**, **Hyper-local Data**, and **Gamification** to make managing health engaging and effortless.

---

## Key Features

### 1. Cortex: The AI Health Architect
At the heart of MySNG is **Cortex**, an advanced NLU (Natural Language Understanding) driven assistant. It doesn't just answer questions; it **takes action**.

#### **Capabilities:**
*   **One-Shot Appointment Booking**:
    *   *User:* "Book a dental appointment at Nusa Bestari for tomorrow at 2 PM."
    *   *AI:* Instantly parses "Dental", "Nusa Bestari", and "Tomorrow 2 PM", skipping 5+ manual tap steps.
*   **Smart Medication Assistant**:
    *   *User:* "Remind me to take my Panadol every day at 9 AM."
    *   *AI:* Adds the schedule to your Medication Tracker and sets up push notifications.
    *   *User:* "Did I take my meds today?"
    *   *AI:* Checks your daily log and reports status.
*   **SOS Emergency Mode**:
    *   *Trigger:* Say **"Emergency"**, **"Chest pain"**, or **"Help"**.
    *   *Action:* The interface shifts to **Red Alert Mode**.
    *   *Features:* One-tap **999 Call**, instant **Hospital Navigation** (via Google Maps), and Medical ID display.
*   **Contextual Awareness**:
    *   Understands "nearby" to trigger GPS.
    *   Handles cancellations smoothly ("Actually, cancel that").

### 2. Quantum Health Dashboard
A visually stunning, glassmorphic command center for your health data.
*   **MySejahtera Health Score**: A proprietary algorithm that calculates a daily score (0-100) based on your BMI, sleep patterns, and step count.
*   **Visual Calorie Tracker**: Snap a photo of your food and let the AI automatically detect the meal and estimate the calories/macros (powered by LLaMA Vision).
*   **Gamification**:
    *   **XP & Levels**: Earn XP for logging health data, checking in, or completing quizzes.
    *   **Badges**: Unlock achievements like "Early Bird" (Morning check-ins) or "Marathoner" (10k steps).

### 3. Infectious Disease Tracker (Hotspots)
Real-time, hyper-local risk assessment.
*   **Dynamic Heatmaps**: Visualizes active clusters of Dengue, COVID-19, and Influenza on an interactive map.
*   **Proximity Radar**: Runs in the background (simulated) to warn you if you enter a "Red Zone".
*   **Premise Check-In**: A fast, precise QR scanner for contact tracing.

### 4. Digital Health ID
Your medical identity, modernized.
*   **Vaccination Passports**: View, add, update, and manage verified vaccine certificates.
*   **Secure Authentication**: Features enterprise-grade Email Verification with deep-linking magic (Universal App Links) to securely log users into their verified digital vault.

### 5. Secure Cloud Synchronization
*   **Real-time Database**: Profiles, medications, and chat history are securely synchronized across devices using a real-time cloud backend.
*   **Gamified Progress**: Your XP, levels, and daily quests are securely tracked globally.

---

##  How to Use

### **AI Chat (Cortex)**
1.  Tap the **"Ask AI"** floating button or the bottom navigation bar.
2.  **Type or Speak** your request.
    *   *Try:* "I have a fever and headache." (Triage)
    *   *Try:* "Where can I get a booster shot nearby?" (Locator)
3.  **Booking Flow**:
    *   The AI will ask clarifying questions if details are missing (e.g., "Which clinic?").
    *   Confirm your details and receive a digital appointment ticket.

### **Medication Tracker**
1.  Go to **Digital Health** -> **Medication**.
2.  Tap **+ Add Medication** or ask the AI to do it.
3.  Mark meds as "Taken" to maintain your streak and earn Health XP.

### **Hotspot Tracking**
1.  Navigate to the **Hotspot** tab.
2.  View your current location's risk level (Low/Medium/High).
3.  Check the heatmap radius to safe-plan your travel.

---

## Technical Architecture

### **Tech Stack**
*   **Framework**: Flutter 3.x (Dart)
*   **State Management**: Riverpod (for reactive, scalable state)
*   **Backend as a Service**: Supabase (PostgreSQL, Auth, Edge Functions)
*   **AI Engine**: Custom NLU Logic + Groq API integration (Powered by LLaMA 3 for Chat and LLaMA Vision / LLaMA 4 for Visual Calorie Tracking)
*   **Services**:
    *   `supabase_flutter`: Secure authentication, email verification, and real-time database queries.
    *   `app_links`: Universal mobile deep linking for seamless authentication redirects.
    *   `geolocator`: GPS & Location services.
    *   `flutter_map` & `latlong2`: OpenStreetMaps integration.
    *   `shared_preferences`: Local settings storage.
    *   `url_launcher`: External calls and navigation.

### **Design System**
*   **Aesthetics**: Glassmorphism, Neumorphism, and Holographic UI.
*   **Animations**: `flutter_animate` for smooth, cinematic transitions.
*   **Typography**: Google Fonts (Outfit / Inter) for a clean, modern look.

---

## Downloads & Installation

> **Note:** This app is not yet available on the App Store or Play Store. You must install it manually.

### **Android (APK)**
1.  Download the **`app-release.apk`** file from this repository (or the Releases tab).
2.  Open the file on your Android phone.
3.  Allow "Install from Unknown Sources" if prompted.

### **iOS (IPA) - Unsigned**
>  **Important:** The IPA file is **unsigned** (due to Apple restrictions). You cannot install it directly.

**How to Install:**
1.  Download the **`ios_app.ipa`** file.
2.  Use a sideloading tool on your PC/Mac:
    *   **[AltStore](https://altstore.io/)**: (Recommended) Free, requires refreshing every 7 days.
    *   **[Sideloadly](https://sideloadly.io/)**: Drag & drop installation.
    *   **Signulous**: Paid service (no computer needed).
3.  Once installed, go to **Settings -> General -> VPN & Device Management** on your iPhone and "Trust" your Apple ID to open the app.

---

## Installation Guide

1.  **Prerequisites**:
    *   Flutter SDK installed (v3.0+)
    *   Dart SDK
    *   Android Studio / VS Code

2.  **Clone the Repo**:
    ```bash
    git clone https://github.com/yourusername/my_sejahtera_ng.git
    cd my_sejahtera_ng
    ```

3.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

4.  **Configuration (Optional)**:
    *   Create a `.env` file in the root directory.
    *   Add your Supabase credentials to enable the live backend:
        ```env
        SUPABASE_URL=your_project_url
        SUPABASE_ANON_KEY=your_anon_key
        ```
    *   Add `GROQ_API_KEY=your_key_here` to enable the real LLM backend.

5.  **Run the App**:
    ```bash
    flutter run
    ```

---

## Roadmap
*   [ ] integration with WearOS / Apple Watch.
*   [ ] Blockchain-based medical record storage.

---
*MySejahtera Next Gen — Empowering Malaysia, One Pulse at a Time.*
