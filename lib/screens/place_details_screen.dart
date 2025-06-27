import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_guide/screens/saved_place_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> place;
  final Map<String, dynamic> details;

  const PlaceDetailsScreen({
    Key? key,
    required this.place,
    required this.details,
  }) : super(key: key);

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  Set<String> _savedPlaceNames = {};

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
  }

  Future<void> _initializeCurrentUser() async {
    await _authService.initializeCurrentUser();
    final user = _authService.currentUser;
    print('user: $user');
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
    if (_currentUser  != null) {
      await _loadSavedPlaces();
    }
  }

  Future<void> _loadSavedPlaces() async {

    if (_currentUser == null)  {
      print('there is no current user');
      return;
    }
    try {
      final savedPlaces = await _firestoreService.getSavedPlacesForUser(_currentUser!.uid);
      if (mounted) {
        setState(() {
          _savedPlaceNames = savedPlaces.map((place) => place['name'] as String).toSet();
        });
      }

      if (savedPlaces.isEmpty) {
        print("not saved places found");
      }
      else {
        print("saved places: $_savedPlaceNames");
      }
    } catch (e) {
      print('Error loading saved places: $e');
    }
  }

  Future<void> _toggleSavePlace(Map<String, dynamic> place) async {
    final l10n = AppLocalizations.of(context)!;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginToSavePlace)),
      );
      return;
    }
    final placeName = place['name'] as String;
    final isSaved = _savedPlaceNames.contains(placeName);

    try {
      if (isSaved) {
        await _firestoreService.removeSavedPlaceForUser(_currentUser!.uid, placeName);
        setState(() {
          _savedPlaceNames.remove(placeName);
        });
      } else {
        await _firestoreService.savePlaceForUser(_currentUser!.uid, place);
        setState(() {
          _savedPlaceNames.add(placeName);
        });
      }
    } catch (e) {
      print('Error toggling save place: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failUpdateSavedPlaces)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final places = widget.details['places'] as List<dynamic>? ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.place['name'] ?? l10n.placeDetails,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black54,
                      offset: Offset(1.0, 1.0),
                    )
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: widget.place['image'] != null
                  ? Image.network(
                widget.place['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                },
              )
                  : Container(color: Colors.grey[300]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildLocationInfo(context),
                const SizedBox(height: 16),
                Divider(
                  color: Colors.grey[300],
                  thickness: 1.5,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.recommendedAttractionAndFood,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                if (places.isEmpty)
                  _buildEmptyRecommendationsWidget(context)
                else
                  _buildRecommendationsList(places, context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.place['location']?['city'] ?? ''}, ${widget.place['location']?['state'] ?? ''}, ${widget.place['location']?['country'] ?? ''}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRecommendationsWidget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.noRecommendation,
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildRecommendationsList(List<dynamic> places, BuildContext context) {
  //   return ListView.separated(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     itemCount: places.length,
  //     separatorBuilder: (_, __) => const SizedBox(height: 12),
  //     itemBuilder: (context, index) {
  //       final p = places[index];
  //       final isSaved = _savedPlaceNames.contains(p['name']);
  //       return Card(
  //         elevation: 3,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: ListTile(
  //           title: Text(
  //             p['name'] ?? '',
  //             style: Theme.of(context).textTheme.titleMedium?.copyWith(
  //               fontWeight: FontWeight.bold,
  //               color: Theme.of(context).primaryColor,
  //             ),
  //           ),
  //           subtitle: Text(p['address'] ?? ''),
  //           trailing: IconButton(
  //             icon: Icon(
  //               isSaved ? Icons.bookmark : Icons.bookmark_border,
  //               color: isSaved ? Colors.yellow[700] : null,
  //             ),
  //             onPressed: () => _toggleSavePlace(p),
  //             tooltip: isSaved ? 'Remove from saved' : 'Save place',
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildRecommendationsList(List<dynamic> places, BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: places.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = places[index];
        final isSaved = _savedPlaceNames.contains(p['name']);
        return GestureDetector(
          onTap: () {
            // Navigate to the details screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SavedPlaceDetailsScreen(place: p), // Replace with your destination screen
              ),
            );
          },
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                p['name'] ?? '',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              subtitle: Text(p['address'] ?? ''),
              trailing: IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? Colors.yellow[700] : null,
                ),
                onPressed: () => _toggleSavePlace(p),
                tooltip: isSaved ? 'Remove from saved' : 'Save place',
              ),
            ),
          ),
        );
      },
    );
  }
}