import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/places_service.dart';
import 'services/hotel_service.dart';
import 'screens/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/ai_chat_service.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load();
  await Firebase.initializeApp();
  final doc = await FirebaseFirestore.instance.collection('config').doc('api_keys').get();
  final apiKey = doc['travel_advisor_api_key'] as String?;
  final hfApiKey = doc['huggingface_api_key'] as String?;
  final hfModelUrl = doc['huggingface_model_url'] as String?;
  final travelAdvisorHost = doc['travel_advisor_host'] as String?;
  final travelAdvisorBaseUrl = doc['travel_advisor_base_url'] as String?;
  if (apiKey != null && apiKey.isNotEmpty) {
    PlacesService.setApiKey(apiKey);
    HotelService.setApiKey(apiKey);
  }
  if (hfApiKey != null && hfApiKey.isNotEmpty) {
    AIChatService.setApiKey(hfApiKey);
  }
  if (hfModelUrl != null && hfModelUrl.isNotEmpty) {
    AIChatService.setModelUrl(hfModelUrl);
  }
  // Optionally, set host/baseUrl for other services if you add setters
  runApp(const TravelApp());
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel App',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A1B9A),
          brightness: Brightness.dark,
          primary: const Color(0xFF8E44AD),
          tertiary: const Color(0xFFF39C12), // Accent color
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E44AD),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1F1F1F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIconColor: Colors.white54,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 28, color: Colors.white),
          headlineSmall: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return const MainPage();
    } else {
      return const LoginScreen();
    }
  }
}