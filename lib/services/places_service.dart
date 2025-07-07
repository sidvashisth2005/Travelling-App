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
          );
        }).toList();
        allPlaces.addAll(cities);
      }
      if (allPlaces.length >= 4) break;
    }
    allPlaces.shuffle();
    return allPlaces.take(4).toList();
  }
} 