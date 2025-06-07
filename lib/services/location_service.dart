import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'location_api_service.dart';

class LocationService {
  static final LocationApiService _apiService = LocationApiService();

  // Get current position using geolocator
  static Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  static Map<String, String> regionNameMapping = {
    "Melaka": "Malacca",
    // Add other languages too if needed
  };

  // Get address from coordinates using geocoding and LocationApiService for codes
  static Future<Map<String, dynamic>> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Fetch country code and region code from API service
        String? countryCode = await _apiService.getCountryCodeByName(place.country);

        String? englishRegionName = regionNameMapping[place.administrativeArea] ?? place.administrativeArea;

        String? regionCode = await _apiService.getRegionCodeByName(countryCode, englishRegionName);

        return {
          'street': place.street,
          'city': place.locality,
          'region': englishRegionName,
          'regionCode': regionCode,
          'country': place.country,
          'countryCode': countryCode,
          'postalCode': place.postalCode,
        };
      }
      return {};
    } catch (e) {
      print('Error in getAddressFromCoordinates: $e');
      return {};
    }
  }

  // Get coordinates from address string
  static Future<Map<String, double>> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }
      return {};
    } catch (e) {
      print('Error in getCoordinatesFromAddress: $e');
      return {};
    }
  }
}

