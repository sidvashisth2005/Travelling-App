# Travel App

A modern Flutter travel application for exploring places, viewing details, searching for hotels, chatting with AI, and navigating with beautiful map integration. Built with Firebase authentication, dynamic API config, TripAdvisor and OpenStreetMap APIs, Hugging Face AI chatbot, and a sleek Material 3 dark theme.

---

## 🚀 Project Overview
This app lets users:
- Search and explore cities and points of interest (POIs)
- View detailed information about places, including images, descriptions, addresses, and nearby landmarks
- See places and hotels on interactive maps
- Get directions to any place or hotel using Google Maps
- Register and log in securely with Firebase Auth
- Chat with an AI assistant (Hugging Face Inference API)

---

## ✨ Features

### 1. **Authentication**
- Secure login and registration using Firebase Auth

### 2. **Explore Places**
- Search for cities and view top places/POIs (TripAdvisor API)
- See popular Indian destinations
- Modern, card-based UI with images and descriptions

### 3. **Place Details**
- Tap a place to view:
  - Large image, name, description, and address
  - **Nearby Landmark:**
    - Fetched via OpenStreetMap/Nominatim reverse geocoding
    - Clickable: opens Google Maps for the landmark location
  - **SEE ON MAPS:**
    - Opens an embedded OpenStreetMap (OSM) view with a marker
    - **Get Directions** button: opens Google Maps for navigation

### 4. **Hotels**
- Search for hotels in a city (TripAdvisor API, with OSM fallback)
- See hotels on a map, with images and address
- "Nearby Landmark" for hotels (via OSM)

### 5. **AI Chatbot**
- Chat with an AI assistant powered by Hugging Face Inference API
- Model and API key are fetched dynamically from Firebase
- Copy-to-clipboard: Long-press any chat message to copy
- Robust error handling for API/network issues

### 6. **Modern UI/UX**
- Material 3, dark theme, purple primary color, rounded cards and buttons
- Smooth transitions and consistent padding

---

## 🗂️ Folder Structure
```
lib/
  main.dart                # App entry point and theme
  screens/                 # All UI screens (home, details, hotels, chatbot, etc.)
  services/                # API and data services (places, hotels, auth, ai_chat)
  widgets/                 # Reusable UI components
  models/                  # Data models (Place, Hotel, etc.)
```

---

## ⚙️ Setup & Running

1. **Clone the repository:**
   ```bash
   git clone https://github.com/sidvashisth2005/Travelling-App.git
   cd travel_app
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Set up Firebase:**
   - Add your Firebase config files for Android/iOS if using authentication
   - In Firestore, create a `config` collection and an `api_keys` document with these fields:
     - `travel_advisor_api_key`: Your TripAdvisor RapidAPI key
     - `travel_advisor_host`: `travel-advisor.p.rapidapi.com`
     - `travel_advisor_base_url`: `https://travel-advisor.p.rapidapi.com`
     - `huggingface_api_key`: Your Hugging Face Inference API key (with Inference permission)
     - `huggingface_model_url`: e.g. `https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium`

4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 🔑 API Keys & Dynamic Config
- **All API keys, hosts, and model URLs are stored in Firebase Firestore** under `config/api_keys`.
- The app fetches these at startup, so you can update keys or endpoints without redeploying.
- **TripAdvisor RapidAPI:** Used for places and hotels data
- **OpenStreetMap Nominatim:** Used for reverse geocoding and landmarks (no key required)
- **Hugging Face Inference API:** Used for AI chatbot (key and model URL from Firestore)
- **Firebase:** Used for authentication and config storage

---

## 🗺️ Map & Geocoding
- **Maps:** Uses [flutter_map](https://pub.dev/packages/flutter_map) for embedded OpenStreetMap views (no key required)
- **Directions:** Uses [url_launcher](https://pub.dev/packages/url_launcher) to open Google Maps for navigation
- **Landmarks:** Uses Nominatim reverse geocoding to find and display nearby famous places

---

## 🤖 AI Chatbot
- Powered by Hugging Face Inference API (e.g., DialoGPT, Blenderbot)
- Model and API key are fetched from Firestore
- Copy-to-clipboard: Long-press any chat message to copy
- Handles API/network errors gracefully

---

## 🛠️ Dependencies
- [flutter_map](https://pub.dev/packages/flutter_map)
- [latlong2](https://pub.dev/packages/latlong2)
- [url_launcher](https://pub.dev/packages/url_launcher)
- [http](https://pub.dev/packages/http)
- [firebase_core](https://pub.dev/packages/firebase_core), [firebase_auth](https://pub.dev/packages/firebase_auth)
- [cloud_firestore](https://pub.dev/packages/cloud_firestore)

---

## 📝 Contributing
- Pull requests are welcome!
- Please open an issue for feature requests or bugs
- Follow best practices for Flutter and Dart

---

## 🧰 Troubleshooting
- **API errors:** Check your API keys and network connection
- **Map not loading:** Ensure you have internet access and the correct dependencies
- **Firebase issues:** Make sure your config files and Firestore rules are correct
- **Rate limits:** Nominatim and TripAdvisor APIs have rate limits; use responsibly
- **Firestore permissions:**
  - For development, use:
    ```
    service cloud.firestore {
      match /databases/{database}/documents {
        match /config/api_keys {
          allow read: if true;
          allow write: if false;
        }
      }
    }
    ```
  - For production, restrict read access as needed

---

## 📸 Screenshots
*Screenshots here to showcase the UI and features!*

---

## 📄 License
*All rights reserved.*

---

## 📬 Contact
- Project maintained by: *Siddhant Vashisth*
- For questions, open an issue or contact: *siddhantvashisth05@email.com*
