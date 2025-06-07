import 'package:flutter/material.dart';
import '../models/itinerary_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/itinerary_service.dart';
import '../widgets/itinerary_card.dart';
import 'edit_itinerary_screen.dart';
import 'itinerary_details_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final _itineraryService = ItineraryService();
  final _authService = AuthService();
  String _selectedFilter = 'all';
  UserModel? _currentUser;

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
  }

  Future<void> _createNewItinerary() async {
    if (_currentUser == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditItineraryScreen(
          currentUser: _currentUser!,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _viewItineraryDetails(ItineraryModel itinerary) async {
    if (_currentUser == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItineraryDetailsScreen(
          itinerary: itinerary,
          currentUser: _currentUser!,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view your trips'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewItinerary,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Planned', 'planned'),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', 'in_progress'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed'),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled', 'cancelled'),
              ],
            ),
          ),

          // Itineraries List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _itineraryService.getItinerariesByUser(_currentUser!.uid),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_travel,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No trips yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start planning your next adventure!',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _createNewItinerary,
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Trip'),
                        ),
                      ],
                    ),
                  );
                }

                // Filter itineraries based on selected filter
                final filteredItineraries = _selectedFilter == 'all'
                    ? itineraries
                    : itineraries.where((i) => i['status'] == _selectedFilter).toList();

                if (filteredItineraries.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${_selectedFilter.replaceAll('_', ' ')} trips found',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItineraries.length,
                  itemBuilder: (context, index) {
                    final itineraryData = filteredItineraries[index];
                    final itinerary = ItineraryModel.fromFirestore(
                      itineraryData,
                      itineraryData['id'],
                      _currentUser!,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ItineraryCard(
                        itinerary: itinerary,
                        showAuthor: false,
                        isDetailed: true,
                        onTap: () => _viewItineraryDetails(itinerary),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewItinerary,
        child: const Icon(Icons.add),
      ),
    );
  }
}