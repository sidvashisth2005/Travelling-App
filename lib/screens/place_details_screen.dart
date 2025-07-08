import 'package:flutter/material.dart';
import '../services/places_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailsScreen({
    super.key,
    required this.place,
  });

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  String? _nearbyLandmark;

  @override
  void initState() {
    super.initState();
    final place = widget.place;
    if (place.latitude != null && place.longitude != null) {
      PlacesService.fetchNearbyLandmark(place.latitude!, place.longitude!).then((landmark) {
        if (mounted) {
          setState(() {
            _nearbyLandmark = landmark ?? 'Not available';
          });
        }
      });
    } else {
      _nearbyLandmark = 'Not available';
    }
  }

  Future<void> _openLandmarkInMaps() async {
    final place = widget.place;
    if (place.latitude == null || place.longitude == null) return;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = widget.place;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Place Details'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            color: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    place.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null ? child : const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: Colors.grey[800],
                      child: const Icon(Icons.broken_image, size: 60, color: Colors.white24),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 10),
                      if (place.description.isNotEmpty)
                        Text(
                          place.description,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white54, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              place.address,
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Nearby Landmark Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nearby Landmark', style: theme.textTheme.labelLarge),
                                const SizedBox(height: 2),
                                if (_nearbyLandmark != null && _nearbyLandmark != 'Loading...' && _nearbyLandmark != 'Not available')
                                  GestureDetector(
                                    onTap: _openLandmarkInMaps,
                                    child: Text(
                                      _nearbyLandmark!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.tertiary,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                else
                                  Text(
                                    _nearbyLandmark ?? 'Loading...',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: place.latitude != null && place.longitude != null
                              ? () => _showMap(context)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('SEE ON MAPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Inline preview map (static, non-interactive)
                      if (place.latitude != null && place.longitude != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 220,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(place.latitude!, place.longitude!),
                                initialZoom: 13.5,
                                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  subdomains: const ['a', 'b', 'c'],
                                  userAgentPackageName: 'com.example.travel_app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      width: 60,
                                      height: 60,
                                      point: LatLng(place.latitude!, place.longitude!),
                                      child: Icon(Icons.location_on, color: theme.colorScheme.primary, size: 40),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text('Location coordinates not available', style: TextStyle(color: Colors.white38)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMap(BuildContext context) {
    final place = widget.place;
    if (place.latitude == null || place.longitude == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text('Location on Map', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(place.latitude!, place.longitude!),
                        initialZoom: 15.5,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'com.example.travel_app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 60,
                              height: 60,
                              point: LatLng(place.latitude!, place.longitude!),
                              child: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  place.address,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ),
              // Get Directions Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.directions, color: Colors.white),
                    label: const Text('Get Directions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 