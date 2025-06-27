import 'dart:convert';
import 'package:http/http.dart' as http;

class Country {
  final String name;
  final String code;

  Country({required this.name, required this.code});
}

class Region {
  final String name;
  final String isoCode;

  Region({required this.name, required this.isoCode});
}

class LocationApiService {
  static const String countriesUrl = 'https://restcountries.com/v3.1/all?fields=name,cca2';
  static const String geoDbBaseUrl = 'http://geodb-free-service.wirefreethought.com';

  // Fetch list of countries
  Future<List<Country>> getCountries() async {
    final response = await http.get(
        Uri.parse(countriesUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<Country> countries = data.map((country) {
        return Country(
          name: country['name']['common'] as String,
          code: country['cca2'] as String, // 2-letter country code
        );
      }).toList();
      countries.sort((a, b) => a.name.compareTo(b.name));
      return countries;
    } else {
      throw Exception('Failed to load countries');
    }
  }

  Future<List<Region>> getRegions(String countryCode) async {
    print("getRegions called");
    List<Region> allRegions = [];
    String? nextUrl = 'http://geodb-free-service.wirefreethought.com/v1/geo/countries/$countryCode/regions?limit=10';

    while (nextUrl != null) {
      final response = await http.get(Uri.parse(nextUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> regions = data['data'];

        allRegions.addAll(
          regions.map((region) => Region(
            name: region['name'] as String,
            isoCode: region['isoCode'] as String,
          )),
        );

        // Look for the "next" link
        final List<dynamic>? links = data['links'];
        final nextLink = links?.firstWhere(
              (link) => link['rel'] == 'next',
          orElse: () => null,
        );
        nextUrl = nextLink != null ? 'http://geodb-free-service.wirefreethought.com${nextLink['href']}' : null;
      } else {
        throw Exception('Failed to load regions');
      }
    }

    allRegions.sort((a, b) => a.name.compareTo(b.name));
    return allRegions;
  }


  // Fetch list of cities for a country code and state code
  Future<List<String>> getCities(String countryCode, String stateIsoCode) async {
    List<String> allCities = [];
    String? nextUrl = 'http://geodb-free-service.wirefreethought.com/v1/geo/countries/$countryCode/regions/$stateIsoCode/cities?limit=10';

    while (nextUrl != null) {
      final response = await http.get(Uri.parse(nextUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> citiesData = data['data'];

        allCities.addAll(
          citiesData.map((city) => city['name'] as String),
        );

        // Safely check if links exist and find the "next" link
        final List<dynamic>? links = data['links'];
        final nextLink = links?.firstWhere(
              (link) => link['rel'] == 'next',
          orElse: () => null,
        );
        nextUrl = nextLink != null ? 'http://geodb-free-service.wirefreethought.com${nextLink['href']}' : null;
      } else {
        throw Exception('Failed to load cities');
      }
    }

    allCities.sort();
    return allCities;
  }


  // Get country code by country name
  Future<String?> getCountryCodeByName(String? countryName) async {
    if (countryName == null) return null;
    final countries = await getCountries();
    try {
      final country = countries.firstWhere((c) => c.name.toLowerCase() == countryName.toLowerCase());
      print("get country by name ${countryName} and the code is ${country.code}");
      return country.code;
    } catch (e) {
      print("Exception: ${e.toString()}");
      return null;
    }
  }

// Get region code by country code and region name
  Future<String?> getRegionCodeByName(String? countryCode, String? regionName) async {
    if (countryCode == null || regionName == null) return null;
    final regions = await getRegions(countryCode);
    try {
      print("get region from ${countryCode}, ${regionName}");
      final region = regions.firstWhere((r) => r.name.toLowerCase() == regionName.toLowerCase());
      return region.isoCode;
    } catch (e) {
      print("Exception: ${e.toString()}");
      return null;
    }
  }
}