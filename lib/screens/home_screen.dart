import 'package:flutter/material.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/itinerary_card.dart';
import '../../widgets/bottom_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Where To?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const CustomSearchBar(),
                const SizedBox(height: 24),
                const Text(
                  'See Other Itineraries',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      ItineraryCard(
                        image: 'assets/japan.jpg',
                        title: 'Trip To Japan',
                        author: 'Monica',
                      ),
                      SizedBox(width: 16),
                      ItineraryCard(
                        image: 'assets/malaysia.jpg',
                        title: 'Trip To Malaysia',
                        author: 'Alex',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigation(),
    );
  }
}
