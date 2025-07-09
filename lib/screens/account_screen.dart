import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../widgets/animated_fade_slide.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/place.dart';
import 'place_details_screen.dart';
import '../services/user_trips_service.dart';
import '../services/user_profile_service.dart';
import 'package:shimmer/shimmer.dart';

class AccountScreen extends StatefulWidget {
  final List<Place> wishlist;
  final List<Place> scheduledTrips;
  final void Function(String) onRemoveFromWishlist;
  final void Function(String) onRemoveScheduledTrip;
  final void Function(Place) onScheduleTrip;
  final VoidCallback onProfileUpdated;
  const AccountScreen({
    super.key,
    required this.wishlist,
    required this.scheduledTrips,
    required this.onRemoveFromWishlist,
    required this.onRemoveScheduledTrip,
    required this.onScheduleTrip,
    required this.onProfileUpdated,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Remove local scheduledTrips list to avoid shadowing the parent
  // List<Place> scheduledTrips = [];
  List<_CompletedTrip> completedTrips = [];
  bool showScheduled = false;
  bool showCompleted = false;
  bool _loadingTrips = true;
  String? _profileName;
  String? _profileEmail;
  String? _profilePhotoURL;
  String _scheduledSort = 'date_desc';
  String _completedSort = 'date_desc';
  Map<String, DateTime> _scheduledDates = {};

  @override
  void initState() {
    super.initState();
    _loadTripsFromFirestore();
    _loadProfileFromFirestore();
  }

  Future<void> _loadTripsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loadingTrips = true);
    final trips = await UserTripsService.getUserTrips(user.uid);
    setState(() {
      // scheduledTrips now comes from widget.scheduledTrips (parent)
      completedTrips = (trips['completed'] as List)
          .map((m) => _CompletedTrip(
                place: UserTripsService.mapToPlace(m as Map<String, dynamic>),
                date: m['completedDate'] != null ? DateTime.parse(m['completedDate']) : DateTime.now(),
              ))
          .toList();
      // Load scheduled dates
      _scheduledDates = {};
      for (final m in (trips['scheduled'] as List)) {
        if (m['scheduledDate'] != null && m['name'] != null) {
          _scheduledDates[m['name']] = DateTime.tryParse(m['scheduledDate']) ?? DateTime.now();
        }
      }
      _loadingTrips = false;
    });
  }

