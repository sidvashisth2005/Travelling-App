# Travel App

A modern Flutter travel application for exploring places, viewing details, searching for hotels, and navigating with beautiful map integration. Built with Firebase authentication, TripAdvisor and OpenStreetMap APIs, and a sleek Material 3 dark theme.

---

## 🚀 Project Overview
This app lets users:
- Search and explore cities and points of interest (POIs)
- View detailed information about places, including images, descriptions, addresses, and nearby landmarks
- See places and hotels on interactive maps
- Get directions to any place or hotel using Google Maps
- Register and log in securely with Firebase Auth

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
- Search for hotels in a city (TripAdvisor API)
- (Planned) Show hotels on a map, supplement with OSM data, and add "Nearby Landmark" for hotels

### 5. **Modern UI/UX**
- Material 3, dark theme, purple primary color, rounded cards and buttons
- Smooth transitions and consistent padding

---

## 🗂️ Folder Structure
```
lib/
  main.dart                # App entry point and theme
  screens/                 # All UI screens (home, details, hotels, account, etc.)
  services/                # API and data services (places, hotels, auth)
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
3. **Run the app:**
   ```bash
   flutter run
   ```

---

## 🔑 API Keys & Environment Variables
- **TripAdvisor RapidAPI:**
  - Used for places and hotels data
  - Get your API key from [RapidAPI]
  - Add your key in `lib/services/places_service.dart` and `lib/services/hotel_service.dart`
- **OpenStreetMap Nominatim:**
  - Used for reverse geocoding and landmarks
  - No API key required (free usage, but respect rate limits)
- **Firebase:**
  - Add your Firebase config files for Android/iOS if using authentication

---

## 🗺️ Map & Geocoding
- **Maps:** Uses [flutter_map](https://pub.dev/packages/flutter_map) for embedded OpenStreetMap views (no key required)
- **Directions:** Uses [url_launcher](https://pub.dev/packages/url_launcher) to open Google Maps for navigation
- **Landmarks:** Uses Nominatim reverse geocoding to find and display nearby famous places

---

## 🛠️ Dependencies
- [flutter_map](https://pub.dev/packages/flutter_map)
- [latlong2](https://pub.dev/packages/latlong2)
- [url_launcher](https://pub.dev/packages/url_launcher)
- [http](https://pub.dev/packages/http)
- [firebase_core](https://pub.dev/packages/firebase_core), [firebase_auth](https://pub.dev/packages/firebase_auth)

---

## 📝 Contributing
- Pull requests are welcome!
- Please open an issue for feature requests or bugs
- Follow best practices for Flutter and Dart

---

## 🧰 Troubleshooting
- **API errors:** Check your API keys and network connection
- **Map not loading:** Ensure you have internet access and the correct dependencies
- **Firebase issues:** Make sure your config files are present and correct
- **Rate limits:** Nominatim and TripAdvisor APIs have rate limits; use responsibly

---

## 📸 Screenshots
*Screenshots here to showcase the UI and features!*

---

## 📄 License
*All license reserved.

---

## 📬 Contact
- Project maintained by: *Your Name or Organization*
- For questions, open an issue or contact: *your@email.com*
