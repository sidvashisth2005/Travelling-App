import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'hotels_screen.dart';
import 'account_screen.dart';
import 'chatbot_screen.dart';
import '../models/place.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_trips_service.dart';
import '../services/user_profile_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  Set<String> _wishlist = {};
  List<Place> _scheduledTrips = [];
  final Map<String, Place> _allPlaces = {};
  bool _loadingWishlist = true;
  bool _loadingScheduled = true;

  String _displayName = 'Traveler';
  String? _photoURL;

  bool _isWishlistActionInProgress = false;
  bool _isScheduleActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadWishlistFromFirestore();
    _loadScheduledFromFirestore();
    _loadProfileFromFirestore();
  }

  Future<void> _loadWishlistFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loadingWishlist = true);
    final trips = await UserTripsService.getUserTrips(user.uid);
    final wishlist = (trips['wishlist'] as List)
        .map((m) => UserTripsService.mapToPlace(m as Map<String, dynamic>))
        .toList();
    for (final p in wishlist) {
      _allPlaces[p.name] = p;
    }
    setState(() {
      _wishlist = wishlist.map((p) => p.name).toSet();
      _loadingWishlist = false;
    });
  }

  Future<void> _loadScheduledFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loadingScheduled = true);
    final trips = await UserTripsService.getUserTrips(user.uid);
    final scheduled = (trips['scheduled'] as List)
        .map((m) => UserTripsService.mapToPlace(m as Map<String, dynamic>))
        .toList();
    for (final p in scheduled) {
      _allPlaces[p.name] = p;
    }
    setState(() {
      _scheduledTrips = scheduled;
      _loadingScheduled = false;
    });
  }

  Future<void> _loadProfileFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final data = await UserProfileService.getUserProfile(user.uid);
    setState(() {
      _displayName = data?['name'] ?? user.displayName ?? 'Traveler';
      _photoURL = data?['photoURL'] ?? user.photoURL;
    });
  }

  Future<void> _saveWishlistToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final wishlistMaps = _wishlist.map((name) => _allPlaces[name]).whereType<Place>().map(UserTripsService.placeToMap).toList();
    await UserTripsService.updateWishlist(user.uid, wishlistMaps);
  }

  Future<void> _saveScheduledToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final scheduledMaps = _scheduledTrips.map(UserTripsService.placeToMap).toList();
    await UserTripsService.updateScheduled(user.uid, scheduledMaps);
  }

  void _onWishlistChanged(String placeName, bool add) async {
    if (_isWishlistActionInProgress) return;
    if (add && _wishlist.contains(placeName)) {
      // Already in wishlist
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.red),
                const SizedBox(width: 8),
                const Text('Already in your wishlist!'),
              ],
            ),
            backgroundColor: Colors.grey[900],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 6,
          ),
        );
      }
      return;
    }
    _isWishlistActionInProgress = true;
    setState(() {
      if (add) {
        _wishlist.add(placeName);
      } else {
        _wishlist.remove(placeName);
      }
    });
    try {
      await _saveWishlistToFirestore();
    } catch (e) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                const Text('Failed to update wishlist. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red[900],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 6,
          ),
        );
      }
    }
    _isWishlistActionInProgress = false;
  }

  void _onScheduleTrip(Place place) async {
    if (_isScheduleActionInProgress) return;
    if (_scheduledTrips.any((p) => p.name == place.name)) {
      // Already scheduled
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Trip already scheduled!'),
              ],
            ),
            backgroundColor: Colors.grey[900],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 6,
          ),
        );
      }
      return;
    }
    _isScheduleActionInProgress = true;
    setState(() {
      _scheduledTrips.add(place);
    });
    try {
      await _saveScheduledToFirestore();
    } catch (e) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Failed to schedule trip. Please try again.'),
              ],
            ),
            backgroundColor: Colors.orange[900],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 6,
          ),
        );
      }
    }
    _isScheduleActionInProgress = false;
  }

  void _onRemoveScheduledTrip(String name) {
    setState(() {
      _scheduledTrips.removeWhere((p) => p.name == name);
    });
    _saveScheduledToFirestore();
  }

  void _registerPlaces(List<Place> places) {
    for (final p in places) {
      _allPlaces[p.name] = p;
    }
  }

  Future<void> _reloadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    await _loadProfileFromFirestore();
  }

  List<Widget> get _pages => [
    HomeScreen(
      key: ValueKey(_wishlist.hashCode ^ _scheduledTrips.length),
      wishlist: _wishlist,
      scheduledTrips: _scheduledTrips,
      onWishlistChanged: (name, add) {
        final place = _allPlaces[name];
        if (place != null) {
          _onWishlistChanged(name, add);
        }
      },
      onScheduleTrip: _onScheduleTrip,
      registerPlaces: _registerPlaces,
      displayName: _displayName,
    ),
    HotelsScreen(),
    ChatbotScreen(),
    AccountScreen(
      wishlist: _wishlist.map((name) => _allPlaces[name]).whereType<Place>().toList(),
      scheduledTrips: _scheduledTrips,
      onRemoveFromWishlist: (name) => _onWishlistChanged(name, false),
      onRemoveScheduledTrip: _onRemoveScheduledTrip,
      onScheduleTrip: _onScheduleTrip,
      onProfileUpdated: _reloadUserProfile,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingWishlist || _loadingScheduled) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1F1F1F),
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
            NavigationDestination(icon: Icon(Icons.hotel_outlined), selectedIcon: Icon(Icons.hotel), label: 'Hotels'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chatbot'),
            NavigationDestination(icon: Icon(Icons.account_circle_outlined), selectedIcon: Icon(Icons.account_circle), label: 'Account'),
          ],
        ),
      ),
    );
  }
}

// Add a global navigatorKey for SnackBar context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();