import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CambricAuth {
  // Use the Supabase instance that's already initialized in main.dart
  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;
  static Stream<AuthState> get authState => client.auth.onAuthStateChange;
}

class CambricUserProfile {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final Map<String, dynamic>? metadata;

  CambricUserProfile({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.createdAt,
    this.lastLogin,
    this.metadata,
  });

  factory CambricUserProfile.fromUser(User user) {
    return CambricUserProfile(
      id: user.id,
      email: user.email,
      displayName: user.userMetadata?['display_name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      createdAt: user.createdAt.isNotEmpty ? DateTime.tryParse(user.createdAt) : null,
      lastLogin: DateTime.now(),
      metadata: user.userMetadata,
    );
  }

  factory CambricUserProfile.fromProfile(Map<String, dynamic> data) {
    return CambricUserProfile(
      id: data['id'],
      email: data['email'],
      displayName: data['display_name'],
      avatarUrl: data['avatar_url'],
      createdAt: data['created_at'] != null ? DateTime.tryParse(data['created_at']) : null,
      lastLogin: data['last_sync_at'] != null ? DateTime.tryParse(data['last_sync_at']) : null,
      metadata: data,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'last_login': lastLogin?.toIso8601String(),
  };
}

/// Simplified AuthProvider with reliable session handling
/// Uses standard Supabase Auth session management
class AuthProvider extends ChangeNotifier {
  SupabaseClient? _client;
  User? _user;
  CambricUserProfile? _profile;
  bool _loading = true; // Start true for initial check
  String? _error;
  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;

  User? get user => _user;
  CambricUserProfile? get profile => _profile;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Check for existing session first
    await Future.delayed(const Duration(milliseconds: 500));
    _client = Supabase.instance.client;
    assert(_client != null, "Supabase client should be initialized");
    
    // Then listen for auth changes
    _authSubscription = _client!.auth.onAuthStateChange.listen(_handleAuthChange);
    
    // Fallback: mark as initialized after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!_initialized) {
        _initialized = true;
        _loading = false;
        notifyListeners();
      }
    });
  }

  void _checkExistingSession() {
    try {
       final session = _client!.auth.currentSession;
      if (session != null && session.user != null) {
        _user = session.user;
        _profile = CambricUserProfile.fromUser(_user!);
        _loadFullProfile();
        _initialized = true;
        _loading = false;
        notifyListeners();
      }
    } catch (e) {
      // Session check failed, that's OK
      _initialized = true;
      _loading = false;
      notifyListeners();
    }
  }

  void _handleAuthChange(AuthState data) {
    final AuthChangeEvent event = data.event;
    final Session? session = data.session;

    switch (event) {
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.signedIn:
        if (session?.user != null) {
          _user = session!.user;
          _profile = CambricUserProfile.fromUser(_user!);
          _error = null;
          _initialized = true;
          _loading = false;
          _loadFullProfile();
        }
        break;

      case AuthChangeEvent.tokenRefreshed:
        if (session?.user != null) {
          _user = session!.user;
          _profile = CambricUserProfile.fromUser(_user!);
        }
        break;

      case AuthChangeEvent.signedOut:
        _user = null;
        _profile = null;
        break;

      case AuthChangeEvent.userUpdated:
        if (session?.user != null) {
          _user = session!.user;
          _profile = CambricUserProfile.fromUser(_user!);
          _loadFullProfile();
        }
        break;

      case AuthChangeEvent.passwordRecovery:
        // Password recovery email was sent - no action needed
        break;

      case AuthChangeEvent.userDeleted:
        // User account was deleted - sign out
        _user = null;
        _profile = null;
        break;

      case AuthChangeEvent.mfaChallengeVerified:
        // MFA challenge completed - refresh user
        if (session?.user != null) {
          _user = session!.user;
          _profile = CambricUserProfile.fromUser(_user!);
        }
        break;

      default:
        // Handle unknown events gracefully
        break;
    }
    
    notifyListeners();
  }

  Future<void> _loadFullProfile() async {
    if (_user == null) return;

    try {
      final result = await _client!
          .from('digital_saver_user_profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();

      if (result != null) {
        _profile = CambricUserProfile.fromProfile(result);
        notifyListeners();
      }
    } catch (e) {
      // Profile load failed, user still authenticated
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client!.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      if (response.user != null) {
        _user = response.user;
        _profile = CambricUserProfile.fromUser(_user!);
        await _createUserProfile();
        notifyListeners();
        return true;
      }

      _error = 'Sign up pending. Please check your email to confirm.';
      notifyListeners();
      return false;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 30));

      if (result.user != null) {
        _user = result.user;
        _profile = CambricUserProfile.fromUser(_user!);
        _loadFullProfile();
        notifyListeners();
        return true;
      }

      _error = 'Sign in failed';
      notifyListeners();
      return false;
    } on TimeoutException {
      _error = 'Connection timed out. Please check your internet.';
      notifyListeners();
      return false;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://cambric-software.github.io/Digital-saver/',
      );
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _loading = true;
    notifyListeners();

    try {
      await _client!.auth.signOut();
    } catch (e) {
      // Continue with local sign out
    }
    
    _user = null;
    _profile = null;
    _loading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? displayName,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_user == null) return false;

    try {
      final updates = <String, dynamic>{
        'id': _user!.id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) {
        updates['display_name'] = displayName;
        await _client!.auth.updateUser(
          UserAttributes(data: {'display_name': displayName}),
        );
      }

      if (additionalData != null) {
        updates.addAll(additionalData);
      }

      await _client!.from('digital_saver_user_profiles').upsert(updates);

      if (displayName != null && _profile != null) {
        _profile = CambricUserProfile(
          id: _profile!.id,
          email: _profile!.email,
          displayName: displayName,
          avatarUrl: _profile!.avatarUrl,
          createdAt: _profile!.createdAt,
          lastLogin: _profile!.lastLogin,
          metadata: {...?_profile!.metadata, ...?additionalData},
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _client!.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://cambric-software.github.io/Digital-saver/',
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _createUserProfile() async {
    if (_user == null) return;

    try {
      await _client!.from('digital_saver_user_profiles').upsert({
        'id': _user!.id,
        'email': _user!.email,
        'display_name': _profile?.displayName ?? _user!.email?.split('@').first,
        'created_at': DateTime.now().toIso8601String(),
        'last_sync_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Profile creation failed, not critical
    }
  }

  String _parseError(dynamic e) {
    if (e is AuthException) {
      return e.message;
    }
    if (e is Exception) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Invalid email or password';
      }
      if (msg.contains('email not confirmed')) {
        return 'Please confirm your email first';
      }
      if (msg.contains('user already registered')) {
        return 'This email is already registered';
      }
      if (msg.contains('weak password')) {
        return 'Password is too weak';
      }
    }
    return 'An error occurred. Please try again.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
