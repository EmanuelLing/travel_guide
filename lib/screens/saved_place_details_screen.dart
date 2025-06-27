import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SavedPlaceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> place;

  const SavedPlaceDetailsScreen({
    Key? key,
    required this.place,
  }) : super(key: key);

  Widget _buildInfoCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
        VoidCallback? onTap,
      }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    final l10n = AppLocalizations.of(context)!;

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ${l10n.copy}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final String name = place['name'] ?? 'Unnamed Place';
    final String imageUrl = place['image'] ?? '';
    final String address = place['address'] ?? '';
    final String type = place['type'] ?? '';
    final String notes = place['notes'] ?? '';
    final String phone = place['phone'] ?? '';
    final String website = place['website'] ?? '';
    final String openingHours = place['openingHours'] ?? '';
    final String category = place['category'] ?? '';
    final String city = place['location']?['city'] ?? '';
    final String country = place['location']?['country'] ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue[400]!,
                                Colors.blue[600]!,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.place,
                            size: 80,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue[400]!,
                            Colors.blue[600]!,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.place,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Place Name and Category/Type
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                if (category.isNotEmpty || type.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (category.isNotEmpty)
                                        _buildChip(category, Icons.category),
                                      if (type.isNotEmpty)
                                        _buildChip(type, Icons.label),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Location Information
                      if (address.isNotEmpty || city.isNotEmpty || country.isNotEmpty) ...[
                        Text(
                          l10n.location,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (address.isNotEmpty)
                          _buildInfoCard(
                            context,
                            icon: Icons.location_on,
                            title: l10n.address,
                            value: address,
                            onTap: () => _copyToClipboard(context, address, 'Address'),
                          ),
                        if (city.isNotEmpty)
                          _buildInfoCard(
                            context,
                            icon: Icons.location_city,
                            title: l10n.city,
                            value: city,
                          ),
                        if (country.isNotEmpty)
                          _buildInfoCard(
                            context,
                            icon: Icons.public,
                            title: l10n.country,
                            value: country,
                          ),
                        const SizedBox(height: 16),
                      ],

                      // Contact Information
                      if (phone.isNotEmpty || website.isNotEmpty) ...[
                        Text(
                          l10n.contact,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (phone.isNotEmpty)
                          _buildInfoCard(
                            context,
                            icon: Icons.phone,
                            title: l10n.phone,
                            value: phone,
                            onTap: () => _makePhoneCall(phone),
                          ),
                        if (website.isNotEmpty)
                          _buildInfoCard(
                            context,
                            icon: Icons.language,
                            title: l10n.website,
                            value: website,
                            onTap: () => _launchUrl(website.startsWith('http') ? website : 'https://$website'),
                          ),
                        const SizedBox(height: 16),
                      ],

                      // Opening Hours
                      if (openingHours.isNotEmpty) ...[
                        Text(
                          l10n.hours,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          icon: Icons.access_time,
                          title: l10n.openingHours,
                          value: openingHours,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Notes
                      if (notes.isNotEmpty) ...[
                        Text(
                          l10n.notes,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              notes,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add functionality for directions or other actions
          final locationQuery = address.isNotEmpty ? address : '$city, $country';
          if (locationQuery.isNotEmpty) {
            _launchUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(locationQuery)}');
          }
        },
        icon: const Icon(Icons.directions),
        label: Text(l10n.directions),
      ),
    );
  }
}