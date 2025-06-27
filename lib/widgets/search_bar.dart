import 'package:flutter/material.dart';
import '../services/location_api_service.dart';
import '../services/place_recommendation_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlaceSearchBar extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onSearchResults;

  const PlaceSearchBar({Key? key, required this.onSearchResults}) : super(key: key);

  @override
  _PlaceSearchBarState createState() => _PlaceSearchBarState();
}

class _PlaceSearchBarState extends State<PlaceSearchBar> {
  final LocationApiService _locationApiService = LocationApiService();

  List<Country> _countries = [];
  List<Region> _regions = [];

  Country? _selectedCountry;
  Region? _selectedRegion;

  bool _isLoadingRegions = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await _locationApiService.getCountries();
      setState(() {
        _countries = countries;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onCountrySelected(Country? country) async {
    setState(() {
      _selectedCountry = country;
      _selectedRegion = null;
      _regions = [];
    });
    if (country != null) {
      setState(() {
        _isLoadingRegions = true;
      });
      try {
        final regions = await _locationApiService.getRegions(country.code);
        setState(() {
          _regions = regions;
        });
      } catch (e) {
        // Handle error
      } finally {
        setState(() {
          _isLoadingRegions = false;
        });
      }
    }
  }

  Future<void> _search() async {
    if (_selectedCountry == null || _selectedRegion == null) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await PlaceRecommendationService.getRecommendedPlacesByCountryAndRegion(_selectedCountry!.name, _selectedRegion!.name,
      );
      widget.onSearchResults(results);
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView( // Allow scrolling if content overflows
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Add some padding for better layout
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make children take full width
          children: [
            // Wrap the dropdown in a Container to enforce proper constraints
            DropdownButtonFormField<Country>(
              isExpanded: true, // This is crucial - makes dropdown use available width
              decoration: InputDecoration(
                labelText: l10n.selectCountry,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _countries
                  .map((c) => DropdownMenuItem(
                value: c,
                child: Text(
                  c.name,
                  overflow: TextOverflow.ellipsis, // Handle text overflow
                ),
              ))
                  .toList(),
              value: _selectedCountry,
              onChanged: _onCountrySelected,
            ),
            const SizedBox(height: 16),
            _isLoadingRegions
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<Region>(
              isExpanded: true, // This is crucial - makes dropdown use available width
              decoration: InputDecoration(
                labelText: l10n.selectRegion,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _regions
                  .map((r) => DropdownMenuItem(
                value: r,
                child: Text(
                  r.name,
                  overflow: TextOverflow.ellipsis, // Handle text overflow
                ),
              ))
                  .toList(),
              value: _selectedRegion,
              onChanged: (region) {
                setState(() {
                  _selectedRegion = region;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48, // Fixed height for button
              child: ElevatedButton(
                onPressed: _isSearching ? null : _search, // Fixed typo: *search -> _search
                child: _isSearching
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  l10n.search,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}