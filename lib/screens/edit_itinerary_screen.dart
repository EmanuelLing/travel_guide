import 'package:flutter/material.dart';
import 'package:travel_guide/screens/saved_places_screen.dart';
import '../models/itinerary_model.dart';
import '../models/user_model.dart';
import '../services/itinerary_service.dart';

class EditItineraryScreen extends StatefulWidget {
  final ItineraryModel? itinerary;
  final UserModel currentUser;

  const EditItineraryScreen({
    super.key,
    this.itinerary,
    required this.currentUser,
  });

  @override
  State<EditItineraryScreen> createState() => _EditItineraryScreenState();
}

class _EditItineraryScreenState extends State<EditItineraryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'planned';
  bool _isLoading = false;
  final _itineraryService = ItineraryService();

  List<Map<String, dynamic>> _places = [];
  int _selectedDay = 1;

  @override
  void initState() {
    super.initState();
    if (widget.itinerary != null) {
      _initializeWithExistingItinerary();
    }
  }

  void _initializeWithExistingItinerary() {
    final itinerary = widget.itinerary!;

    // Fill in text controllers
    _titleController.text = itinerary.title;
    _descriptionController.text = itinerary.description;
    _locationController.text = itinerary.location;

    // Fill in dates
    _startDate = itinerary.startDate;
    _endDate = itinerary.endDate;

    // Fill in status
    _status = itinerary.status;

    // Fill in tags
    if (itinerary.tags.isNotEmpty) {
      _tagsController.text = itinerary.tags.join(', ');
    }

    // Fill in places
    _places = itinerary.places != null
        ? List<Map<String, dynamic>>.from(itinerary.places)
        : [];

    // Set selected day to the first day or 1 if no places
    if (_places.isNotEmpty) {
      final firstPlaceDay = _places.first['day'] ?? 1;
      _selectedDay = firstPlaceDay;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: isStartDate ? DateTime.now() : (_startDate ?? DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  int get itineraryDurationInDays {
    if (_startDate == null || _endDate == null) return 1;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  List<String> _processTags(String tagsString) {
    return tagsString
        .split(',')
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  void _addPlace(Map<String, dynamic> place) {
    final placeWithDay = {
      ...place,
      'day': _selectedDay,
    };
    setState(() {
      _places.add(placeWithDay);
    });
  }

  void _removePlace(int index) {
    setState(() {
      _places.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final additionalData = {
        'places': _places,
      };

      if (widget.itinerary == null) {
        await _itineraryService.createItinerary(
          userId: widget.currentUser.uid,
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          startDate: _startDate!,
          endDate: _endDate!,
          tags: _processTags(_tagsController.text),
          additionalData: additionalData,
        );
      } else {
        await _itineraryService.updateItinerary(
          itineraryId: widget.itinerary!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          startDate: _startDate,
          endDate: _endDate,
          tags: _processTags(_tagsController.text),
          status: _status,
          additionalData: additionalData,
        );
      }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itinerary == null ? 'Create Itinerary' : 'Edit Itinerary'),
        actions: [
          if (widget.itinerary != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() => _status = value);
              },
              initialValue: _status,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'planned',
                  child: Text('Planned'),
                ),
                const PopupMenuItem(
                  value: 'in_progress',
                  child: Text('In Progress'),
                ),
                const PopupMenuItem(
                  value: 'completed',
                  child: Text('Completed'),
                ),
                const PopupMenuItem(
                  value: 'cancelled',
                  child: Text('Cancelled'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(
                        _startDate == null
                            ? 'Not selected'
                            : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                      ),
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(
                        _endDate == null
                            ? 'Not selected'
                            : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                      ),
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma-separated)',
                  border: OutlineInputBorder(),
                  hintText: 'beach, summer, family',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Select Day:'),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: _selectedDay,
                    items: List.generate(
                      itineraryDurationInDays,
                          (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('Day ${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDay = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final selectedPlaces = await Navigator.push<List<Map<String, dynamic>>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SavedPlacesScreen(selectMode: true),
                    ),
                  );

                  if (selectedPlaces != null && selectedPlaces.isNotEmpty) {
                    for (var place in selectedPlaces) {
                      _addPlace(place);
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Place from Saved Places'),
              ),
              const SizedBox(height: 16),
              _buildPlacesList(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(widget.itinerary == null ? 'Create' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to display the list of places in the itinerary
  Widget _buildPlacesList() {
    if (_places.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No places added yet.'),
      );
    }

    final Map<int, List<Map<String, dynamic>>> placesByDay = {};
    for (var place in _places) {
      final day = place['day'] ?? 1;
      placesByDay.putIfAbsent(day, () => []).add(place);
    }

    return Column(
      children: placesByDay.entries.map((entry) {
        final day = entry.key;
        final places = entry.value;
        return ExpansionTile(
          title: Text('Day $day'),
          initiallyExpanded: true,
          children: places.asMap().entries.map((placeEntry) {
            final index = _places.indexOf(placeEntry.value);
            final place = placeEntry.value;
            return ListTile(
              title: Text(place['name'] ?? 'Unnamed Place'),
              subtitle: Text(place['location']?['city'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _removePlace(index),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}