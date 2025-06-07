import 'package:flutter/material.dart';
import 'package:travel_guide/services/location_api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../widgets/main_navigation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _locationController = TextEditingController();
  final _authService = AuthService();
  final _locationApiService = LocationApiService();
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  List<Country>? _countries;
  List<String>? _regions;
  List<String>? _cities;
  String? _selectedCountry;
  String? _selectedCountryCode;
  String? _selectedRegion;
  String? _selectedRegionCode;
  String? _selectedCity;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await LocationService.getCurrentPosition();
      final address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _selectedCountry = address['country'];
        _selectedRegion = address['region'];
        _selectedCity = address['city'];
        _selectedCountryCode = address['countryCode'];
        _selectedRegionCode = address['regionCode'];
        _locationController.text = '${address['street']}, ${address['city']}, ${address['region']}, ${address['country']}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _searchLocation() async {
    if (_locationController.text.isEmpty) return;

    setState(() => _isLoadingLocation = true);
    try {
      final coordinates = await LocationService.getCoordinatesFromAddress(_locationController.text);
      final address = await LocationService.getAddressFromCoordinates(
        coordinates['latitude']!,
        coordinates['longitude']!,
      );

      setState(() {
        _selectedCountry = address['country'];
        _selectedRegion = address['region'];
        _selectedCountryCode = address['countryCode'];
        _selectedRegionCode = address['regionCode'];
        _selectedCity = address['city'];
        _locationController.text = '${address['street']}, ${address['city']}, ${address['region']}, ${address['country']}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          displayName: _nameController.text.trim(),
          region: _selectedRegion,
          regionCode: _selectedRegionCode,
          country: _selectedCountry,
          countryCode: _selectedCountryCode,
          city: _selectedCity,
        );

        if (mounted) {
          // Replace all screens with MainNavigation after successful registration
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MainNavigation(),
            ),
                (route) => false,
          );
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
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Location Search Field with Current Location Button
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchLocation,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your location';
                        }
                        return null;
                      },
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
              ),
              const SizedBox(height: 16),
              // Display Selected Location
              if (_selectedCountry != null || _selectedRegion != null || _selectedCity != null) ...[
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
                const SizedBox(height: 16),
              ],
              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
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
                  'Create Account',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              // Login Link
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
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

  Future<void> _loadRegions(String countryCode) async {
    try {
      final regions = await _locationApiService.getRegions(countryCode);
      if (mounted) {
        setState(() {
          _regions = regions.map((region) => region.name).toList();
        });
      }
    } catch (e) {
      // Handle error or show message
    }
  }

  Future<void> _loadCities(String countryCode, String regionCode) async {
    try {
      final cities = await _locationApiService.getCities(countryCode, regionCode);
      if (mounted) {
        setState(() {
          _cities = cities;
        });
      }
    } catch (e) {
      // Handle error or show message
    }
  }
}
