import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/saved_place_details_screen.dart';

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
  bool _isLoading = true;

  Set<int> _selectedIndices = {}; // For multi-selection

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
          _isLoading = false;
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Saved Places',
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

    if (_savedPlaces.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshPlaces,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _savedPlaces.length,
          itemBuilder: (context, index) {
            return _buildPlaceCard(_savedPlaces[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'No saved places yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your favorite locations will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshPlaces,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
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
    final placeType = place['type'] ?? 'location';
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
                            place['name'] ?? 'Unnamed Place',
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
                                  place['address'] ?? 'No address available',
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
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Place'),
          content: Text(
              'Are you sure you want to remove "${place['name']}" from your saved places?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _firestoreService.removeSavedPlaceForUser(_currentUser!.uid, place['name']);
                await _refreshPlaces();
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