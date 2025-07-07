// lib/services/hotel_service.dart

// This service is ONLY for hotels (Hotels page), NOT for places/POIs.
// Only this service should call the /hotels/list endpoint.
// For places/POIs, use places_service.dart instead.

import 'dart:convert';
import 'package:http/http.dart' as http;

class Hotel {
  final String name, address, price, imageUrl;
  final double rating;

  Hotel({
    required this.name,
    required this.address,
    required this.price,
    required this.imageUrl,
    required this.rating,
  });
}

class HotelService {
  static const host = 'tripadvisor-com1.p.rapidapi.com';
  static const apiKey = 'edf817298dmsh1546aaf8d19ca75p1da5a5jsn7d6b3c2cb31d';

  Future<String?> getLocationId(String city) async {
    print('Fetching location ID for: $city');
    final uri = Uri.https(host, '/locations/search', {
      'query': city,
      'limit': '5',
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
    print('Location search response: [33m${res.statusCode} ${res.body}[0m');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['data'] as List;
      if (data.isNotEmpty) {
        final city = data.firstWhere(
          (item) => item['result_type'] == 'city' || item['result_type'] == 'geos',
          orElse: () => null,
        );
        if (city != null) {
          return city['result_object']['location_id']?.toString();
        }
        // Fallback: use first result
        return data[0]['result_object']['location_id']?.toString();
      }
    }
    return null;
  }

  Future<String?> getLocationIdByCoords(double lat, double lng) async {
    print('Fetching location ID for coordinates: $lat, $lng');
    final uri = Uri.https(host, '/locations/search', {
      'latitude': lat.toString(),
      'longitude': lng.toString(),
      'limit': '5',
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
    print('Location search by coords response: [33m${res.statusCode} ${res.body}[0m');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['data'] as List;
      if (data.isNotEmpty) {
        final city = data.firstWhere(
          (item) => item['result_type'] == 'city' || item['result_type'] == 'geos',
          orElse: () => null,
        );
        if (city != null) {
          return city['result_object']['location_id']?.toString();
        }
        // Fallback: use first result
        return data[0]['result_object']['location_id']?.toString();
      }
    }
    return null;
  }

  Future<List<Hotel>> fetchHotels(String locationId) async {
    print('Fetching hotels for locationId: $locationId');
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
    print('Hotels fetch response: ${res.statusCode} ${res.body}');
    if (res.statusCode == 200) {
      final arr = jsonDecode(res.body)['data'] as List;
      return arr.map((h) {
        final r = h['hotel'] ?? h['result_object'];
        final name = r['name'] ?? '';
        final address = r['address'] ?? '';
        final photo = r['photo']?['images']?['medium']?['url'] ?? '';
        return Hotel(
          name: name,
          address: address,
          price: h['price']?['current_prices'] ?? 'N/A',
          imageUrl: photo,
          rating: (h['rating'] ?? 0).toDouble(),
        );
      }).where((hotel) => hotel.name.isNotEmpty && hotel.address.isNotEmpty).toList();
    } else {
      throw Exception('Hotels fetch failed (status: [31m${res.statusCode}[0m)');
    }
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
