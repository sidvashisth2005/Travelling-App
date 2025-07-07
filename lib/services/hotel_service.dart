// lib/services/hotel_service.dart

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
  static const host = 'travel-advisor.p.rapidapi.com';
  static const apiKey = '<YOUR_RAPIDAPI_KEY>';

  Future<String?> getLocationId(String city) async {
    final uri = Uri.https(host, '/locations/search', {
      'query': city,
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
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['data'] as List;
      if (data.isNotEmpty) return data[0]['result_object']['location_id']?.toString();
    }
    return null;
  }

  Future<List<Hotel>> fetchHotels(String locationId) async {
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
      return arr.map((h) {
        final r = h['hotel'] ?? h['result_object'];
        final photo = r['photo']?['images']?['medium']?['url'] ?? '';
        return Hotel(
          name: r['name'] ?? 'Unknown',
          address: r['address'] ?? '',
          price: h['price']?['current_prices'] ?? 'N/A',
          imageUrl: photo,
          rating: (h['rating'] ?? 0).toDouble(),
        );
      }).toList();
    } else {
      throw Exception('Hotels fetch failed (status: ${res.statusCode})');
    }
  }
}
