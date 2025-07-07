import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<String?> signIn(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
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