import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  GoogleAuthService({
    required SupabaseClient supabaseClient,
    GoogleSignIn? googleSignIn,
  }) : _supabase = supabaseClient,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  Future<AuthResponse> signIn() async {
    final account = await _googleSignIn.authenticate();

    final authData = await account.authentication;
    final idToken = authData.idToken;
    if (idToken == null) {
      throw AuthException('Google did not return idToken');
    }

    return _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    await _supabase.auth.signOut();
  }
}
