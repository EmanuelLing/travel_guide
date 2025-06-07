import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/location_api_service.dart';
import '../services/image_storage_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _authService = AuthService();
  final _locationApiService = LocationApiService();
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _initializing = true;

  late Stream<UserModel?> _authStream;

  String? _selectedCountry;
  String? _selectedCountryCode;
  String? _selectedRegion;
  String? _selectedRegionCode;
  String? _selectedCity;

  List<Country> _countries = [];
  List<Region> _regions = [];
  List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _initializeLocationData();
  }

  Future<void> _initializeLocationData() async {
    try {
      final countries = await _locationApiService.getCountries();
      if (mounted) {
        setState(() {
          _countries = countries;
        });
      }
    } catch (e) {
      // Handle error or show message
    }
  }

  Future<void> _initializeAuth() async {
    await _authService.initializeCurrentUser();
    if (mounted) {
      setState(() {
        _authStream = _authService.authStateChanges;
        _initializing = false;
      });
    }
  }

  Future<void> _loadUserData([UserModel? user]) async {
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email;

      final countryObj = _countries.firstWhere(
            (country) => country.name == user.country,
        orElse: () => Country(name: '', code: ''),
      );

      if (_selectedCountryCode != countryObj.code) {
        setState(() {
          _selectedCountry = countryObj.name.isNotEmpty ? countryObj.name : null;
          _selectedCountryCode = countryObj.code.isNotEmpty ? countryObj.code : null;
          _selectedRegion = user.region;
          _selectedRegionCode = user.regionCode;
          _selectedCity = user.city;
        });

        if (_selectedCountryCode != null) {
          await _loadRegions(_selectedCountryCode!);
        }
        if (_selectedCountryCode != null && _selectedRegionCode != null) {
          await _loadCities(_selectedCountryCode!, _selectedRegionCode!);
        }
      }

      _updateLocationDisplay();
    }
  }

  Future<void> _loadRegions(String countryCode) async {
    try {
      final regions = await _locationApiService.getRegions(countryCode);
      if (mounted) {
        setState(() {
          _regions = regions;
          print("states from loadStates: ${_regions}");
        });
      }
    } catch (e) {
      // Handle error or show message
      print(e.toString());
    }
  }

  Future<void> _loadCities(String countryCode, String regionCode) async {
    try {
      print("load cities, the country code is ${countryCode} and the region code is ${regionCode}");
      final cities = await _locationApiService.getCities(countryCode, regionCode);
      if (mounted) {
        setState(() {
          _cities = cities;
          print('cities: ${_cities}');
        });
      }
    } catch (e) {
      // Handle error or show message
      print("Error in load Cities ${e.toString()}");
    }
  }

  void _updateLocationDisplay() {
    final locationParts = [
      _selectedCity,
      _selectedRegion,
      _selectedCountry,
    ].where((e) => e != null && e.isNotEmpty).toList();
    _locationController.text = locationParts.isEmpty ? 'No location set' : locationParts.join(', ');
  }

  Future<void> _showLocationPicker() async {
    final originalCountries = _countries;
    final originalRegions = _regions;
    final originalCities = _cities;

    Country? tempCountry;
    try {
      tempCountry = _countries.firstWhere((c) => c.code == _selectedCountryCode);
    } catch (e) {
      tempCountry = null;
    }
    Region? tempRegion;
    try {
      tempRegion = _regions.firstWhere((r) => r.name == _selectedRegion);
    } catch (e) {
      tempRegion = null;
    }
    String? tempCity = _selectedCity;

    // Remove duplicates from cities list
    final uniqueCities = _cities.toSet().toList();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final countries = _countries;
            final regions = tempCountry != null ? _regions : <Region>[];
            final cities = (tempCountry != null && tempRegion != null) ? _cities : <String>[];

            return AlertDialog(
              title: const Text('Select Location'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<Country>(
                      value: tempCountry,
                      isExpanded: true,
                      hint: const Text('Select Country'),
                      items: countries.map<DropdownMenuItem<Country>>((Country country) {
                        return DropdownMenuItem<Country>(
                          value: country,
                          child: Text(country.name),
                        );
                      }).toList(),
                      onChanged: (Country? newValue) async {
                        setState(() {
                          tempCountry = newValue;
                          tempRegion = null;
                          tempCity = null;
                          _regions = [];
                          _cities = [];
                        });
                        if (newValue != null) {
                          await _loadRegions(newValue.code);
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (tempCountry != null && _regions.isNotEmpty)
                      Column(
                        children: [
                          DropdownButton<Region>(
                            value: tempRegion,
                            isExpanded: true,
                            hint: const Text('Select Region'),
                            items: regions.map<DropdownMenuItem<Region>>((Region region) {
                              return DropdownMenuItem<Region>(
                                value: region,
                                child: Text(region.name),
                              );
                            }).toList(),
                            onChanged: (Region? newValue) async {
                              setState(() {
                                tempRegion = newValue;
                                tempCity = null;
                                _cities = [];
                              });
                              if (newValue != null && tempCountry != null) {
                                await _loadCities(tempCountry!.code, newValue.isoCode);
                                print("cities after update: ${cities}");
                                setState(() {});
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    if (tempCountry != null && tempRegion != null)
                        DropdownButton<String>(
                          value: tempCity,
                          isExpanded: true,
                          hint: const Text('Select City'),
                          items: cities.map<DropdownMenuItem<String>>((String city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              tempCity = newValue;
                            });
                          },
                        )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    this.setState(() {
                      _countries = originalCountries;
                      _regions = originalRegions;
                      _cities = originalCities;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() {
                      _selectedCountryCode = tempCountry?.code;
                      _selectedRegion = tempRegion?.name;
                      _selectedRegionCode = tempRegion?.isoCode;
                      _selectedCity = tempCity;
                      _updateLocationDisplay();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      // Get current position using geolocator package
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Reverse geocode to get address details using geocoding package
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        setState(() {
          _selectedCountry = place.country;
          _selectedRegion = place.administrativeArea;
          _selectedCity = place.locality;

          if (_selectedCountry != null) {
            _loadRegions(_selectedCountryCode!);
          }
          if (_selectedCountryCode != null && _selectedRegionCode != null) {
            _loadCities(_selectedCountryCode!, _selectedRegionCode!);
          }

          _updateLocationDisplay();
        });
      } else {
        setState(() {
          _locationController.text = 'Location not found';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _handleSave(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.updateProfile(
        uid: user.uid,
        displayName: _nameController.text.trim(),
        region: _selectedRegion,
        country: _selectedCountry,
        city: _selectedCity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<UserModel?>(
        stream: _authStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return _buildSignInPrompt();
          }

          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadUserData(user);
            });
          }

          return _buildUserProfile(user);
        },
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in to view your profile',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfilePicture(user),
            const SizedBox(height: 24),
            _buildEmailDisplay(user),
            const SizedBox(height: 24),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildLocationField(),
            const SizedBox(height: 16),
            if (_hasSelectedLocation) _buildSelectedLocation(),
            const SizedBox(height: 24),
            _buildSaveButton(user),
            const SizedBox(height: 16),
            _buildSignOutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture(UserModel user) {

    return Center(
      child: Stack(
        children: [
          FutureBuilder<File?>(
            future: ImageStorageService.getImageFromPath(user.localPhotoPath),
            builder: (context, snapshot) {
              return GestureDetector(
                onTap: _handleProfilePictureTap,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: snapshot.data != null
                      ? FileImage(snapshot.data!)
                      : null,
                  child: snapshot.data == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
              );
            },
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _handleProfilePictureTap,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleProfilePictureTap() async {
    final action = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Profile Picture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
            ],
          ),
        );
      },
    );

    if (action == null) return;

    File? imageFile;
    if (action == 'gallery') {
      imageFile = await ImageStorageService.pickImage();
    } else if (action == 'camera') {
      imageFile = await ImageStorageService.takePhoto();
    }

    if (imageFile != null && mounted) {
      setState(() => _isLoading = true);
      try {
        final user = _authService.currentUser;
        if (user == null) return;

        if (user.localPhotoPath != null) {
          await ImageStorageService.deleteImageLocally(user.localPhotoPath!);
          print("old local path is deleted");
        }

        final localPath = await ImageStorageService.saveImageLocally(
          imageFile,
          user.uid,
        );

        if (localPath != null) {

          await _authService.updateProfile(
            uid: user.uid,
            localPhotoPath: localPath,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile picture: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildEmailDisplay(UserModel user) {
    return Text(
      user.email ?? 'No email set',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Display Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  Widget _buildLocationField() {
    final isLocationComplete = _selectedCountry != null && _selectedRegion != null && _selectedCity != null;

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _locationController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Location',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: isLocationComplete ? _showLocationPicker: null,
              ),
            ),
            onTap: isLocationComplete ? _showLocationPicker: null,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _isLoadingLocation ? null : _getCurrentLocation,
          icon: _isLoadingLocation
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.my_location),
          tooltip: 'Use current location',
        ),
      ],
    );
  }

  bool get _hasSelectedLocation =>
      _selectedCountry != null || _selectedRegion != null || _selectedCity != null;

  Widget _buildSelectedLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Location:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (_selectedCity != null) _selectedCity,
            if (_selectedRegion != null) _selectedRegion,
            if (_selectedCountry != null) _selectedCountry,
          ].where((e) => e != null).join(', '),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSaveButton(UserModel user) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _handleSave(user),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : const Text(
        'Save Changes',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return OutlinedButton(
      onPressed: _handleSignOut,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Sign Out',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
