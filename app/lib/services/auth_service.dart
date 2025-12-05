import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      // Allow UI to handle specific error codes
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Admin-Safe User Creation (Uses Secondary App)
  // Returns UID on success, null on failure
  Future<String?> createUser(String email, String password) async {
    FirebaseApp? tempApp;
    try {
      try {
        tempApp = Firebase.app('tempAuthApp');
      } catch (e) {
        tempApp = await Firebase.initializeApp(
          name: 'tempAuthApp',
          options: Firebase.app().options,
        );
      }
      
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      return credential.user?.uid;
    } catch (e) {
      return null;
    } finally {
      // Best effort cleanup
      try {
        await tempApp?.delete();
      } catch (_) {}
    }
  }
}
