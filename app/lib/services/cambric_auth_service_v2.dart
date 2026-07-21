import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CambricAuth {
  static const String _supabaseUrl = 'https://dafgzzkerytjuvxzymnq.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhZmd6emtlcnl0anV2eHp5bW5xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3MTE1MDUsImV4cCI6MjA5OTI4NzUwNX0.bZdxqNuy1ZyHMGzBieq7BzUd6IUEhfHEZxL-YTka3DQ';

  static SupabaseClient? _client;

  static SupabaseClient get client {
    _client ??= SupabaseClient(_supabaseUrl, _supabaseAnonKey);
    return _client!;
  }

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

class AuthProvider extends ChangeNotifier {
  SupabaseClient get _client => CambricAuth.client;
  User? _user;
  CambricUserProfile? _profile;
  bool _loading = true;  // Start as true to prevent premature redirects
  String? _error;
  StreamSubscription<AuthState>? _authSubscription;
  bool _sessionRestored = false;
  bool _initialCheckDone = false;

  User? get user => _user;
  CambricUserProfile? get profile => _profile;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // FIRST: Set up stream listener BEFORE anything else
    // This ensures we catch initialSession even if it fires immediately
    _authSubscription = _client.auth.onAuthStateChange.listen(
      _handleAuthChange,
      onError: (error) {
        _error = error.toString();
        _loading = false;
        _initialCheckDone = true;
        notifyListeners();
      },
    );

    // THEN: Check for existing session synchronously
    // This is a fallback for sessions already in memory
    _checkExistingSessionSync();
  }

  void _checkExistingSessionSync() {
    if (_initialCheckDone) return;
    
    try {
      final existingSession = _client.auth.currentSession;
      if (existingSession != null && existingSession.user != null) {
        _user = existingSession.user;
        _profile = CambricUserProfile.fromUser(_user!);
        _sessionRestored = true;
        _loading = false;
        _initialCheckDone = true;
        // Load full profile in background
        _loadFullProfile();
        notifyListeners();
      } else {
        // No session found yet, wait for stream
        // Set a timeout to prevent infinite loading
        Future.delayed(const Duration(seconds: 3), () {
          if (!_initialCheckDone && _user == null) {
            _loading = false;
            _initialCheckDone = true;
            notifyListeners();
          }
        });
      }
    } catch (e) {
      _loading = false;
      _initialCheckDone = true;
      notifyListeners();
    }
  }

  Future<void> _handleAuthChange(AuthState data) async {
    if (_initialCheckDone && _user != null && data.event != AuthChangeEvent.signedOut) {
      // Already have a user, ignore redundant events (except signedOut)
      return;
    }

    final AuthChangeEvent event = data.event;
    final Session? session = data.session;

    switch (event) {
      case AuthChangeEvent.initialSession:
        // This fires when session is restored from storage (web refresh)
        if (session?.user != null) {
          _user = session!.user;
          _profile = CambricUserProfile.fromUser(_user!);
          _sessionRestored = true;
          _loadFullProfile(); // fire and forget
        }
        _loading = false;
        _initialCheckDone = true;
        _error = null;
        notifyListeners();
        break;

      case AuthChangeEvent.signedIn:
        if (session?.user != null) {
          _user = session!.user;
          _profile = CambricUserProfile.fromUser(_user!);
          _sessionRestored = true;
          _loadFullProfile(); // fire and forget
        }
        _loading = false;
        _initialCheckDone = true;
        _error = null;
        notifyListeners();
        break;

      case AuthChangeEvent.tokenRefreshed:
        if (session?.user != null) {
          _user = session!.user;
          _profile = CambricUserProfile.fromUser(_user!);
        }
        _loading = false;
        notifyListeners();
        break;

      case AuthChangeEvent.signedOut:
        _user = null;
        _profile = null;
        _sessionRestored = false;
        _loading = false;
        _initialCheckDone = true;
        notifyListeners();
        break;

      case AuthChangeEvent.userUpdated:
        if (session?.user != null) {
          _user = session!.user;
          _profile = CambricUserProfile.fromUser(_user!);
          _loadFullProfile(); // fire and forget
        }
        _loading = false;
        notifyListeners();
        break;

      default:
        break;
    }
  }

  Future<void> _loadFullProfile() async {
    if (_user == null) return;

    try {
      final result = await _client
          .from('digital_saver_user_profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (result != null) {
        _profile = CambricUserProfile.fromProfile(result);
        notifyListeners();
      }
    } catch (e) {
      // Profile load failed, user still authenticated
    }
  }

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      if (response.user != null) {
        _user = response.user;
        _profile = CambricUserProfile.fromUser(_user!);
        await _createUserProfile();
        _loading = false;
        _initialCheckDone = true;
        notifyListeners();
        return true;
      }

      _loading = false;
      _error = 'Sign up failed';
      notifyListeners();
      return false;
    } catch (e) {
      _loading = false;
      _error = _parseError(e); _initialCheckDone = true; // Mark done even on failure
      notifyListeners();
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Race between sign in and 8 second timeout
      final result = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 8));

      if (result.user != null) {
        _user = result.user;
        _profile = CambricUserProfile.fromUser(_user!);
        _loadFullProfile(); // fire and forget
        _loading = false;
        _initialCheckDone = true;
        notifyListeners();
        return true;
      }

      _loading = false;
      _error = "Sign in failed"; _initialCheckDone = true; // Mark done even on failure
      notifyListeners();
      return false;
    } on TimeoutException {
      _loading = false;
      _initialCheckDone = true; // Mark done even on timeout
      _error = 'Connection timed out. Please check your internet.';
      notifyListeners();
      return false;
    } catch (e) {
      _loading = false;
      _error = _parseError(e); _initialCheckDone = true; // Mark done even on failure
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://cambric-software.github.io/Digital-saver/',
      );
      // OAuth redirects, session will be restored via onAuthStateChange
      return true;
    } catch (e) {
      _loading = false;
      _error = _parseError(e); _initialCheckDone = true; // Mark done even on failure
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _loading = true;
    notifyListeners();

    try {
      await _client.auth.signOut();
      _user = null;
      _profile = null;
      _sessionRestored = false;
      _initialCheckDone = true;
    } catch (e) {
      // Sign out failed but still clear local state
      _user = null;
      _profile = null;
      _sessionRestored = false;
      _initialCheckDone = true;
    }

    _loading = false;
    notifyListeners();
  }

  // Update user profile
  Future<bool> updateProfile({
    String? displayName,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_user == null) return false;

    try {
      final updates = <String, dynamic>{
        'id': _user!.id,  // Required for upsert
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) {
        updates['display_name'] = displayName;
        // Also update auth metadata
        await _client.auth.updateUser(
          UserAttributes(data: {'display_name': displayName}),
        );
      }

      if (additionalData != null) {
        updates.addAll(additionalData);
      }

      await _client.from('digital_saver_user_profiles').upsert(updates);

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

  // Reset password
  Future<bool> resetPassword(String email) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://cambric-software.github.io/Digital-saver/',
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      _error = _parseError(e); _initialCheckDone = true; // Mark done even on failure
      notifyListeners();
      return false;
    }
  }

  // Create user profile in database
  Future<void> _createUserProfile() async {
    if (_user == null) return;

    try {
      await _client.from('digital_saver_user_profiles').upsert({
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

  // Parse error messages
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
