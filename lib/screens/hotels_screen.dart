import 'package:flutter/material.dart';
import '../services/hotel_service.dart';
import 'package:geolocator/geolocator.dart';

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

  Future<void> _searchHotels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hotels = [];
    });
    try {
      final locationId = await _hotelService.getLocationId(_locationController.text);
      if (locationId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No hotels found for this area.';
        });
        return;
      }
      final hotels = await _hotelService.fetchHotels(locationId);
      setState(() {
        _hotels = hotels;
        _isLoading = false;
      });
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
          const SizedBox(height: 32),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
            ),
          if (_hotels.isNotEmpty)
            ..._hotels.map((hotel) => Card(
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
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(hotel.address, style: const TextStyle(fontSize: 13)),
                          ),
                        if (hotel.price.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text('Price: ${hotel.price}', style: const TextStyle(fontSize: 13)),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(hotel.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
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