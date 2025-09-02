import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'saved_place_details_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SavedPlacesScreen extends StatefulWidget {
  final bool selectMode; // Enable multi-selection mode when true

  const SavedPlacesScreen({Key? key, this.selectMode = false}) : super(key: key);

  @override
  _SavedPlacesScreenState createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;

  List<Map<String, dynamic>> _savedPlaces = [];
  List<Map<String, dynamic>> _filteredPlaces = [];
  bool _isLoading = true;
  String? _selectedCountry;

  Set<int> _selectedIndices = {}; // For multi-selection

  Set<String> _countries = {}; // This will hold the unique countries extracted from saved places

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
  }

  Future<void> _initializeCurrentUser() async {
    await _authService.initializeCurrentUser();
    final user = _authService.currentUser;
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
    if (_currentUser != null) {
      await _loadSavedPlaces();
    }
  }

  Future<void> _loadSavedPlaces() async {
    if (_currentUser == null) return;
    try {
      final places = await _firestoreService.getSavedPlacesForUser(_currentUser!.uid);
      if (mounted) {
        setState(() {
          _savedPlaces = places;
          _filteredPlaces = places; // Initialize filtered places
          _isLoading = false;

          // Extract unique countries from the addresses
          _extractCountries();

          // If a country is selected, filter the places
          if (_selectedCountry != null) {
            _filterPlacesByCountry(_selectedCountry);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshPlaces() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    await _loadSavedPlaces();

    // After loading saved places, check if a country is selected
    if (_selectedCountry != null) {
      _filterPlacesByCountry(_selectedCountry); // Filter places based on the selected country
    }
  }

  void _extractCountries() {
    _countries.clear(); // Clear previous countries
    for (var place in _savedPlaces) {
      final address = place['address'] ?? '';
      final country = address.split(',').last.trim(); // Get the last part of the address
      _countries.add(country); // Add to the set of countries
    }
  }

  void _filterPlacesByCountry(String? country) {
    if (country == null || country.isEmpty) {
      setState(() {
        _filteredPlaces = _savedPlaces; // Show all places if no country is selected
      });
      return;
    }

    setState(() {
      _filteredPlaces = _savedPlaces.where((place) {
        final address = place['address'] ?? '';
        return address.split(',').last.trim() == country; // Check if the last part of the address matches the country
      }).toList();
    });
  }

  // Widget _buildCountryDropdown() {
  //   return DropdownButton<String>(
  //     value: _selectedCountry,
  //     hint: const Text('Select Country'),
  //     onChanged: (String? newValue) {
  //       setState(() {
  //         _selectedCountry = newValue;
  //         _filterPlacesByCountry(newValue); // Filter places when country is selected
  //       });
  //     },
  //     items: _countries.map<DropdownMenuItem<String>>((String country) {
  //       return DropdownMenuItem<String>(
  //         value: country,
  //         child: Text(country),
  //       );
  //     }).toList(),
  //   );
  // }

  Widget _buildCountryDropdown() {
    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: DropdownButton<String>(
        value: _selectedCountry,
        hint: Text(
          'Select Country',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        iconSize: 20,
        elevation: 8,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        underline: Container(), // Remove default underline
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        onChanged: (String? newValue) {
          setState(() {
            _selectedCountry = newValue;
            _filterPlacesByCountry(newValue);
          });
        },
        selectedItemBuilder: (BuildContext context) {
          return _countries.map<Widget>((String country) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      country,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        },
        items: _countries.map<DropdownMenuItem<String>>((String country) {
          return DropdownMenuItem<String>(
            value: country,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      country,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          l10n.savedPlaces,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (widget.selectMode)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                final selectedPlaces = _selectedIndices.map((i) => _savedPlaces[i]).toList();
                Navigator.pop(context, selectedPlaces);
              },
              tooltip: 'Confirm Selection',
            ),
          _buildCountryDropdown(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPlaces,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredPlaces.isEmpty) {
      return _buildEmptyState();
    }

    // return RefreshIndicator(
    //   onRefresh: _refreshPlaces,
    //   child: Padding(
    //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    //     child: ListView.builder(
    //       physics: const AlwaysScrollableScrollPhysics(),
    //       itemCount: _savedPlaces.length,
    //       itemBuilder: (context, index) {
    //         return _buildPlaceCard(_savedPlaces[index], index);
    //       },
    //     ),
    //   ),
    // );
    return RefreshIndicator(
      onRefresh: _loadSavedPlaces,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _filteredPlaces.length,
          itemBuilder: (context, index) {
            return _buildPlaceCard(_filteredPlaces[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noSavedPlaces,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.favoriteLocations,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshPlaces,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.refresh),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place, int index) {
    final l10n = AppLocalizations.of(context)!;

    final placeType = place['type'] ?? l10n.location;
    final IconData categoryIcon = _getCategoryIcon(placeType);
    final Color categoryColor = _getCategoryColor(placeType);

    final bool isSelected = widget.selectMode && _selectedIndices.contains(index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (widget.selectMode) {
              setState(() {
                if (isSelected) {
                  _selectedIndices.remove(index);
                } else {
                  _selectedIndices.add(index);
                }
              });
            } else {
              // Navigate to place details screen or other action
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedPlaceDetailsScreen(
                    place: place,
                  ),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.selectMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedIndices.add(index);
                            } else {
                              _selectedIndices.remove(index);
                            }
                          });
                        },
                      ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        categoryIcon,
                        color: categoryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place['name'] ?? l10n.unnamedPlace,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  place['address'] ?? l10n.noAddressAvailable,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (place['notes'] != null && place['notes'].isNotEmpty)
                            Text(
                              place['notes'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (!widget.selectMode)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red[400],
                        onPressed: () {
                          _showDeleteConfirmation(place);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.coffee;
      case 'hotel':
        return Icons.hotel;
      case 'shopping':
        return Icons.shopping_bag;
      case 'attraction':
        return Icons.attractions;
      case 'work':
        return Icons.work;
      case 'home':
        return Icons.home;
      default:
        return Icons.place;
    }
  }

  Color _getCategoryColor(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return Colors.orange;
      case 'cafe':
        return Colors.brown;
      case 'hotel':
        return Colors.blue;
      case 'shopping':
        return Colors.purple;
      case 'attraction':
        return Colors.green;
      case 'work':
        return Colors.indigo;
      case 'home':
        return Colors.teal;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> place) async {
    final l10n = AppLocalizations.of(context)!;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.removePlace),
          content: Text('${l10n.removeConfirm1} ${place['name']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _firestoreService.removeSavedPlaceForUser (_currentUser !.uid, place['name']);
                await _refreshPlaces();

                // Check if the deleted place was the last one in the filtered list
                if (_selectedCountry != null) {
                  // Get the remaining places for the selected country
                  final remainingPlaces = _filteredPlaces.where((p) {
                    final address = p['address'] ?? '';
                    return address.split(',').last.trim() == _selectedCountry;
                  }).toList();

                  // If no remaining places, reset the selected country
                  if (remainingPlaces.isEmpty) {
                    setState(() {
                      _selectedCountry = null; // Reset to null if the selected country is deleted
                      _filteredPlaces = _savedPlaces; // Show all places
                    });
                  } else {
                    // If there are remaining places, keep the filter
                    setState(() {
                      _filteredPlaces = remainingPlaces; // Update filtered places
                    });
                  }
                }
              },
              child: const Text(
                'REMOVE',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}