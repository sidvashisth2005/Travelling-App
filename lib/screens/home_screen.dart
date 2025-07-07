import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../services/places_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
    setState(() {
      popularDestinations = places;
      _isPopularLoading = false;
    });
  }

  Future<void> _searchPlaces() async {
    setState(() => _isLoading = true);
    final places = await PlacesService.fetchTopPlaces(_searchController.text);
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
                      final user = FirebaseAuth.instance.currentUser;
                      final name = user?.displayName ?? 'Traveler';
                      return Text('Hi, $name', style: theme.textTheme.bodyMedium);
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
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )),
            if (!_isPopularLoading && popularDestinations.isNotEmpty)
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: popularDestinations.length,
                  itemBuilder: (context, index) {
                    final place = popularDestinations[index];
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
              const Center(child: CircularProgressIndicator()),
            if (_places.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Top Places'),
                    ..._places.map((place) => Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
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
                          ),
                        )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          TextButton(onPressed: () {}, child: Text('See All', style: TextStyle(color: Theme.of(context).colorScheme.tertiary))),
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