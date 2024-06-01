import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref);
});

class AuthRepository {
  final ProviderRef _ref;

  AuthRepository(this._ref);

  Future<User?> signInWithGoogle() async {
    try {
      final googleSignIn = _ref.read(googleSignInProvider);
      final firebaseAuth = _ref.read(firebaseAuthProvider);

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final googleSignIn = _ref.read(googleSignInProvider);
      final firebaseAuth = _ref.read(firebaseAuthProvider);

      await googleSignIn.signOut();
      await firebaseAuth.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
