import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Cambric Auth Configuration
class CambricAuth {
  // Supabase Project Configuration - Cambric Products
  static const String _supabaseUrl = 'https://cambric-systems.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhbWJyaWMiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY0MjU0NjcwMCwiZXhwIjoxOTU4MTIyNzAwfQ.xsldjFOFKiQLM5A7G8X9qM1VZ1V1R5e4tYvK9tT9t0c';
  
  static SupabaseClient? _client;
  
  static SupabaseClient get client {
    _client ??= SupabaseClient(_supabaseUrl, _supabaseAnonKey);
    return _client!;
  }
  
  static Future<void> initialize() async {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }
  
  // Current user session
  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;
  
  // Auth state stream
  static Stream<AuthState> get authState => client.auth.onAuthStateChange;
}

// User profile data stored in Supabase
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
      createdAt: user.createdAt,
      lastLogin: DateTime.now(),
      metadata: user.userMetadata,
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

// Auth state provider
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = CambricAuth.client;
  User? _user;
  CambricUserProfile? _profile;
  bool _loading = true;
  String? _error;

  User? get user => _user;
  CambricUserProfile? get profile => _profile;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _loading = true;
    notifyListeners();

    // Check for existing session
    final session = _client.auth.currentSession;
    if (session != null) {
      _user = session.user;
      _profile = CambricUserProfile.fromUser(_user!);
    }

    // Listen for auth changes
    _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn) {
        _user = session?.user;
        _profile = _user != null ? CambricUserProfile.fromUser(_user!) : null;
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _profile = null;
      }
      _loading = false;
      _error = null;
      notifyListeners();
    });

    _loading = false;
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = response.user;
      _profile = _user != null ? CambricUserProfile.fromUser(_user!) : null;
      _loading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = _mapAuthError(e.message);
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, {String? displayName}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );
      _user = response.user;
      _profile = _user != null ? CambricUserProfile.fromUser(_user!) : null;
      _loading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = _mapAuthError(e.message);
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.cambric.digitalsaver://callback',
      );
      return true;
    } on AuthException catch (e) {
      _error = _mapAuthError(e.message);
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Google sign in failed';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _loading = true;
    notifyListeners();
    await _client.auth.signOut();
    _user = null;
    _profile = null;
    _loading = false;
    notifyListeners();
  }

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    if (_user == null) return;

    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _client.auth.updateUser(UserAttributes(data: updates));
        _profile = CambricUserProfile(
          id: _user!.id,
          email: _user!.email,
          displayName: displayName ?? _profile?.displayName,
          avatarUrl: avatarUrl ?? _profile?.avatarUrl,
          createdAt: _user!.createdAt,
          lastLogin: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update profile';
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.cambric.digitalsaver://reset-password',
      );
    } on AuthException catch (e) {
      _error = _mapAuthError(e.message);
      notifyListeners();
    }
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (message.contains('Email not confirmed')) {
      return 'Please verify your email address';
    } else if (message.contains('User already registered')) {
      return 'An account with this email already exists';
    } else if (message.contains('Password should be at least')) {
      return 'Password must be at least 6 characters';
    } else if (message.contains('To sign up')) {
      return 'Unable to sign up. Please try again.';
    }
    return message;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// Local auth state persistence
class AuthStateStorage {
  static const String _keyIsAuthenticated = 'cambric_authenticated';
  static const String _keyUserId = 'cambric_user_id';
  static const String _keyUserEmail = 'cambric_user_email';
  static const String _keyLastLogin = 'cambric_last_login';

  static Future<void> saveAuthState({
    required String userId,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsAuthenticated, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyLastLogin, DateTime.now().toIso8601String());
  }

  static Future<Map<String, dynamic>?> getAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuth = prefs.getBool(_keyIsAuthenticated) ?? false;
    if (!isAuth) return null;

    return {
      'userId': prefs.getString(_keyUserId),
      'email': prefs.getString(_keyUserEmail),
      'lastLogin': prefs.getString(_keyLastLogin),
    };
  }

  static Future<void> clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsAuthenticated);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyLastLogin);
  }
}
