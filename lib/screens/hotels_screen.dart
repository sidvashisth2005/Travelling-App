import 'package:flutter/material.dart';
import '../services/hotel_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/places_service.dart';

class HotelsScreen extends StatefulWidget {
  const HotelsScreen({super.key});

  @override
  State<HotelsScreen> createState() => _HotelsScreenState();
}

class _HotelsScreenState extends State<HotelsScreen> {
  final TextEditingController _locationController = TextEditingController();
  final HotelService _hotelService = HotelService();
  bool _isLoading = false;
  String? _errorMessage;
  List<Hotel> _hotels = [];
  String? _detectedArea;

  // Filter state
  RangeValues _priceRange = const RangeValues(0, 10000);
  String _roomType = 'Any';
  String _acType = 'Any';
  double _minRating = 0;

  List<String> roomTypes = ['Any', 'Single', 'Double', 'Hall'];
  List<String> acTypes = ['Any', 'AC', 'Non AC'];

  Future<void> _searchHotels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hotels = [];
    });
    try {
      final hotels = await _hotelService.fetchHotels(_locationController.text);
      setState(() {
        _hotels = hotels;
        _isLoading = false;
      });
      if (hotels.isEmpty) {
        setState(() {
          _errorMessage = 'No hotels found for this area.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch hotels. Please try again.';
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hotels = [];
      _detectedArea = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location services are disabled.';
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location services are disabled.', style: TextStyle(fontSize: 14, color: Colors.white70)),
              duration: Duration(milliseconds: 1500),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.grey[900],
              elevation: 6,
            ),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Location permissions are denied.';
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Location permissions are denied.', style: TextStyle(fontSize: 14, color: Colors.white70)),
                duration: Duration(milliseconds: 1500),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.grey[900],
                elevation: 6,
              ),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permissions are permanently denied.';
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permissions are permanently denied.', style: TextStyle(fontSize: 14, color: Colors.white70)),
              duration: Duration(milliseconds: 1500),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.grey[900],
              elevation: 6,
            ),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      // Use coordinates to get nearest location_id
      final locationResult = await _hotelService.getLocationInfoByCoords(position.latitude, position.longitude);
      final locationId = locationResult['location_id'];
      final areaName = locationResult['name'];
      if (locationId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No hotels found for your current location.';
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No hotels found for your current location.', style: TextStyle(fontSize: 14, color: Colors.white70)),
              duration: Duration(milliseconds: 1500),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.grey[900],
              elevation: 6,
            ),
          );
        }
        return;
      }
      final hotels = await _hotelService.fetchHotels(locationId);
      setState(() {
        _hotels = hotels;
        _isLoading = false;
        _detectedArea = areaName;
        _locationController.text = areaName ?? '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch hotels for your location.';
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to fetch hotels for your location.', style: TextStyle(fontSize: 14, color: Colors.white70)),
            duration: Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.grey[900],
            elevation: 6,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hotelsWithCoords = _hotels.where((h) => h.latitude != null && h.longitude != null).toList();
    // Apply filters
    final filteredHotels = _hotels.where((hotel) {
      // Price filter (assume price is a string like '₹1234' or 'N/A')
      double price = 0;
      final priceMatch = RegExp(r'(\d+)').firstMatch(hotel.price);
      if (priceMatch != null) price = double.tryParse(priceMatch.group(1)!) ?? 0;
      final inPrice = price >= _priceRange.start && price <= _priceRange.end || hotel.price == 'N/A';
      final inRoom = _roomType == 'Any' || hotel.name.toLowerCase().contains(_roomType.toLowerCase());
      final inAC = _acType == 'Any' || hotel.name.toLowerCase().contains(_acType.toLowerCase());
      final inRating = hotel.rating >= _minRating;
      return inPrice && inRoom && inAC && inRating;
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Hotels'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Find the Perfect Stay', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Enter the area you want to stay in or are currently in, and discover the best hotels.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Enter area or location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  onSubmitted: (_) => _searchHotels(),
                  enabled: !_isLoading,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Search'),
                onPressed: _searchHotels,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.my_location, color: Colors.white70),
                tooltip: 'Use My Current Location',
                onPressed: _useCurrentLocation,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filters bar
          Card(
            color: theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_alt, color: Colors.deepPurpleAccent),
                      const SizedBox(width: 8),
                      Text('Filters', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Price Range
                  const Text('Price Range'),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 10000,
                    divisions: 20,
                    labels: RangeLabels('₹${_priceRange.start.toInt()}', '₹${_priceRange.end.toInt()}'),
                    onChanged: (v) => setState(() => _priceRange = v),
                  ),
                  const SizedBox(height: 20),
                  // Room Type and AC/Non AC
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Room Type'),
                            DropdownButton<String>(
                              value: _roomType,
                              isExpanded: true,
                              items: roomTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (v) => setState(() => _roomType = v!),
                              hint: const Text('Room Type'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('AC/Non AC'),
                            DropdownButton<String>(
                              value: _acType,
                              isExpanded: true,
                              items: acTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (v) => setState(() => _acType = v!),
                              hint: const Text('AC/Non AC'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Min Rating
                  Row(
                    children: [
                      const Text('Min. Rating:'),
                      Expanded(
                        child: Slider(
                          value: _minRating,
                          min: 0,
                          max: 5,
                          divisions: 5,
                          label: _minRating.toStringAsFixed(1),
                          onChanged: (v) => setState(() => _minRating = v),
                        ),
                      ),
                      Text(_minRating > 0 ? _minRating.toStringAsFixed(1) : 'Any'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
            ),
          if (filteredHotels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 260,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        filteredHotels.first.latitude!,
                        filteredHotels.first.longitude!,
                      ),
                      initialZoom: 13.0,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.travel_app',
                      ),
                      MarkerLayer(
                        markers: filteredHotels.map((hotel) => Marker(
                          width: 48,
                          height: 48,
                          point: LatLng(hotel.latitude!, hotel.longitude!),
                          child: Icon(Icons.location_on, color: theme.colorScheme.primary, size: 36),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (filteredHotels.isNotEmpty)
            ...filteredHotels.map((hotel) => Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: hotel.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              hotel.imageUrl,
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
                            child: const Icon(Icons.hotel, size: 32, color: Colors.deepPurpleAccent),
                          ),
                    title: Text(
                      hotel.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hotel.address.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              hotel.address,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (hotel.price.isNotEmpty)
                          Text('Price: ${hotel.price}', style: theme.textTheme.bodySmall),
                        if (hotel.rating > 0)
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(hotel.rating.toStringAsFixed(1), style: theme.textTheme.bodySmall),
                            ],
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HotelDetailsScreen(hotel: hotel),
                        ),
                      );
                    },
                  ),
                )),
          if (_detectedArea != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.deepPurpleAccent, size: 18),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text('Showing hotels near: $_detectedArea',
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class HotelDetailsScreen extends StatefulWidget {
  final Hotel hotel;
  const HotelDetailsScreen({super.key, required this.hotel});

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> {
  String? _nearbyLandmark;

  @override
  void initState() {
    super.initState();
    final h = widget.hotel;
    if (h.latitude != null && h.longitude != null) {
      PlacesService.fetchNearbyLandmark(h.latitude!, h.longitude!).then((landmark) {
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
    final h = widget.hotel;
    if (h.latitude == null || h.longitude == null) return;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${h.latitude},${h.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showMap(BuildContext context) {
    final h = widget.hotel;
    if (h.latitude == null || h.longitude == null) return;
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
                        initialCenter: LatLng(h.latitude!, h.longitude!),
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
                              point: LatLng(h.latitude!, h.longitude!),
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
                  h.address,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ),
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
                      final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${h.latitude},${h.longitude}');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = widget.hotel;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Hotel Details'),
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
                  child: h.imageUrl.isNotEmpty
                      ? Image.network(
                          h.imageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) => progress == null ? child : const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
                          errorBuilder: (_, __, ___) => Container(
                            height: 220,
                            color: Colors.grey[800],
                            child: const Icon(Icons.broken_image, size: 60, color: Colors.white24),
                          ),
                        )
                      : Container(
                          height: 220,
                          color: Colors.grey[800],
                          child: const Icon(Icons.hotel, size: 60, color: Colors.white24),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.name, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 10),
                      if (h.address.isNotEmpty)
                        Text(h.address, style: theme.textTheme.bodyMedium, maxLines: 4, overflow: TextOverflow.ellipsis),
                      if (h.price.isNotEmpty && h.price != 'N/A')
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Price: ${h.price}', style: theme.textTheme.bodyMedium),
                        ),
                      if (h.rating > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(h.rating.toStringAsFixed(1), style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      const SizedBox(height: 18),
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
                          onPressed: h.latitude != null && h.longitude != null
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
                      if (h.latitude != null && h.longitude != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 220,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(h.latitude!, h.longitude!),
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
                                      point: LatLng(h.latitude!, h.longitude!),
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
}