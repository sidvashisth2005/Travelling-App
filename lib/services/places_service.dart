import 'dart:convert';
import 'package:http/http.dart' as http;

// This service is ONLY for places/POIs (Explore page), NOT for hotels.
// Do NOT use this service to fetch hotels or call /hotels/list endpoint.
// If you need hotels, use hotel_service.dart instead.

class Place {
  final String name;
  final String description;
  final String imageUrl;
  final double? latitude;
  final double? longitude;
  final String address;

  Place({
    required this.name, 
    required this.description, 
    required this.imageUrl,
    this.latitude,
    this.longitude,
    required this.address,
  });
}

class PlacesService {
  static const String host = 'travel-advisor.p.rapidapi.com';
  static String? _apiKey;
  static setApiKey(String key) => _apiKey = key;
  static String get apiKey => _apiKey ?? '';

  static Future<String?> getLocationId(String city) async {
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
          latitude: p['latitude'] != null ? double.tryParse(p['latitude'].toString()) : null,
          longitude: p['longitude'] != null ? double.tryParse(p['longitude'].toString()) : null,
          address: p['address_string'] ?? p['location_string'] ?? '',
        );
      }).toList();
    }
    return [];
  }

  static Future<List<Place>> fetchPopularIndianDestinations() async {
    // List of major Indian cities for more variety
    final cityNames = [
      'Delhi', 'Mumbai', 'Bangalore', 'Hyderabad', 'Chennai', 'Kolkata',
      'Pune', 'Jaipur', 'Ahmedabad', 'Goa', 'Agra', 'Varanasi', 'Udaipur',
      'Mysore', 'Amritsar', 'Lucknow', 'Indore', 'Bhopal', 'Surat', 'Chandigarh',
      'Shimla', 'Manali', 'Rishikesh', 'Jodhpur', 'Kochi', 'Guwahati', 'Shillong',
      'Darjeeling', 'Gangtok', 'Puri', 'Madurai', 'Coimbatore', 'Nagpur', 'Nashik',
      'Aurangabad', 'Patna', 'Ranchi', 'Raipur', 'Dehradun', 'Haridwar', 'Puri',
      'Kanpur', 'Meerut', 'Vadodara', 'Thiruvananthapuram', 'Jamshedpur', 'Gwalior',
      'Noida', 'Faridabad', 'Ghaziabad', 'Rajkot', 'Jabalpur', 'Aligarh', 'Bikaner',
      'Ajmer', 'Jhansi', 'Bareilly', 'Dhanbad', 'Bhilai', 'Kozhikode', 'Thrissur',
      'Vijayawada', 'Visakhapatnam', 'Warangal', 'Tirupati', 'Mathura', 'Siliguri',
      'Kolhapur', 'Solapur', 'Hubli', 'Belgaum', 'Guntur', 'Nellore', 'Kurnool',
      'Cuttack', 'Bhubaneswar', 'Jalandhar', 'Ludhiana', 'Panipat', 'Sonipat',
      'Rohtak', 'Hisar', 'Ambala', 'Moradabad', 'Saharanpur', 'Alwar', 'Rewa',
      'Satna', 'Ratlam', 'Ujjain', 'Haldwani', 'Nainital', 'Mussoorie', 'Durgapur',
      'Asansol', 'Bardhaman', 'Kharagpur', 'Durg', 'Bilaspur', 'Korba', 'Raigarh',
      'Silchar', 'Aizawl', 'Imphal', 'Itanagar', 'Kohima', 'Agartala', 'Port Blair',
      'Puducherry', 'Kanyakumari', 'Rameswaram', 'Cherrapunji', 'Tawang', 'Leh',
      'Kargil', 'Srinagar', 'Jammu', 'Baramulla', 'Kupwara', 'Pahalgam', 'Gulmarg',
      'Katra', 'Palampur', 'Mandi', 'Kullu', 'Solan', 'Dharamshala', 'Dalhousie',
      'Mount Abu', 'Pushkar', 'Bundi', 'Chittorgarh', 'Sikar', 'Shekhawati',
      'Mandawa', 'Jaisalmer', 'Bharatpur', 'Dausa', 'Sawai Madhopur', 'Alleppey',
      'Munnar', 'Wayanad', 'Thekkady', 'Kovalam', 'Varkala', 'Kumarakom',
      'Hampi', 'Badami', 'Pattadakal', 'Bijapur', 'Bidar', 'Gadag', 'Hospet',
      'Chikmagalur', 'Coorg', 'Halebidu', 'Belur', 'Shravanabelagola', 'Yercaud',
      'Kodaikanal', 'Ooty', 'Coonoor', 'Pollachi', 'Palani', 'Dindigul', 'Madikeri',
      'Mandya', 'Tumkur', 'Hassan', 'Bagalkot', 'Karwar', 'Sirsi', 'Dandeli',
      'Gokarna', 'Karimnagar', 'Nizamabad', 'Adilabad', 'Mahbubnagar', 'Medak',
      'Suryapet', 'Khammam', 'Nalgonda', 'Warangal', 'Karimganj', 'Tezpur',
      'Dibrugarh', 'Tinsukia', 'Jorhat', 'Nagaon', 'Diphu', 'Haflong',
      'Goalpara', 'Bongaigaon', 'Barpeta', 'Dhubri', 'Morigaon', 'Baksa',
      'Udalguri', 'Charaideo', 'Majuli', 'Lakhimpur', 'Dhemaji', 'Hojai',
      'Biswanath', 'South Salmara', 'West Karbi Anglong', 'East Karbi Anglong',
      'Kamrup', 'Kamrup Metropolitan', 'Darrang', 'Sonitpur', 'Golaghat',
      'Sivasagar', 'Jorhat', 'Tinsukia', 'Dibrugarh', 'Lakhimpur', 'Dhemaji',
      'Charaideo', 'Majuli', 'Hailakandi', 'Karimganj', 'Cachar', 'Karbi Anglong',
      'Dima Hasao', 'Baksa', 'Barpeta', 'Bongaigaon', 'Chirang', 'Dhubri',
      'Darrang', 'Goalpara', 'Golaghat', 'Hojai', 'Jorhat', 'Kamrup',
      'Kamrup Metropolitan', 'Karbi Anglong', 'Kokrajhar', 'Lakhimpur',
      'Majuli', 'Morigaon', 'Nagaon', 'Nalbari', 'Sivasagar', 'Sonitpur',
      'South Salmara', 'Tinsukia',
      
    ];
    cityNames.shuffle();
    final selectedCities = cityNames.take(8).toList(); // Query more to filter for images
    List<Place> allPlaces = [];
    for (final city in selectedCities) {
      final uri = Uri.https(host, '/locations/search', {
        'query': city,
        'limit': '1',
        'offset': '0',
        'units': 'km',
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
        final cities = data.where((p) =>
          p['result_type'] == 'geos' &&
          p['result_object'] != null &&
          p['result_object']['name'] != null &&
          p['result_object']['photo'] != null &&
          p['result_object']['photo']['images'] != null &&
          p['result_object']['photo']['images']['medium'] != null &&
          p['result_object']['photo']['images']['medium']['url'] != null
        ).map<Place>((p) {
          final obj = p['result_object'];
          return Place(
            name: obj['name'] ?? '',
            description: obj['location_string'] ?? '',
            imageUrl: obj['photo']['images']['medium']['url'] ?? '',
            latitude: obj['latitude'] != null ? double.tryParse(obj['latitude'].toString()) : null,
            longitude: obj['longitude'] != null ? double.tryParse(obj['longitude'].toString()) : null,
            address: obj['location_string'] ?? '',
          );
        }).toList();
        allPlaces.addAll(cities);
      }
      if (allPlaces.length >= 4) break;
    }
    allPlaces.shuffle();
    return allPlaces.take(4).toList();
  }

  static Future<String?> fetchNearbyLandmark(double latitude, double longitude) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1&extratags=1&namedetails=1');
    final res = await http.get(url, headers: {
      'User-Agent': 'travel_app/1.0 (your@email.com)',
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      // Try to get a named POI/landmark
      if (data['namedetails'] != null && data['namedetails'] is Map && data['namedetails'].isNotEmpty) {
        // Prefer 'name' or 'official_name' or 'alt_name'
        final nd = data['namedetails'];
        if (nd['name'] != null) return nd['name'];
        if (nd['official_name'] != null) return nd['official_name'];
        if (nd['alt_name'] != null) return nd['alt_name'];
      }
      // Try to get a famous place from extratags
      if (data['extratags'] != null && data['extratags'] is Map && data['extratags'].isNotEmpty) {
        final et = data['extratags'];
        if (et['wikidata'] != null && et['wikidata'].toString().isNotEmpty) {
          // If there's a wikidata tag, it's likely a notable place
          return data['display_name']?.split(',')?.first;
        }
      }
      // Fallback: use the first part of display_name
      if (data['display_name'] != null) {
        return data['display_name'].toString().split(',').first.trim();
      }
    }
    return null;
  }
} 