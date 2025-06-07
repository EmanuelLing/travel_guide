import 'package:flutter/material.dart';
import 'package:travel_guide/screens/place_details_screen.dart';
import 'package:travel_guide/services/itinerary_service.dart';
import '../models/itinerary_model.dart';
import '../services/place_recommendation_service.dart';
import '../widgets/search_bar.dart';
import '../widgets/itinerary_card.dart';
import '../widgets/recommended_places.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      await _authService.initializeCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = _authService.currentUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error initializing user: $e');
    }
  }

  void _handleSearchResults(List<Map<String, dynamic>> results) {
    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _initializeUser,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome and Search Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome${_currentUser?.displayName != null ? ', ${_currentUser!.displayName}' : ''}!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PlaceSearchBar(onSearchResults: _handleSearchResults),
                      const SizedBox(height: 16),

                      // Search Results Section - FIX: Specify a fixed height for ListView
                      _searchResults.isEmpty
                          ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Text('No search results'),
                        ),
                      )
                          : Container(
                        height: 300, // Fixed height constraint
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true, // Important
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(8),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final place = _searchResults[index];
                            return buildPlaceCard(place);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Itineraries Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'See Other Itineraries',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 150,
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: ItineraryService().getItinerariesExceptUserStream(_currentUser!.uid),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final itineraries = snapshot.data ?? [];

                            if (itineraries.isEmpty) {
                              return const Center(
                                child: Text('No itineraries found'),
                              );
                            }

                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: itineraries.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final itineraryData = itineraries[index];
                                final itinerary = ItineraryModel.fromFirestore(
                                  itineraryData,
                                  itineraryData['id'],
                                  itineraryData['author'],
                                );
                                return SizedBox(
                                  width: 280,
                                  child: ItineraryCard(
                                    itinerary: itinerary,
                                    showAuthor: false,
                                    isDetailed: true,
                                    currentUser: _currentUser!,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // You might also like Section with Recommended Places
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Recommended Places based on location
                      const Text(
                        'Recommended Places',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_currentUser != null)
                        RecommendedPlaces(user: _currentUser!)
                      else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Sign in to see personalized recommendations',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPlaceCard(Map<String, dynamic> place) {
    final location = place['location'] ?? {};
    final countryFlag = place['countryFlag'] ?? '';
    final attractionsCount = place['attractions'] != null ? (place['attractions'] as List).length : 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to place details screen or handle tap
          _navigateToPlaceDetails(place);
        },
        child: SizedBox(
          width: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.network(
                    place['image'] ?? '',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      );
                    },
                  ),
                  if (countryFlag.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.network(
                            countryFlag,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.flag, size: 16);
                            },
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${location['city'] ?? ''}, ${location['country'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place['description'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          place['type'] == 'City' ? Icons.location_city : Icons.landscape,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: Text(
                            place['type'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '$attractionsCount attractions',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  void _navigateToPlaceDetails(Map<String, dynamic> place) async {
    final lat = double.tryParse(place['latitude']?.toString() ?? '') ?? 0.0;
    final lon = double.tryParse(place['longitude']?.toString() ?? '') ?? 0.0;

    final details = await PlaceRecommendationService.getPlaceDetailsGeoapify(lat, lon);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceDetailsScreen(
          place: place,
          details: details,
        ),
      ),
    );
  }
}
