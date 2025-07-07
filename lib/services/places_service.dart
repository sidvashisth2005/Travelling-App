import 'dart:convert';
import 'package:http/http.dart' as http;

class Place {
  final String name;
  final String description;
  final String imageUrl;

  Place({required this.name, required this.description, required this.imageUrl});
}

class PlacesService {
  static const String host = 'travel-advisor.p.rapidapi.com';
  static const String apiKey = 'edf817298dmsh1546aaf8d19ca75p1da5a5jsn7d6b3c2cb31d';

  static Future<String?> getLocationId(String city) async {
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

  static Future<List<Place>> fetchTopPlaces(String city) async {
    final locationId = await getLocationId(city);
    if (locationId == null) return [];
    final uri = Uri.https(host, '/attractions/list', {
      'location_id': locationId,
      'currency': 'USD',
      'lang': 'en_US',
      'sort': 'recommended',
      'lunit': 'km',
      'limit': '10',
    });
    final res = await http.get(uri, headers: {
      'x-rapidapi-key': apiKey,
      'x-rapidapi-host': host,
    });
    if (res.statusCode == 200) {
      final arr = jsonDecode(res.body)['data'] as List;
      return arr.where((p) => p['name'] != null && p['photo'] != null).map<Place>((p) {
        return Place(
          name: p['name'] ?? '',
          description: p['description'] ?? '',
          imageUrl: p['photo']?['images']?['medium']?['url'] ?? '',
        );
      }).toList();
    }
    return [];
  }
} 