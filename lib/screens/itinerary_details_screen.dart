import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:travel_guide/services/firestore_service.dart';
import '../models/itinerary_model.dart';
import '../models/user_model.dart';
import '../services/itinerary_service.dart';
import 'edit_itinerary_screen.dart';

class ItineraryDetailsScreen extends StatefulWidget {
  final ItineraryModel itinerary;
  final UserModel currentUser;

  const ItineraryDetailsScreen({
    super.key,
    required this.itinerary,
    required this.currentUser,
  });

  @override
  State<ItineraryDetailsScreen> createState() => _ItineraryDetailsScreenState();
}

class _ItineraryDetailsScreenState extends State<ItineraryDetailsScreen> {
  final _itineraryService = ItineraryService();
  bool _isLiked = false;
  bool _isLoading = false;
  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.itinerary.isLikedBy(widget.currentUser.uid);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleLike() async {
    setState(() => _isLoading = true);
    try {
      await _itineraryService.toggleLikeItinerary(
        itineraryId: widget.itinerary.id,
        userId: widget.currentUser.uid,
      );

      _isLiked = !_isLiked;
    } catch (e) {
      if (mounted) {
        print('error happened');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditItineraryScreen(
          itinerary: widget.itinerary,
          currentUser: widget.currentUser,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Itinerary'),
        content: const Text('Are you sure you want to delete this itinerary?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _itineraryService.deleteItinerary(widget.itinerary.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCopy() async {
    setState(() => _isLoading = true);
    try {
      final newItineraryData = widget.itinerary.toFirestore();
      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid);
      newItineraryData['author'] = userRef;
      newItineraryData['createdAt'] = FieldValue.serverTimestamp();
      newItineraryData['updatedAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance.collection('itineraries').add(newItineraryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itinerary copied successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to copy itinerary: $e')),
        );
        print('Failed to copy itinerary: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    IconData statusIcon;

    switch (widget.itinerary.status) {
      case 'completed':
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        backgroundColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        statusIcon = Icons.directions_run;
        break;
      case 'cancelled':
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        statusIcon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            widget.itinerary.status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    // Check if there's a valid image to display
    return Stack(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.7),
                Theme.of(context).primaryColor,
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.landscape,
              size: 80,
              color: Colors.white70,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String content) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (widget.itinerary.description.length > 100)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showFullDescription = !_showFullDescription;
                      });
                    },
                    child: Text(_showFullDescription ? 'Show Less' : 'Show More'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _showFullDescription || widget.itinerary.description.length <= 100
                  ? widget.itinerary.description
                  : '${widget.itinerary.description.substring(0, 100)}...',
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    if (widget.itinerary.tags.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tag, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.itinerary.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorSection() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Text(
                widget.itinerary.author.displayName?.substring(0, 1).toUpperCase() ??
                    widget.itinerary.author.email.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.itinerary.author.displayName ?? widget.itinerary.author.email,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Created on ${_formatDate(widget.itinerary.createdAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.itinerary.likeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 18,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.itinerary.likeCount.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildPlacesListGroupedByDay(List<Map<String, dynamic>> places) {
    if (places.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No places added to this itinerary.'),
          ),
        ),
      );
    }

    final Map<int, List<Map<String, dynamic>>> placesByDay = {};
    for (var place in places) {
      final day = place['day'] ?? 1;
      placesByDay.putIfAbsent(day, () => []).add(place);
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.map, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Places to Visit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...placesByDay.entries.map((entry) {
              final day = entry.key;
              final dayPlaces = entry.value;
              return Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  title: Text(
                    'Day $day',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  initiallyExpanded: day == 1,
                  children: dayPlaces.map((place) {
                    return ListTile(
                      contentPadding: const EdgeInsets.only(left: 72, right: 16),
                      title: Text(
                        place['name'] ?? 'Unnamed Place',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(place['location']?['city'] ?? ''),
                      leading: const Icon(Icons.place, size: 20),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.itinerary.author.uid == widget.currentUser.uid;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderImage(),
              title: Text(
                widget.itinerary.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              titlePadding: const EdgeInsets.only(left: 72, right: 16, bottom: 16),
              centerTitle: false,
            ),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _handleEdit,
                ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _handleDelete,
                ),
              if (!isOwner)
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white),
                tooltip: 'Copy Itinerary',
                onPressed: _isLoading ? null : _handleCopy,
              ),
              IconButton(
                icon: Icon(
                  _isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: _isLiked
                      ? Colors.red[300]
                      : Colors.white,
                ),
                onPressed: _isLoading ? null : _handleLike,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.location_on,
                          'LOCATION',
                          widget.itinerary.location,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.calendar_today,
                          'DATES',
                          '${_formatDate(widget.itinerary.startDate)} - ${_formatDate(widget.itinerary.endDate)}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildStatusChip(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDescriptionSection(),
                  const SizedBox(height: 16),
                  _buildTagsSection(),
                  const SizedBox(height: 16),
                  _buildAuthorSection(),
                  const SizedBox(height: 16),
                  // Assuming you have places data to show
                  buildPlacesListGroupedByDay(widget.itinerary.places ?? []),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}