  Future<void> _loadProfileFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final data = await UserProfileService.getUserProfile(user.uid);
    setState(() {
      _profileName = data?['name'] ?? user.displayName ?? 'User';
      _profileEmail = data?['email'] ?? user.email ?? '';
      _profilePhotoURL = data?['photoURL'] ?? user.photoURL;
    });
  }

  Future<void> _saveWishlistToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final wishlistMaps = widget.wishlist.map(UserTripsService.placeToMap).toList();
    await UserTripsService.updateWishlist(user.uid, wishlistMaps);
  }

  Future<void> _saveScheduledToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final scheduledMaps = widget.scheduledTrips.map((place) {
      final map = UserTripsService.placeToMap(place);
      if (_scheduledDates[place.name] != null) {
        map['scheduledDate'] = _scheduledDates[place.name]!.toIso8601String();
      }
      return map;
    }).toList();
    await UserTripsService.updateScheduled(user.uid, scheduledMaps);
  }

  Future<void> _saveCompletedToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final completedMaps = completedTrips
        .map((t) => {
              ...UserTripsService.placeToMap(t.place),
              'completedDate': t.date.toIso8601String(),
            })
        .toList();
    await UserTripsService.updateCompleted(user.uid, completedMaps);
  }

  void _scheduleTrip(Place place) {
    if (!widget.scheduledTrips.any((p) => p.name == place.name)) {
      widget.onScheduleTrip(place);
      // No local setState for scheduledTrips, rely on parent update
      _saveScheduledToFirestore();
      setState(() {}); // Refresh UI
    }
  }

  void _addToCompleted(Place place) {
    setState(() {
      // Remove from scheduled trips
      widget.onRemoveScheduledTrip(place.name);
      // Add to completed if not already present
      if (!completedTrips.any((t) => t.place.name == place.name)) {
        completedTrips.add(_CompletedTrip(place: place, date: DateTime.now()));
      }
    });
    _saveScheduledToFirestore();
    _saveCompletedToFirestore();
    // Show congratulatory SnackBar
    final congrats = [
      'Congratulations!',
      'Well done!',
      'Awesome job!',
      'Trip completed!',
      'You did it!',
      'Adventure complete!'
    ]..shuffle();
    final context = this.context;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.amber),
              const SizedBox(width: 8),
              Text(congrats.first, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
  }

  void _removeFromCompleted(_CompletedTrip trip) {
    setState(() {
      completedTrips.remove(trip);
    });
    _saveCompletedToFirestore();
  }

  void _removeFromWishlist(String name) {
    widget.onRemoveFromWishlist(name);
    _saveWishlistToFirestore();
  }

  Future<void> _pickScheduledDate(Place place) async {
    final initialDate = _scheduledDates[place.name] ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _scheduledDates[place.name] = picked;
      });
      _saveScheduledToFirestore();
    }
  }

  // Helper methods for sorting
  List<Place> _getSortedScheduledTrips() {
    final trips = List<Place>.from(widget.scheduledTrips);
    switch (_scheduledSort) {
      case 'name_asc':
        trips.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        trips.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'date_asc':
        // No date field, so fallback to name
        trips.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'date_desc':
      default:
        // No date field, so fallback to name
        trips.sort((a, b) => b.name.compareTo(a.name));
        break;
    }
    return trips;
  }

  List<_CompletedTrip> _getSortedCompletedTrips() {
    final trips = List<_CompletedTrip>.from(completedTrips);
    switch (_completedSort) {
      case 'name_asc':
        trips.sort((a, b) => a.place.name.compareTo(b.place.name));
        break;
      case 'name_desc':
        trips.sort((a, b) => b.place.name.compareTo(a.place.name));
        break;
      case 'date_asc':
        trips.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'date_desc':
      default:
        trips.sort((a, b) => b.date.compareTo(a.date));
        break;
    }
    return trips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Logged out successfully.',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    duration: Duration(milliseconds: 1500),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.grey[900],
                    elevation: 6,
                  ),
                );
                await Future.delayed(const Duration(milliseconds: 1500));
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loadingTrips
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shimmer for profile
                  Row(
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[800]!,
                        highlightColor: Colors.grey[600]!,
                        child: CircleAvatar(radius: 50, backgroundColor: Colors.grey[900]),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey[800]!,
                              highlightColor: Colors.grey[600]!,
                              child: Container(height: 24, width: 120, color: Colors.grey[900]),
                            ),
                            const SizedBox(height: 8),
                            Shimmer.fromColors(
                              baseColor: Colors.grey[800]!,
                              highlightColor: Colors.grey[600]!,
                              child: Container(height: 16, width: 180, color: Colors.grey[900]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Shimmer for stats
                  Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[600]!,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Container(height: 28, width: 28, color: Colors.grey[900]),
                                const SizedBox(height: 8),
                                Container(height: 20, width: 32, color: Colors.grey[900]),
                                const SizedBox(height: 4),
                                Container(height: 14, width: 48, color: Colors.grey[900]),
                              ],
                            ),
                            Column(
                              children: [
                                Container(height: 28, width: 28, color: Colors.grey[900]),
                                const SizedBox(height: 8),
                                Container(height: 20, width: 32, color: Colors.grey[900]),
                                const SizedBox(height: 4),
                                Container(height: 14, width: 48, color: Colors.grey[900]),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Shimmer for lists
                  ...List.generate(3, (section) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[800]!,
                        highlightColor: Colors.grey[600]!,
                        child: Container(height: 22, width: 160, color: Colors.grey[900]),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(2, (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[800]!,
                          highlightColor: Colors.grey[600]!,
                          child: Card(
                            child: Container(height: 64, width: double.infinity, color: Colors.grey[900]),
                          ),
                        ),
                      )),
                      const SizedBox(height: 32),
                    ],
                  )),
                ],
              ),
            )
          : ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Builder(
            builder: (context) {
              final name = _profileName ?? 'User';
              final email = _profileEmail ?? '';
              final photoURL = _profilePhotoURL;
                      ImageProvider imageProvider;
                      if (photoURL != null && photoURL.isNotEmpty) {
                        if (photoURL.startsWith('http')) {
                          imageProvider = NetworkImage(photoURL);
                } else if (File(photoURL).existsSync()) {
                  imageProvider = FileImage(File(photoURL));
                        } else {
                  imageProvider = const AssetImage('assets/images/default_avatar.png');
                        }
                      } else {
                        imageProvider = const AssetImage('assets/images/default_avatar.png');
                      }
              return Column(
                children: [
                  CircleAvatar(radius: 50, backgroundImage: imageProvider),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      setState(() {}); // Refresh profile info after editing
                      await _loadProfileFromFirestore(); // Reload from Firestore
                      widget.onProfileUpdated(); // Notify parent to reload user profile
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          StatsCard(
            completed: completedTrips.length,
            scheduled: widget.scheduledTrips.length,
            onScheduledTap: () => setState(() {
              showScheduled = true;
              showCompleted = false;
            }),
            onCompletedTap: () => setState(() {
              showCompleted = true;
              showScheduled = false;
            }),
          ),
          const SizedBox(height: 32),
          if (showScheduled)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Scheduled Trips', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Sort by:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _scheduledSort,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'date_desc', child: Text('Newest')),
                        DropdownMenuItem(value: 'date_asc', child: Text('Oldest')),
                        DropdownMenuItem(value: 'name_asc', child: Text('Name A-Z')),
                        DropdownMenuItem(value: 'name_desc', child: Text('Name Z-A')),
                      ],
                      onChanged: (val) => setState(() => _scheduledSort = val ?? 'date_desc'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                widget.scheduledTrips.isEmpty
                    ? Column(
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.orangeAccent, semanticLabel: 'No scheduled trips'),
                          const SizedBox(height: 8),
                          const Text('No scheduled trips yet!', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _getSortedScheduledTrips().length,
                        itemBuilder: (context, index) {
                          final place = _getSortedScheduledTrips()[index];
                          final scheduledDate = _scheduledDates[place.name];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (scheduledDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                                  child: Text(
                                    'Scheduled for: ${_formatFullDate(scheduledDate)}',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 14),
                                  ),
                                ),
                              Stack(
                                children: [
                                  AnimatedFadeSlide(
                                    delay: Duration(milliseconds: 100 * (index + 1)),
                                    child: ScheduledTripCard(
                                      place: place,
                                      onAddToCompleted: () => _addToCompleted(place),
                                      onRemove: () => widget.onRemoveScheduledTrip(place.name),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 16,
                                    child: InkWell(
                                      onTap: () => _pickScheduledDate(place),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white10,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(Icons.calendar_today, color: Colors.red, size: 22),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
                const SizedBox(height: 32),
              ],
            ),
          if (showCompleted)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Completed Trips', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Sort by:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _completedSort,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'date_desc', child: Text('Newest')),
                        DropdownMenuItem(value: 'date_asc', child: Text('Oldest')),
                        DropdownMenuItem(value: 'name_asc', child: Text('Name A-Z')),
                        DropdownMenuItem(value: 'name_desc', child: Text('Name Z-A')),
                      ],
                      onChanged: (val) => setState(() => _completedSort = val ?? 'date_desc'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                completedTrips.isEmpty
                    ? Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: Colors.greenAccent, semanticLabel: 'No completed trips'),
                          const SizedBox(height: 8),
                          const Text('No completed trips yet!', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _getSortedCompletedTrips().length,
                        itemBuilder: (context, index) {
                          final trip = _getSortedCompletedTrips()[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 8, bottom: 2),
                                child: Text(
                                  'Trip Completed on: ${_formatFullDate(trip.date)}',
                                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w500, fontSize: 14),
                                ),
                              ),
                              AnimatedFadeSlide(
                                delay: Duration(milliseconds: 100 * (index + 1)),
                                child: CompletedTripCard(
                                  trip: trip,
                                  onRemove: () => _removeFromCompleted(trip),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
                const SizedBox(height: 32),
              ],
            ),
          const Text('My Wishlist', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          widget.wishlist.isEmpty
              ? Column(
                  children: [
                    Icon(Icons.favorite_border, size: 48, color: Colors.redAccent, semanticLabel: 'Add to wishlist'),
                    const SizedBox(height: 8),
                    const Text('Your wishlist is empty!', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.wishlist.length,
            itemBuilder: (context, index) {
                    final place = widget.wishlist[index];
              return AnimatedFadeSlide(
                delay: Duration(milliseconds: 100 * (index + 1)),
                      child: WishlistCard(
                        place: place,
                        onRemove: () => _removeFromWishlist(place.name),
                        onSchedule: () => widget.onScheduleTrip(place),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class StatsCard extends StatelessWidget {
  final int completed;
  final int scheduled;
  final VoidCallback onScheduledTap;
  final VoidCallback onCompletedTap;
  const StatsCard({super.key, required this.completed, required this.scheduled, required this.onScheduledTap, required this.onCompletedTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: InkWell(
                onTap: onCompletedTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: StatItem(icon: Icons.check_circle, label: 'Completed', value: '$completed'),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: onScheduledTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: StatItem(icon: Icons.calendar_today, label: 'Scheduled', value: '$scheduled'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const StatItem({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.tertiary, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
      ],
    );
  }
}

class WishlistCard extends StatelessWidget {
  final Place place;
  final VoidCallback onRemove;
  final VoidCallback onSchedule;
  const WishlistCard({super.key, required this.place, required this.onRemove, required this.onSchedule});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: place.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  place.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(Icons.place_outlined, color: Theme.of(context).colorScheme.primary),
        title: Text(place.name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(place.address, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaceDetailsScreen(place: place),
            ),
          );
        },
        onLongPress: () async {
          final result = await showModalBottomSheet<String>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.event_available, color: Colors.blue),
                    title: const Text('Schedule Trip', style: TextStyle(color: Colors.blue)),
                    onTap: () => Navigator.pop(context, 'schedule'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove from wishlist', style: TextStyle(color: Colors.red)),
                    onTap: () => Navigator.pop(context, 'remove'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.close),
                    title: const Text('Cancel'),
                    onTap: () => Navigator.pop(context, null),
                  ),
                ],
              ),
            ),
          );
          if (result == 'remove') {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Remove from Wishlist?'),
                content: Text('Are you sure you want to remove \u001b[1m${place.name}\u001b[0m from your wishlist?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
            if (confirm == true) {
              onRemove();
              final snackBar = SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.favorite_border, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${place.name} removed from wishlist')),
                  ],
                ),
                backgroundColor: Colors.grey[900],
                action: SnackBarAction(
                  label: 'Undo',
                  textColor: Colors.red,
                  onPressed: () {
                    onSchedule(); // Re-add to wishlist
                  },
                ),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 6,
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          } else if (result == 'schedule') {
            onSchedule();
          }
        },
      ),
    );
  }
}

class ScheduledTripCard extends StatelessWidget {
  final Place place;
  final VoidCallback onAddToCompleted;
  final VoidCallback onRemove;
  const ScheduledTripCard({super.key, required this.place, required this.onAddToCompleted, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: place.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  place.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(Icons.place_outlined, color: Theme.of(context).colorScheme.primary),
        title: Text(place.name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(place.address, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TripDetailsScreen(place: place),
            ),
          );
        },
        onLongPress: () async {
          final result = await showModalBottomSheet<String>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Add to Completed Trips', style: TextStyle(color: Colors.green)),
                    onTap: () => Navigator.pop(context, 'complete'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove from Scheduled Trips', style: TextStyle(color: Colors.red)),
                    onTap: () => Navigator.pop(context, 'remove'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.close),
                    title: const Text('Cancel'),
                    onTap: () => Navigator.pop(context, null),
                  ),
                ],
              ),
            ),
          );
          if (result == 'remove') {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Remove from Scheduled Trips?'),
                content: Text('Are you sure you want to remove \u001b[1m${place.name}\u001b[0m from your scheduled trips?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
            if (confirm == true) {
              onRemove();
              final snackBar = SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.event_busy, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${place.name} removed from scheduled trips')),
                  ],
                ),
                backgroundColor: Colors.grey[900],
                action: SnackBarAction(
                  label: 'Undo',
                  textColor: Colors.orange,
                  onPressed: () {
                    onAddToCompleted(); // Re-add to scheduled trips (use onAddToCompleted as a proxy for re-adding, or provide a dedicated callback if needed)
                  },
                ),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 6,
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          } else if (result == 'complete') {
            onAddToCompleted();
          }
        },
      ),
    );
  }
}

class CompletedTripCard extends StatelessWidget {
  final _CompletedTrip trip;
  final VoidCallback onRemove;
  const CompletedTripCard({super.key, required this.trip, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final place = trip.place;
    return Card(
      child: ListTile(
        leading: place.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  place.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(Icons.place_outlined, color: Theme.of(context).colorScheme.primary),
        title: Text(place.name, style: const TextStyle(color: Colors.white)),
        subtitle: Text(place.address, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TripDetailsScreen(place: place, completedDate: trip.date),
            ),
          );
        },
        onLongPress: () async {
          final result = await showModalBottomSheet<String>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove from Completed Trips', style: TextStyle(color: Colors.red)),
                    onTap: () => Navigator.pop(context, 'remove'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.close),
                    title: const Text('Cancel'),
                    onTap: () => Navigator.pop(context, null),
                  ),
                ],
              ),
            ),
          );
          if (result == 'remove') {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Remove from Completed Trips?'),
                content: Text('Are you sure you want to remove \u001b[1m${place.name}\u001b[0m from your completed trips?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
            if (confirm == true) {
              onRemove();
              final snackBar = SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${place.name} removed from completed trips')),
                  ],
                ),
                backgroundColor: Colors.grey[900],
                action: SnackBarAction(
                  label: 'Undo',
                  textColor: Colors.green,
                  onPressed: () {
                    // Re-add to completed trips (you may need to provide a callback or logic to restore the trip)
                  },
                ),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 6,
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          }
        },
      ),
    );
  }
}

