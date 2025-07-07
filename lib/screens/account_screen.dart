import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../widgets/animated_fade_slide.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  final List<Destination> wishlist = const [
    Destination(city: 'Paris', country: 'France', imageUrl: ''),
    Destination(city: 'Tokyo', country: 'Japan', imageUrl: ''),
    Destination(city: 'New York', country: 'USA', imageUrl: ''),
    Destination(city: 'Rome', country: 'Italy', imageUrl: ''),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Logged out successfully.',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    duration: Duration(milliseconds: 1500),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.grey[900],
                    elevation: 6,
                  ),
                );
                await Future.delayed(const Duration(milliseconds: 1500));
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Column(
            children: [
              CircleAvatar(radius: 50, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=3')),
              SizedBox(height: 16),
              Text('John Doe', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('johndoe@email.com', style: TextStyle(fontSize: 16, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 32),
          const StatsCard(completed: 5, scheduled: 2),
          const SizedBox(height: 32),
          const Text('My Wishlist', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: wishlist.length,
            itemBuilder: (context, index) {
              return AnimatedFadeSlide(
                delay: Duration(milliseconds: 100 * (index + 1)),
                child: WishlistCard(destination: wishlist[index]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class StatsCard extends StatelessWidget {
  final int completed;
  final int scheduled;
  const StatsCard({super.key, required this.completed, required this.scheduled});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            StatItem(icon: Icons.check_circle, label: 'Completed', value: '$completed'),
            StatItem(icon: Icons.calendar_today, label: 'Scheduled', value: '$scheduled'),
          ],
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const StatItem({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.tertiary, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
      ],
    );
  }
}

class WishlistCard extends StatelessWidget {
  final Destination destination;
  const WishlistCard({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.place_outlined, color: Theme.of(context).colorScheme.primary),
        title: Text(destination.city, style: const TextStyle(color: Colors.white)),
        subtitle: Text(destination.country, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
        onTap: () {},
      ),
    );
  }
}