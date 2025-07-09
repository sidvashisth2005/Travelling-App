import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../services/places_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'place_details_screen.dart';
import 'all_destinations_screen.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  final Set<String> wishlist;
  final List<Place> scheduledTrips;
  final void Function(String, bool) onWishlistChanged;
  final void Function(Place) onScheduleTrip;
  final void Function(List<Place>) registerPlaces;
  final String displayName;
  const HomeScreen({
    super.key,
    required this.wishlist,
    required this.scheduledTrips,
    required this.onWishlistChanged,
    required this.onScheduleTrip,
    required this.registerPlaces,
    required this.displayName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Place> popularDestinations = [];
  bool _isPopularLoading = true;

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Place> _places = [];

  @override
  void initState() {
    super.initState();
    _fetchPopularDestinations();
  }

  Future<void> _fetchPopularDestinations() async {
    setState(() => _isPopularLoading = true);
    final places = await PlacesService.fetchPopularIndianDestinations();
    widget.registerPlaces(places);
    setState(() {
      popularDestinations = places;
      _isPopularLoading = false;
    });
  }

  Future<void> _searchPlaces() async {
    setState(() => _isLoading = true);
    final places = await PlacesService.fetchTopPlaces(_searchController.text);
    widget.registerPlaces(places);
    setState(() {
      _places = places;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      return Text('Hi, ${widget.displayName}', style: theme.textTheme.bodyMedium);
                    },
                  ),
                  Text('Where to next?', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(hintText: 'Search for a city...', prefixIcon: Icon(Icons.search)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _searchPlaces,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader(context, 'Popular Destinations'),
            if (_isPopularLoading)
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 4,
                  itemBuilder: (context, index) => Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[600]!,
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            if (!_isPopularLoading && popularDestinations.isNotEmpty)
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: popularDestinations.length,
                  itemBuilder: (context, index) {
                    final place = popularDestinations[index];
                    final isWishlisted = widget.wishlist.contains(place.name);
                    return GestureDetector(
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
                                  leading: const Icon(Icons.event_available, color: Colors.blue, semanticLabel: 'Schedule Trip'),
                                  title: const Text('Schedule Trip', style: TextStyle(color: Colors.blue)),
                                  onTap: () => Navigator.pop(context, 'schedule'),
                                ),
                                if (isWishlisted)
                                  ListTile(
                                    leading: const Icon(Icons.delete, color: Colors.red, semanticLabel: 'Remove from wishlist'),
                                    title: const Text('Remove from wishlist', style: TextStyle(color: Colors.red)),
                                    onTap: () => Navigator.pop(context, 'remove'),
                                  ),
                                ListTile(
                                  leading: const Icon(Icons.close, semanticLabel: 'Cancel'),
                                  title: const Text('Cancel'),
                                  onTap: () => Navigator.pop(context, null),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (result == 'schedule') {
                          widget.onScheduleTrip(place);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.event_available, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text('Scheduled trip to ${place.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                        } else if (result == 'remove') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remove from Wishlist?'),
                              content: Text('Are you sure you want to remove ${place.name} from your wishlist?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            widget.onWishlistChanged(place.name, false);
                            if (context.mounted) {
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
                                    widget.onWishlistChanged(place.name, true);
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
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  place.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                                  errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.red),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(place.description, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                widget.onWishlistChanged(place.name, !isWishlisted);
                              },
                              child: Icon(
                                isWishlisted ? Icons.favorite : Icons.favorite_border,
                                color: isWishlisted ? Colors.red : Colors.white,
                                size: 28,
                                semanticLabel: isWishlisted ? 'Remove from wishlist' : 'Add to wishlist',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (!_isPopularLoading && popularDestinations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No popular destinations found.', style: TextStyle(fontSize: 16)),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0, bottom: 8),
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh popular destinations',
                  onPressed: _fetchPopularDestinations,
                ),
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Top Places'),
                    ...List.generate(4, (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[800]!,
                        highlightColor: Colors.grey[600]!,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            if (_places.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Top Places'),
                    ..._places.map((place) {
                      final isWishlisted = widget.wishlist.contains(place.name);
                      return GestureDetector(
                        onLongPress: () async {
                          final result = await showModalBottomSheet<String>(
                            context: context,
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.event_available, color: Colors.blue, semanticLabel: 'Schedule Trip'),
                                    title: const Text('Schedule Trip', style: TextStyle(color: Colors.blue)),
                                    onTap: () => Navigator.pop(context, 'schedule'),
                                  ),
                                  if (isWishlisted)
                                    ListTile(
                                      leading: const Icon(Icons.delete, color: Colors.red, semanticLabel: 'Remove from wishlist'),
                                      title: const Text('Remove from wishlist', style: TextStyle(color: Colors.red)),
                                      onTap: () => Navigator.pop(context, 'remove'),
                                    ),
                                  ListTile(
                                    leading: const Icon(Icons.close, semanticLabel: 'Cancel'),
                                    title: const Text('Cancel'),
                                    onTap: () => Navigator.pop(context, null),
                                  ),
                                ],
                              ),
                            ),
                          );
                          if (result == 'schedule') {
                            widget.onScheduleTrip(place);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Trip scheduled for  [1m${place.name} [0m')),
                              );
                            }
                          } else if (result == 'remove') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Remove from Wishlist?'),
                                content: Text('Are you sure you want to remove ${place.name} from your wishlist?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              widget.onWishlistChanged(place.name, false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${place.name} removed from wishlist')),
                                );
                              }
                            }
                          }
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Stack(
                            children: [
                              ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: place.imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      place.imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.place, size: 32, color: Colors.deepPurpleAccent),
                                  ),
                            title: Text(
                              place.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: place.description.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      place.description,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlaceDetailsScreen(place: place),
                                ),
                              );
                            },
                          ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    widget.onWishlistChanged(place.name, !isWishlisted);
                                  },
                                  child: Icon(
                                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                                    color: isWishlisted ? Colors.red : Colors.white,
                                    size: 28,
                                    semanticLabel: isWishlisted ? 'Remove from wishlist' : 'Add to wishlist',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isPopular = title == 'Popular Destinations';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          TextButton(
            onPressed: isPopular
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllDestinationsScreen(destinations: popularDestinations),
                      ),
                    );
                  }
                : () {},
            child: Text('See All', style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
          ),
        ],
      ),
    );
  }
}

class DestinationCard extends StatelessWidget {
  const DestinationCard({super.key, required this.destination});
  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                destination.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(destination.city, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(destination.country, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}