class _CompletedTrip {
  final Place place;
  final DateTime date;
  _CompletedTrip({required this.place, required this.date});
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CompletedTrip &&
          runtimeType == other.runtimeType &&
          place.name == other.place.name &&
          date == other.date;
  @override
  int get hashCode => place.name.hashCode ^ date.hashCode;
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}

String _formatFullDate(DateTime date) {
  const months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${months[date.month]} ${date.day}, ${date.year}';
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    String? photoURL = user?.photoURL;
    // For demo: just use local file path as photoURL (in real app, upload to storage and get a URL)
    if (_imageFile != null) {
      photoURL = _imageFile!.path;
    }
    await user?.updateDisplayName(_nameController.text.trim());
    if (photoURL != null) await user?.updatePhotoURL(photoURL);
    await user?.reload();
    // Update Firestore profile as well
    if (user != null) {
      await UserProfileService.updateUserProfile(
        user.uid,
        name: _nameController.text.trim(),
        photoURL: photoURL,
      );
    }
    setState(() => _isLoading = false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully.', style: TextStyle(fontSize: 14, color: Colors.white70)),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: Colors.grey[900],
          elevation: 6,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final photo = _imageFile != null
        ? FileImage(_imageFile!)
        : (user?.photoURL != null && user!.photoURL!.isNotEmpty && File(user.photoURL!).existsSync()
            ? FileImage(File(user.photoURL!))
            : const NetworkImage('https://i.pravatar.cc/150?img=3') as ImageProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: photo,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Save Changes'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper methods for sorting
// List<Place> _getSortedScheduledTrips() {
//   final trips = List<Place>.from(widget.scheduledTrips);
//   switch (_scheduledSort) {
//     case 'name_asc':
//       trips.sort((a, b) => a.name.compareTo(b.name));
//       break;
//     case 'name_desc':
//       trips.sort((a, b) => b.name.compareTo(a.name));
//       break;
//     case 'date_asc':
//       // No date field, so fallback to name
//       trips.sort((a, b) => a.name.compareTo(b.name));
//       break;
//     case 'date_desc':
//     default:
//       // No date field, so fallback to name
//       trips.sort((a, b) => b.name.compareTo(a.name));
//       break;
//   }
//   return trips;
// }
// List<_CompletedTrip> _getSortedCompletedTrips() {
//   final trips = List<_CompletedTrip>.from(completedTrips);
//   switch (_completedSort) {
//     case 'name_asc':
//       trips.sort((a, b) => a.place.name.compareTo(b.place.name));
//       break;
//     case 'name_desc':
//       trips.sort((a, b) => b.place.name.compareTo(a.place.name));
//       break;
//     case 'date_asc':
//       trips.sort((a, b) => a.date.compareTo(b.date));
//       break;
//     case 'date_desc':
//     default:
//       trips.sort((a, b) => b.date.compareTo(a.date));
//       break;
//   }
//   return trips;
// }

class TripDetailsScreen extends StatelessWidget {
  final Place place;
  final DateTime? completedDate;
  const TripDetailsScreen({super.key, required this.place, this.completedDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(place.name)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (place.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                place.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 24),
          Text(place.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          if (place.address.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.deepPurpleAccent, size: 20),
                const SizedBox(width: 4),
                Expanded(child: Text(place.address, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70))),
              ],
            ),
          if (place.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(place.description, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
          ],
          if (completedDate != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 4),
                Text('Completed on: ${_formatFullDate(completedDate!)}', style: const TextStyle(color: Colors.greenAccent)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    // Format as 'July 10, 2024'
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}