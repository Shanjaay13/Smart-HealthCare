# Smart HealthCare 🩺✨

**Smart HealthCare** is a futuristic reimagining of a national health superapp. Built with **Flutter**, it moves beyond simple tracking to become a proactive, **AI-powered dedicated health companion** for every individual.

---

## Vision
To create a seamless, intelligent, and human-centric health platform that anticipates needs rather than just reacting to them. Smart HealthCare combines **Generative AI**, **Hyper-local Data**, and **Gamification** to make managing health engaging and effortless.

---

## Key Features

### 1. Cortex: The AI Health Architect
At the heart of Smart HealthCare is **Cortex**, an advanced NLU (Natural Language Understanding) driven assistant. It doesn't just answer questions; it **takes action**.

#### **Capabilities:**
*   **One-Shot Appointment Booking**:
    *   *User:* "Book a dental appointment at Nusa Bestari for tomorrow at 2 PM."
    *   *AI:* Instantly parses "Dental", "Nusa Bestari", and "Tomorrow 2 PM", skipping manual tap steps.
*   **Smart Medication Assistant**:
    *   *User:* "Remind me to take my Panadol every day at 9 AM."
    *   *AI:* Adds the schedule to your Medication Tracker and sets up push notifications.
*   **SOS Emergency Mode**:
    *   *Trigger:* Say **"Emergency"**, **"Chest pain"**, or **"Help"**.
    *   *Action:* The interface shifts to **Red Alert Mode**.
    *   *Features:* One-tap **999 Call**, instant **Hospital Navigation** (via Google Maps), and Medical ID display.

### 2. Quantum Health Dashboard
A visually stunning, modern command center for your health data.
*   **Smart Health Score**: An algorithm that calculates a daily score based on your BMI, sleep patterns, and step count.
*   **Visual Calorie Tracker**: Snap a photo of your food and let the AI automatically detect the meal and estimate the calories/macros.
*   **Gamification**: Earn XP and level up for logging health data, checking in, or completing quests.

### 3. Infectious Disease Tracker (Hotspots)
Real-time, hyper-local risk assessment.
*   **Dynamic Heatmaps**: Visualizes active clusters of Dengue, COVID-19, and Influenza on an interactive map.
*   **Proximity Radar**: Runs in the background (simulated) to warn you if you enter a "Red Zone".

### 4. Digital Health ID
Your medical identity, modernized.
*   **Vaccination Passports**: View, add, update, and manage verified vaccine certificates.
*   **Secure Authentication**: Features enterprise-grade authentication with deep-linking magic to securely log users into their verified digital vault.

### 5. Secure Cloud Synchronization
*   **Real-time Database**: Profiles, medications, and chat history are securely synchronized across devices using a real-time cloud backend.

---

## Technical Architecture

### **Tech Stack**
*   **Framework**: Flutter 3.x (Dart)
*   **State Management**: Riverpod (for reactive, scalable state)
*   **Backend as a Service**: Supabase (PostgreSQL, Auth, Edge Functions)
*   **AI Engine**: Custom NLU Logic + Groq API integration (Powered by LLaMA 3 for Chat and LLaMA Vision for Visual Calorie Tracking)
*   **Services**:
    *   `supabase_flutter`: Secure authentication and database queries.
    *   `geolocator`: GPS & Location services.
    *   `flutter_map` & `latlong2`: OpenStreetMaps integration.

### **Design System**
*   **Aesthetics**: Minimalist, Soft Drop-Shadows, and Modern Clean UI.
*   **Animations**: `flutter_animate` for smooth, cinematic transitions.
*   **Typography**: Google Fonts (Outfit / Inter) for a clean, modern look.

---

## Downloads & Installation

> **Note:** This app is not yet available on the Play Store. You must install it manually.

### **Android (APK)**
1.  Download the **`app-release.apk`** file from this repository.
2.  Open the file on your Android phone.
3.  Allow "Install from Unknown Sources" if prompted.

---

## Installation Guide (For Developers)

1.  **Prerequisites**:
    *   Flutter SDK installed (v3.0+)
    *   Dart SDK
    *   Android Studio / VS Code

2.  **Clone the Repo**:
    ```bash
    git clone https://github.com/Shanjaay13/Smart-HealthCare.git
    cd Smart-HealthCare
    ```

3.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

4.  **Configuration (Optional)**:
    *   Create a `.env` file in the root directory.
    *   Add your Supabase and Groq API credentials:
        ```env
        SUPABASE_URL=your_project_url
        SUPABASE_ANON_KEY=your_anon_key
        GROQ_API_KEY=your_key_here
        ```

5.  **Run the App**:
    ```bash
    flutter run
    ```

---
*Smart HealthCare — Empowering your health journey, one pulse at a time.*
