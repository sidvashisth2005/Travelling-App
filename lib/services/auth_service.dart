import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_service.dart';

class AuthService {
  static Future<String?> signIn(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await UserProfileService.saveUserProfile(
          user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          photoURL: user.photoURL,
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    } catch (e) {
      return 'Login failed';
    }
  }

  static Future<String?> register(String name, String email, String password) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await cred.user?.updateDisplayName(name.trim());
      await cred.user?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await UserProfileService.saveUserProfile(
          user.uid,
          name: name.trim(),
          email: user.email ?? '',
          photoURL: user.photoURL,
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    } catch (e) {
      return 'Registration failed';
    }
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
} 