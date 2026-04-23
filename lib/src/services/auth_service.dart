import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around Firebase Auth for the MediLink auth gate.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  String get userId => currentUser?.uid ?? 'anonymous';
  String get displayName =>
      currentUser?.displayName ?? currentUser?.email ?? 'User';

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in anonymously — minimum friction for demo / hackathon.
  Future<User?> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return credential.user;
  }

  /// Sign in with email/password for admin access.
  Future<User?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Register a new admin account.
  Future<User?> registerWithEmail(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
