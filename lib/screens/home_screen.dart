import 'package:flutter/material.dart';
import '../models/destination.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Destination> popularDestinations = const [
    Destination(city: 'Paris', country: 'France', imageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760c0341?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80'),
    Destination(city: 'Kyoto', country: 'Japan', imageUrl: 'https://images.unsplash.com/photo-1524413840807-0c3cb6fa808d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80'),
    Destination(city: 'Rome', country: 'Italy', imageUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1396&q=80'),
    Destination(city: 'Santorini', country: 'Greece', imageUrl: 'https://images.unsplash.com/photo-1533105079780-52b9be4ac20d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hi, John', style: theme.textTheme.bodyMedium),
                  Text('Where to next?', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 20),
                  const TextField(decoration: InputDecoration(hintText: 'Search for a city...', prefixIcon: Icon(Icons.search))),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader(context, 'Popular Destinations'),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: popularDestinations.length,
                itemBuilder: (context, index) => DestinationCard(destination: popularDestinations[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          TextButton(onPressed: () {}, child: Text('See All', style: TextStyle(color: Theme.of(context).colorScheme.tertiary))),
        ],
      ),
    );
  }
}

class DestinationCard extends StatelessWidget {
  const DestinationCard({super.key, required this.destination});
  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                destination.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(destination.city, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(destination.country, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}