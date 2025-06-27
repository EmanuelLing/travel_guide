import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/location_api_service.dart';
import '../services/image_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../locale_provider.dart';

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
    _loadLanguagePreference();
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
      print('failed to get countries');
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
      print("Error in load Cities ${e.toString()}");
    }
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('selected_language');
    if (languageCode != null) {
      Locale locale = Locale(languageCode);
      Provider.of<LocaleProvider>(context, listen: false).setLocale(locale);
    }
  }

  void _updateLocationDisplay() {
    print('selected Country = $_selectedCountry');
    final locationParts = [
      _selectedCity,
      _selectedRegion,
      _selectedCountry,
    ].where((e) => e != null && e.isNotEmpty).toList();
    _locationController.text = locationParts.isEmpty ? 'No location set' : locationParts.join(', ');
  }

  Future<void> _showLocationPicker() async {
    final l10n = AppLocalizations.of(context)!;

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

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final countries = _countries;
            final regions = tempCountry != null ? _regions : <Region>[];
            final cities = (tempCountry != null && tempRegion != null) ? _cities : <String>[];

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(l10n.selectLocation),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDropdownField(
                        label: l10n.selectCountry,
                        icon: Icons.public,
                        child: DropdownButton<Country>(
                          value: tempCountry,
                          isExpanded: true,
                          hint: Text(l10n.selectCountry),
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
                      ),
                      const SizedBox(height: 20),
                      if (tempCountry != null && _regions.isNotEmpty)
                        _buildDropdownField(
                          label: l10n.selectRegion,
                          icon: Icons.map,
                          child: DropdownButton<Region>(
                            value: tempRegion,
                            isExpanded: true,
                            hint: Text(l10n.selectRegion),
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
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      if (tempCountry != null && _regions.isNotEmpty)
                        const SizedBox(height: 20),
                      if (tempCountry != null && tempRegion != null)
                        _buildDropdownField(
                          label: l10n.selectCity,
                          icon: Icons.location_city,
                          child: DropdownButton<String>(
                            value: tempCity,
                            isExpanded: true,
                            hint: Text(l10n.selectCity),
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
                          ),
                        ),
                    ],
                  ),
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
                  child: Text(l10n.cancel),
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
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoadingLocation = true);
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
          _locationController.text = l10n.locationNotFound;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorGettingLocation}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _handleSave(UserModel user) async {
    final l10n = AppLocalizations.of(context)!;

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
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(l10n.profileUpdate),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('${l10n.errorUpdateProfile}: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

  Future<void> _saveLanguagePreference(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageCode);
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
    final l10n = AppLocalizations.of(context)!;

    if (_initializing) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
        ),
      body: StreamBuilder<UserModel?>(
        stream: _authStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
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
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_circle_outlined,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.signInProfile,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Access your account settings and preferences',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      l10n.signIn,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(UserModel user) {
    return CustomScrollView(
      slivers: [
        // _buildAppBar(user),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileCard(user),
                  const SizedBox(height: 20),
                  _buildPersonalInfoCard(user),
                  const SizedBox(height: 20),
                  _buildSettingsCard(),
                  const SizedBox(height: 20),
                  _buildActionButtons(user),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildAppBar(UserModel user) {
  //   final l10n = AppLocalizations.of(context)!;
  //
  //   return SliverAppBar(
  //     expandedHeight: 120,
  //     floating: false,
  //     pinned: true,
  //     elevation: 0,
  //     backgroundColor: Theme.of(context).primaryColor,
  //     flexibleSpace: FlexibleSpaceBar(
  //       title: Text(
  //         l10n.settingsTitle,
  //         style: const TextStyle(
  //           fontWeight: FontWeight.bold,
  //           color: Colors.white,
  //         ),
  //       ),
  //       background: Container(
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //             begin: Alignment.topLeft,
  //             end: Alignment.bottomRight,
  //             colors: [
  //               Theme.of(context).primaryColor,
  //               Theme.of(context).primaryColor.withOpacity(0.8),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildProfileCard(UserModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfilePicture(user),
            const SizedBox(height: 16),
            Text(
              user.displayName ?? 'No name set',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildEmailDisplay(user),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(UserModel user) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildLocationField(),
            if (_hasSelectedLocation) ...[
              const SizedBox(height: 12),
              _buildSelectedLocation(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLanguageSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Text(
                l10n.languageSetting,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<Locale>(
              value: Provider.of<LocaleProvider>(context).locale ?? Localizations.localeOf(context),
              icon: const Icon(Icons.arrow_drop_down),
              underline: const SizedBox.shrink(),
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  _saveLanguagePreference(newLocale.languageCode);
                  Provider.of<LocaleProvider>(context, listen: false).setLocale(newLocale);
                }
              },
              items: AppLocalizations.supportedLocales.map((Locale locale) {
                return DropdownMenuItem<Locale>(
                  value: locale,
                  child: Text(Provider.of<LocaleProvider>(context).getLanguageName(locale)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildLanguageSelector() {
  //   final l10n = AppLocalizations.of(context)!;
  //
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.grey[50],
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Colors.grey[200]!),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(Icons.language, color: Colors.grey[600]),
  //             const SizedBox(width: 12),
  //             Text(
  //               l10n.languageSetting,
  //               style: const TextStyle(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //           ],
  //         ),
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  //           decoration: BoxDecoration(
  //             border: Border.all(color: Colors.grey[300]!),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: DropdownButton<Locale>(
  //             value: Provider.of<LocaleProvider>(context).locale ?? Localizations.localeOf(context),
  //             icon: const Icon(Icons.arrow_drop_down),
  //             underline: const SizedBox.shrink(),
  //             onChanged: (Locale? newLocale) {
  //               if (newLocale != null) {
  //                 _saveLanguagePreference(newLocale.languageCode);
  //                 Provider.of<LocaleProvider>(context, listen: false).setLocale(newLocale);
  //               }
  //             },
  //             items: AppLocalizations.supportedLocales.map((Locale locale) {
  //               return DropdownMenuItem<Locale>(
  //                 value: locale,
  //                 child: Text(
  //                   Provider.of<LocaleProvider>(context).getLanguageName(locale),
  //                 ),
  //               );
  //             }).toList(),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildActionButtons(UserModel user) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _handleSave(user),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save),
                const SizedBox(width: 8),
                Text(
                  l10n.saveChanges,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _handleSignOut,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.red[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: Colors.red[600]),
                const SizedBox(width: 8),
                Text(
                  l10n.signOut,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePicture(UserModel user) {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FutureBuilder<File?>(
              future: ImageStorageService.getImageFromPath(user.localPhotoPath),
              builder: (context, snapshot) {
                return GestureDetector(
                  onTap: _handleProfilePictureTap,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: snapshot.data != null
                        ? FileImage(snapshot.data!)
                        : null,
                    child: snapshot.data == null
                        ? Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey[600],
                    )
                        : null,
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: GestureDetector(
              onTap: _handleProfilePictureTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
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
    final l10n = AppLocalizations.of(context)!;

    final action = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.photo_camera, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(l10n.updateProfilePicture),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.photo_library, color: Colors.blue[600]),
                      ),
                      title: Text(l10n.chooseFromGallery),
                      onTap: () => Navigator.pop(context, 'gallery'),
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.camera_alt, color: Colors.green[600]),
                      ),
                      title: Text(l10n.takeAPhoto),
                      onTap: () => Navigator.pop(context, 'camera'),
                    ),
                  ],
                ),
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
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(l10n.profileUpdate),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${l10n.errorUpdateProfile}: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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

  Widget _buildEmailDisplay(UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            user.email ?? 'No email set',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: l10n.displayName,
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.enterName;
        }
        return null;
      },
    );
  }

  Widget _buildLocationField() {
    final l10n = AppLocalizations.of(context)!;
    final isLocationComplete = _selectedCountry != null && _selectedRegion != null && _selectedCity != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _locationController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: l10n.location,
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingLocation)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  // IconButton(
                  //   icon: const Icon(Icons.my_location),
                  //   onPressed: _getCurrentLocation,
                  //   tooltip: 'Get current location',
                  // ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showLocationPicker,
                ),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onTap: _showLocationPicker,
        ),
      ],
    );
  }

  bool get _hasSelectedLocation =>
      _selectedCountry != null || _selectedRegion != null || _selectedCity != null;

  Widget _buildSelectedLocation() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              [
                if (_selectedCity != null) _selectedCity,
                if (_selectedRegion != null) _selectedRegion,
                if (_selectedCountry != null) _selectedCountry,
              ].where((e) => e != null).join(', '),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}