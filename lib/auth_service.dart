import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register User
  Future<String?> registerUser(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    }
  }

  // Login User
  Future<String?> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Error message handling
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
