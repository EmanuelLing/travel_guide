import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';

class PlaceRecommendationService {
  static const String _baseUrl = 'https://restcountries.com/v3.1';
  static const String _geoNamesBaseUrl = 'http://api.geonames.org';
  static const String _geoNamesUsername = 'linghaoen'; // Replace with your GeoNames username
  static const String _pexelsBaseUrl = 'https://api.pexels.com/v1';
  static const String _pexelsApiKey = 'gO83Pt6ahfVQ7UxoKDdbjehQwKpbmNEMuaK6hyVOFO34HEpjyYAmmAYy'; // Replace with your Pexels API key
  static const String _geoapifyApiKey = 'aefe51ff2fe64068912182fde2f21e58'; // Replace with your Geoapify API key
  static const String _geoapifyPlacesUrl = 'https://api.geoapify.com/v2/places';

  // Simple in-memory cache for place recommendations keyed by country
  static final Map<String, List<Map<String, dynamic>>> _cache = {};

  // Limit number of places fetched to improve performance
  static const int _maxPlaces = 20;

  // Get recommended places based on user's location using GeoNames API with caching and limiting
  static Future<List<Map<String, dynamic>>> getRecommendedPlaces(UserModel user) async {
    try {
      if (user.country != null && _cache.containsKey(user.country)) {
        // Return cached data if available
        return _cache[user.country]!;
      }

      List<Map<String, dynamic>> recommendations = [];
      String targetRegion = 'Asia'; // Default region
      String? targetCountryCode;

      if (user.country != null) {
        final countryResponse = await http.get(
          Uri.parse('$_baseUrl/name/${user.country}'),
        );

        if (countryResponse.statusCode == 200) {
          final List<dynamic> countryData = json.decode(countryResponse.body);
          targetRegion = countryData[0]['region'];
          targetCountryCode = countryData[0]['cca2'];
        }
      }

      if (targetCountryCode != null) {
        final geoNamesResponse = await http.get(
          Uri.parse('$_geoNamesBaseUrl/searchJSON?country=$targetCountryCode&featureClass=P&maxRows=$_maxPlaces&username=$_geoNamesUsername'),
        );

        if (geoNamesResponse.statusCode == 200) {
          final geoData = json.decode(geoNamesResponse.body);
          final List<dynamic> geoNames = geoData['geonames'];

          for (var place in geoNames) {
            final imageUrl = await _fetchPlaceImage(place['name']);

            recommendations.add({
              'name': place['name'],
              'description': place['fcodeName'] ?? 'Place',
              'type': place['fcodeName'] ?? 'Place',
              'location': {
                'city': place['name'],
                'state': place['adminName1'] ?? '',
                'country': user.country ?? '',
              },
              'latitude': place['lat'],
              'longitude': place['lng'],
              'image': imageUrl,
            });
          }
        }
      }

      if (recommendations.isEmpty) {
        final response = await http.get(Uri.parse('$_baseUrl/region/$targetRegion'));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          return [];
        }
      }

      recommendations = _sortByLocationRelevance(
        recommendations,
        user.country,
        user.region,
        user.city,
      );

      // Cache the recommendations
      if (user.country != null) {
        _cache[user.country!] = recommendations;
      }

      return recommendations;
    } catch (e) {
      print('Error getting recommended places: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getRecommendedPlacesByCountryAndRegion(String country, String region) async {
    try {
      List<Map<String, dynamic>> recommendations = [];
      String? targetCountryCode;

      // Fetch country code based on the provided country name
      final countryResponse = await http.get(
        Uri.parse('$_baseUrl/name/$country'),
      );

      if (countryResponse.statusCode == 200) {
        final List<dynamic> countryData = json.decode(countryResponse.body);
        targetCountryCode = countryData[0]['cca2'];
      }

      if (targetCountryCode != null) {
        // Fetch places based on the country code and region
        final geoNamesResponse = await http.get(
          Uri.parse('$_geoNamesBaseUrl/searchJSON?country=$targetCountryCode&featureClass=P&maxRows=$_maxPlaces&username=$_geoNamesUsername'),
        );

        if (geoNamesResponse.statusCode == 200) {
          final geoData = json.decode(geoNamesResponse.body);
          final List<dynamic> geoNames = geoData['geonames'];

          List<dynamic> filteredPlaces = geoNames.where((place) {
            final state = place['adminName1'] ?? '';
            return region.toLowerCase() == state.toString().toLowerCase();
          }).toList();

          for (var place in filteredPlaces) {
            final imageUrl = await _fetchPlaceImage(place['name']);

            recommendations.add({
              'name': place['name'],
              'description': place['fcodeName'] ?? 'Place',
              'type': place['fcodeName'] ?? 'Place',
              'location': {
                'city': place['name'],
                'state': place['adminName1'] ?? '',
                'country': country,
              },
              'latitude': place['lat'],
              'longitude': place['lng'],
              'image': imageUrl,
            });
          }
        }
      }

      if (recommendations.isEmpty) {
        // If no recommendations found, fetch by region
        final response = await http.get(Uri.parse('$_baseUrl/region/$region'));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          // Process the data if needed
        }
      }

      // Sort recommendations by location relevance if needed
      recommendations = _sortByLocationRelevance(
        recommendations,
        country,
        region,
        null, // You can pass city if needed
      );

      // Cache the recommendations
      if (country != null) {
        _cache[country] = recommendations;
      }

      return recommendations;
    } catch (e) {
      print('Error getting recommended places by country and region: $e');
      return [];
    }
  }

