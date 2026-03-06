import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  const AuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authChanges() => _auth.authStateChanges();

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();
}
