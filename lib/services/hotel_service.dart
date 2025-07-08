// lib/services/hotel_service.dart

// This service is ONLY for hotels (Hotels page), NOT for places/POIs.
// Only this service should call the /hotels/list endpoint.
// For places/POIs, use places_service.dart instead.

import 'dart:convert';
import 'package:http/http.dart' as http;

class Hotel {
  final String name, address, price, imageUrl;
  final double rating;
  final double? latitude;
  final double? longitude;

  Hotel({
    required this.name,
    required this.address,
    required this.price,
    required this.imageUrl,
    required this.rating,
    this.latitude,
    this.longitude,
  });
}

class HotelService {
  static const host = 'travel-advisor.p.rapidapi.com';
  static const apiKey = 'cdc3752538mshc4fb1defcf687cbp1cb762jsna80c7989bb21';

  Future<String?> getLocationId(String city) async {
    final uri = Uri.https(host, '/locations/search', {
      'query': city,
      'limit': '3',
      'offset': '0',
      'units': 'km',
      'location_id': '1',
      'currency': 'USD',
      'sort': 'relevance',
      'lang': 'en_US',
    });
    final res = await http.get(uri, headers: {
      'x-rapidapi-key': apiKey,
      'x-rapidapi-host': host,
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['data'] as List;
      if (data.isNotEmpty) {
        return data[0]['result_object']['location_id']?.toString();
      }
    }
    return null;
  }

  Future<List<Hotel>> fetchHotels(String city) async {
    // 1. Try Travel API
    final locationId = await getLocationId(city);
    if (locationId != null) {
      final uri = Uri.https(host, '/hotels/list', {
        'location_id': locationId,
        'currency': 'USD',
        'limit': '10',
        'adults': '1',
        'rooms': '1',
        'offset': '0',
        'sort': 'recommended',
        'lang': 'en_US',
      });
      final res = await http.get(uri, headers: {
        'x-rapidapi-key': apiKey,
        'x-rapidapi-host': host,
      });
      if (res.statusCode == 200) {
        final arr = jsonDecode(res.body)['data'] as List;
        final hotels = arr.map((h) {
          final r = h['hotel'] ?? h['result_object'];
          final name = r['name'] ?? '';
          final address = r['address'] ?? '';
          final photo = r['photo']?['images']?['medium']?['url'] ?? '';
          final lat = r['latitude'] != null ? double.tryParse(r['latitude'].toString()) : null;
          final lon = r['longitude'] != null ? double.tryParse(r['longitude'].toString()) : null;
          return Hotel(
            name: name,
            address: address,
            price: h['price']?['current_prices'] ?? 'N/A',
            imageUrl: photo,
            rating: (h['rating'] ?? 0).toDouble(),
            latitude: lat,
            longitude: lon,
          );
        }).where((hotel) => hotel.name.isNotEmpty && hotel.address.isNotEmpty).toList();
        if (hotels.isNotEmpty) return hotels;
      }
    }
    // 2. Fallback: OSM Nominatim (hotels, hostels, guest houses, motels)
    final types = ['hotel', 'hostel', 'guest_house', 'motel'];
    final List<Hotel> allResults = [];
    for (final type in types) {
      final osmUri = Uri.parse('https://nominatim.openstreetmap.org/search?city=${Uri.encodeComponent(city)}&format=json&extratags=1&addressdetails=1&limit=15&tourism=$type');
      final osmRes = await http.get(osmUri, headers: {
        'User-Agent': 'travel_app/1.0 (your@email.com)',
      });
      if (osmRes.statusCode == 200) {
        final arr = jsonDecode(osmRes.body) as List;
        for (final h in arr) {
          final name = h['namedetails']?['name'] ?? h['display_name']?.split(',')?.first ?? 'Accommodation';
          final address = h['display_name'] ?? '';
          final lat = h['lat'] != null ? double.tryParse(h['lat'].toString()) : null;
          final lon = h['lon'] != null ? double.tryParse(h['lon'].toString()) : null;
          String imageUrl = '';
          if (h['extratags'] != null && h['extratags']['image'] != null) {
            imageUrl = h['extratags']['image'];
          }
          // Deduplicate by lat/lon
          if (lat != null && lon != null && !allResults.any((hotel) => hotel.latitude == lat && hotel.longitude == lon)) {
            allResults.add(Hotel(
              name: name,
              address: address,
              price: 'N/A',
              imageUrl: imageUrl,
              rating: 0,
              latitude: lat,
              longitude: lon,
            ));
          }
        }
      }
    }
    return allResults;
  }

  Future<Map<String, String?>> getLocationInfoByCoords(double lat, double lng) async {
    print('Fetching location info for coordinates: $lat, $lng');
    final uri = Uri.https(host, '/locations/search', {
      'latitude': lat.toString(),
      'longitude': lng.toString(),
      'limit': '1',
      'offset': '0',
      'units': 'km',
      'location_id': '1',
      'currency': 'USD',
      'sort': 'relevance',
      'lang': 'en_US',
    });
    final res = await http.get(uri, headers: {
      'x-rapidapi-key': apiKey,
      'x-rapidapi-host': host,
    });
    print('Location info by coords response: ${res.statusCode} ${res.body}');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['data'] as List;
      if (data.isNotEmpty) {
        final obj = data[0]['result_object'];
        return {
          'location_id': obj['location_id']?.toString(),
          'name': obj['name']?.toString(),
        };
      }
    }
    return {'location_id': null, 'name': null};
  }
}