  static Future<String> _fetchPlaceImage(String placeName) async {
    const String defaultImageUrl = 'https://static.vecteezy.com/system/resources/previews/022/014/063/original/missing-picture-page-for-website-design-or-mobile-app-design-no-image-available-icon-vector.jpg'; // Replace with your default image URL
    try {
      final response = await http.get(
        Uri.parse('$_pexelsBaseUrl/search?query=$placeName&per_page=1'),
        headers: {
          'Authorization': _pexelsApiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photos = data['photos'];
        if (photos != null && photos.isNotEmpty) {
          return photos[0]['src']['medium'] ?? defaultImageUrl;
        }
      }
      return defaultImageUrl;
    } catch (e) {
      print('Error fetching image for $placeName: $e');
      return defaultImageUrl;
    }
  }

  static List<Map<String, dynamic>> _sortByLocationRelevance(
      List<Map<String, dynamic>> places,
      String? userCountry,
      String? userRegion,
      String? userCity,
      ) {
    return places..sort((a, b) {
      if (userCountry == null) return 0;

      final aLocation = a['location'];
      final bLocation = b['location'];

      int aScore = 0;
      int bScore = 0;

      if (aLocation['country'] == userCountry) aScore += 100;
      if (bLocation['country'] == userCountry) bScore += 100;

      if (userRegion != null) {
        if (aLocation['state'] == userRegion) aScore += 10;
        if (bLocation['state'] == userRegion) bScore += 10;
      }

      if (userCity != null) {
        if (aLocation['city'] == userCity) aScore += 1;
        if (bLocation['city'] == userCity) bScore += 1;
      }

      return bScore.compareTo(aScore);
    });
  }

  static Future<Map<String, dynamic>> getPlaceDetails(String placeName, String countryName) async {
    try {
      final countryResponse = await http.get(
        Uri.parse('$_baseUrl/name/$countryName?fullText=true'),
      );

      if (countryResponse.statusCode == 200) {
        final List<dynamic> countryData = json.decode(countryResponse.body);
        final country = countryData[0];

        return {
          'name': placeName,
          'country': countryName,
          'countryDetails': {
            'capital': country['capital']?[0] ?? 'Unknown',
            'region': country['region'],
            'subregion': country['subregion'],
            'population': country['population'],
            'languages': country['languages'] ?? {},
            'currencies': country['currencies'] ?? {},
            'flag': country['flags']['png'],
            'timezones': country['timezones'] ?? [],
          },
        };
      }
      throw Exception('Failed to load place details');
    } catch (e) {
      print('Error getting place details: $e');
      return {};
    }
  }

  // New method to fetch place details including attractions, foods, etc.
  static Future<Map<String, dynamic>> getPlaceDetailsGeoapify(double lat, double lon) async {
    try {
      final url = Uri.parse(
          '$_geoapifyPlacesUrl?categories=tourism.sights,catering.restaurant&filter=circle:$lon,$lat,5000&limit=20&apiKey=$_geoapifyApiKey'
      );
      final response = await http.get(url);

      print('status from geoapify api: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>? ?? [];

        List<Map<String, dynamic>> places = [];

        for (var feature in features) {
          final props = feature['properties'] ?? {};
          places.add({
            'name': props['name'] ?? 'Unknown',
            'address': props['formatted'] ?? '',
            'categories': props['categories'] ?? [],
            'phone': props['contact']?['phone'] ?? '',
            'email': props['contact']?['email'] ?? '',
            'website': props['website'] ?? '',
            'opening_hours': props['opening_hours'] ?? '',
            'facilities': props['facilities'] ?? {},
          });
        }

        return {
          'places': places,
        };
      }
      return {};
    } catch (e) {
      print('Error fetching place details from Geoapify: $e');
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    // Implement API call to search places by query, e.g., using Geoapify or GeoNames
    // Return list of place maps matching the query
    // For example, using Geoapify Places API:
    final url = Uri.parse('https://api.geoapify.com/v2/places?text=$query&limit=20&apiKey=$_geoapifyApiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data['features'] as List<dynamic>? ?? [];
      return features.map((feature) {
        final props = feature['properties'] ?? {};
        return {
          'name': props['name'],
          'location': {
            'city': props['city'] ?? '',
            'state': props['state'] ?? '',
            'country': props['country'] ?? '',
          },
          'latitude': props['lat'],
          'longitude': props['lon'],
          'image': props['image'] ?? '',
        };
      }).toList();
    }
    return [];
  }
}