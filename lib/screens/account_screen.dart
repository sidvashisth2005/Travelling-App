import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../widgets/animated_fade_slide.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
          Builder(
            builder: (context) {
              final user = FirebaseAuth.instance.currentUser;
              final name = user?.displayName ?? 'User';
              final email = user?.email ?? '';
              return Column(
                children: [
                  Builder(
                    builder: (context) {
                      final photoURL = user?.photoURL;
                      ImageProvider imageProvider;
                      if (photoURL != null && photoURL.isNotEmpty) {
                        if (photoURL.startsWith('http')) {
                          imageProvider = NetworkImage(photoURL);
                        } else {
                          imageProvider = FileImage(File(photoURL));
                        }
                      } else {
                        imageProvider = const AssetImage('assets/images/default_avatar.png');
                      }
                      return CircleAvatar(radius: 50, backgroundImage: imageProvider);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                  ),
                ],
              );
            },
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

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    String? photoURL = user?.photoURL;
    // For demo: just use local file path as photoURL (in real app, upload to storage and get a URL)
    if (_imageFile != null) {
      photoURL = _imageFile!.path;
    }
    await user?.updateDisplayName(_nameController.text.trim());
    if (photoURL != null) await user?.updatePhotoURL(photoURL);
    await user?.reload();
    setState(() => _isLoading = false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully.', style: TextStyle(fontSize: 14, color: Colors.white70)),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: Colors.grey[900],
          elevation: 6,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final photo = _imageFile != null
        ? FileImage(_imageFile!)
        : (user?.photoURL != null && user!.photoURL!.isNotEmpty && File(user.photoURL!).existsSync()
            ? FileImage(File(user.photoURL!))
            : const NetworkImage('https://i.pravatar.cc/150?img=3') as ImageProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: photo,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Save Changes'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}