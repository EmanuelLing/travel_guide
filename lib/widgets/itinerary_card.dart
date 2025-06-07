import 'package:flutter/material.dart';
import '../models/itinerary_model.dart';
import '../models/user_model.dart';
import '../screens/itinerary_details_screen.dart';

class ItineraryCard extends StatelessWidget {
  final ItineraryModel itinerary;
  final VoidCallback? onTap;
  final bool showAuthor;
  final bool isDetailed;
  final UserModel? currentUser;

  const ItineraryCard({
    super.key,
    required this.itinerary,
    this.onTap,
    this.showAuthor = true,
    this.isDetailed = false,
    this.currentUser,
  });

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    IconData iconData;
    String statusText;

    switch (itinerary.status) {
      case 'completed':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        iconData = Icons.check_circle;
        statusText = 'DONE';
        break;
      case 'in_progress':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        iconData = Icons.timelapse_rounded;
        statusText = 'ACTIVE';
        break;
      case 'cancelled':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        iconData = Icons.cancel;
        statusText = 'CANCEL';
        break;
      default:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        iconData = Icons.info_outline;
        statusText = itinerary.status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 10,
            color: textColor,
          ),
          const SizedBox(width: 3),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    // Use constraint width instead of full screen width
    final cardWidth = 280.0; // Fixed width as used in the ListView

    return GestureDetector(
      onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItineraryDetailsScreen(
            itinerary: itinerary,
            currentUser: currentUser!, // Pass current user if available
          ),
        ),
      );
    },
    child: Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                theme.colorScheme.primary.withOpacity(0.03),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title and status row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        itinerary.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildStatusChip(),
                  ],
                ),

                const SizedBox(height: 8),

                // Info row - Location and dates side by side to save space
                Row(
                  children: [
                    // Location
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              itinerary.location,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dates - More compact
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 10,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${_formatDate(itinerary.startDate)} - ${_formatDate(itinerary.endDate)}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Description - conditionally rendered
                if (isDetailed) ...[
                  const SizedBox(height: 8),
                  Text(
                    itinerary.description,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Bottom section
                if (showAuthor || itinerary.tags.isNotEmpty || itinerary.likeCount > 0) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 6),

                  // Compact bottom row
                  Row(
                    children: [
                      // Tags
                      if (itinerary.tags.isNotEmpty) ...[
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: itinerary.tags.take(2).map((tag) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      style: TextStyle(
                                        color: theme.colorScheme.secondary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],

                      // Author (compact)
                      if (showAuthor) ...[
                        if (itinerary.tags.isNotEmpty)
                          const SizedBox(width: 4),
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            (itinerary.author.displayName != null
                                ? itinerary.author.displayName!
                                : itinerary.author.email)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],

                      // Like counter - simplified
                      if (itinerary.likeCount > 0) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.favorite,
                          size: 12,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          itinerary.likeCount.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}