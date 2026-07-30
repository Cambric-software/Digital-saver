import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Profile data class for Digital Saver users
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
    final createdAtValue = user.createdAt;
    DateTime? createdAt;
    if (createdAtValue != null) {
      if (createdAtValue is String) {
        createdAt = DateTime.tryParse(createdAtValue);
      } else if (createdAtValue is DateTime) {
        createdAt = createdAtValue;
      }
    }
    return CambricUserProfile(
      id: user.id ?? '',
      email: user.email,
      displayName: user.userMetadata?['display_name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      createdAt: createdAt,
      lastLogin: DateTime.now(),
      metadata: user.userMetadata,
    );
  }

  factory CambricUserProfile.fromProfile(Map<String, dynamic> data) {
    return CambricUserProfile(
      id: data['id']?.toString() ?? '',
      email: data['email'],
      displayName: data['display_name'],
      avatarUrl: data['avatar_url'],
      createdAt: data['created_at'] != null ? DateTime.tryParse(data['created_at'].toString()) : null,
      lastLogin: data['last_sync_at'] != null ? DateTime.tryParse(data['last_sync_at'].toString()) : null,
      metadata: data,
    );
  }
}

/// AuthProvider with proper state management
class AuthProvider extends ChangeNotifier {
  User? _user;
  CambricUserProfile? _profile;
  bool _loading = false;
  String? _error;
  bool _initialSessionChecked = false;
  StreamSubscription<AuthState>? _subscription;
  String? _cachedEmail;

  User? get user => _user;
  CambricUserProfile? get profile => _profile;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;
  String? get cachedEmail => _cachedEmail;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Mark as ready immediately - Supabase is already initialized in main.dart
    _loading = false;
    _initialSessionChecked = true;

    // Load cached email for cross-platform login
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedEmail = prefs.getString('cached_email');
    } catch (_) {}
    
    try {
      final client = Supabase.instance.client;
      if (client.auth == null) return;
      
      // Check existing session
      _checkExistingSession(client);
      
      // Set up auth state listener
      _subscription = client.auth.onAuthStateChange.listen(
        (data) => _onAuthStateChange(client, data),
        onError: (e) { /* Ignore errors */ },
      );
    } catch (e) {
      _error = 'Failed to connect to server';
      _loading = false;
      notifyListeners();
    }
  }

  void _checkExistingSession(SupabaseClient client) {
    try {
      final session = client.auth.currentSession;
      if (session == null) return;
      final user = session.user;
      if (user == null) return;
      final userId = user.id;
      if (userId == null || userId.isEmpty) return;
      _user = user;
      _profile = CambricUserProfile.fromUser(user);
      _ensureProfile();
    } catch (e) {
      // Ignore errors
    }
    notifyListeners();
  }

  void _onAuthStateChange(SupabaseClient client, AuthState data) {
    try {
      final event = data.event;
      final session = data.session;
      
      if (session == null) return;
      final user = session.user;
      
      if (event == AuthChangeEvent.signedIn && user != null) {
        final userId = user.id;
        if (userId == null || userId.isEmpty) return;
        _user = user;
        _profile = CambricUserProfile.fromUser(user);
        _loading = false;
        _error = null;
        _ensureProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _profile = null;
        _error = null;
      } else if (event == AuthChangeEvent.tokenRefreshed && user != null) {
        final userId = user.id;
        if (userId == null || userId.isEmpty) return;
        _user = user;
        _profile = CambricUserProfile.fromUser(user);
      } else if (event == AuthChangeEvent.initialSession && user != null) {
        final userId = user.id;
        if (userId == null || userId.isEmpty) return;
        _user = user;
        _profile = CambricUserProfile.fromUser(user);
        _ensureProfile();
      }
    } catch (e) {
      // Ignore errors
    }

    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    _loading = true;
    _error = null;
    _initialSessionChecked = true;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      final result = await client.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 30));

      final user = result.user;
      if (user == null) {
        _error = 'Sign in failed';
        _loading = false;
        notifyListeners();
        return false;
      }
      final userId = user.id;
      if (userId == null || userId.isEmpty) {
        _error = 'Sign in failed';
        _loading = false;
        notifyListeners();
        return false;
      }
      _user = user;
      _profile = CambricUserProfile.fromUser(user);
      _loading = false;
      _error = null;
      notifyListeners();
      
      await _ensureProfile();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_email', email);
      } catch (_) {}
      return true;
    } catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({required String email, required String password, String? displayName}) async {
    _loading = true;
    _error = null;
    _initialSessionChecked = true;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      final user = response.user;
      if (user == null) {
        _error = 'Sign up pending. Check your email.';
        _loading = false;
        notifyListeners();
        return false;
      }
      final userId = user.id;
      if (userId == null || userId.isEmpty) {
        _error = 'Sign up pending. Check your email.';
        _loading = false;
        notifyListeners();
        return false;
      }
      _user = user;
      _profile = CambricUserProfile.fromUser(user);
      _loading = false;
      notifyListeners();
      
      await _ensureProfile();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_email', email);
      } catch (_) {}
      return true;
    } catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _loading = true;
    notifyListeners();
    
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    
    _user = null;
    _profile = null;
    _loading = false;
    notifyListeners();
  }

  Future<void> updateProfile({String? displayName, Map<String, dynamic>? additionalData}) async {
    final user = _user;
    if (user == null) return;
    try {
      final updates = <String, dynamic>{
        'id': user.id,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (displayName != null) updates['display_name'] = displayName;
      if (additionalData != null) updates.addAll(additionalData);
      await Supabase.instance.client.from('digital_saver_user_profiles').upsert(updates);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _ensureProfile() async {
    final user = _user;
    if (user == null || user.id.isEmpty) return;
    
    try {
      await Supabase.instance.client.from('digital_saver_user_profiles').upsert({
        'id': user.id,
        'email': user.email,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail - profile creation can be retried later
    }
  }

  String _parseError(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('invalid')) return 'Invalid email or password';
    if (msg.contains('email')) return 'Check your email address';
    if (msg.contains('already')) return 'Email already registered';
    return 'Authentication failed. Please try again.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
