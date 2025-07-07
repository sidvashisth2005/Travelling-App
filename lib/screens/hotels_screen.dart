import 'package:flutter/material.dart';

class HotelsScreen extends StatelessWidget {
  const HotelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hotels'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel_outlined, size: 100, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text('Find the Perfect Stay', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text('Compare prices and book hotels for your trip.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(icon: const Icon(Icons.search), label: const Text('Search Hotels'), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}