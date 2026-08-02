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
    DateTime? createdAt;
    final createdAtValue = user.createdAt;
    if (createdAtValue != null && createdAtValue.isNotEmpty) {
      createdAt = DateTime.tryParse(createdAtValue);
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
      // FIXED: Properly check for null/empty userId before using it
      if (userId == null || userId.isEmpty) {
        // Try to get from metadata as fallback
        final metadataId = user.userMetadata?['id']?.toString();
        if (metadataId == null || metadataId.isEmpty) return;
        // Create a minimal user object for local use
        _user = user;
        _profile = CambricUserProfile.fromUser(user);
      } else {
        _user = user;
        _profile = CambricUserProfile.fromUser(user);
      }
      _ensureProfile();
    } catch (e) {
      // Log error for debugging but don't crash
      debugPrint('Error checking existing session: $e');
    }
    notifyListeners();
  }

  void _onAuthStateChange(SupabaseClient client, AuthState data) {
    try {
      final event = data.event;
      final session = data.session;
      
      if (session == null) {
        // Handle sign out
        if (event == AuthChangeEvent.signedOut) {
          _user = null;
          _profile = null;
          _error = null;
          _loading = false;
        }
        notifyListeners();
        return;
      }
      
      final user = session.user;
      if (user == null) {
        notifyListeners();
        return;
      }
      
      // FIXED: Safely check userId before using
      final userId = user.id;
      
      if (event == AuthChangeEvent.signedIn) {
        if (userId == null || userId.isEmpty) {
          debugPrint('Sign in event but userId is null/empty');
          notifyListeners();
          return;
        }
        _user = user;
        _profile = CambricUserProfile.fromUser(user);
        _loading = false;
        _error = null;
        _ensureProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _profile = null;
        _error = null;
        _loading = false;
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        if (userId != null && userId.isNotEmpty) {
          _user = user;
          _profile = CambricUserProfile.fromUser(user);
        }
      } else if (event == AuthChangeEvent.initialSession) {
        if (userId != null && userId.isNotEmpty) {
          _user = user;
          _profile = CambricUserProfile.fromUser(user);
          _ensureProfile();
        }
      }
    } catch (e) {
      // Log error for debugging but don't crash
      debugPrint('Error in auth state change: $e');
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
      
      // FIXED: Safely check userId
      final userId = user.id;
      if (userId == null || userId.isEmpty) {
        _error = 'Sign in failed - invalid user session';
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
    if (user == null || user.id.isEmpty) {
      debugPrint('ERROR [_ensureProfile]: User is null or has empty ID. User: $user');
      return;
    }

    try {
      debugPrint('INFO [_ensureProfile]: Creating profile for user ${user.id}');
      await Supabase.instance.client.from('digital_saver_user_profiles').upsert({
        'id': user.id,
        'email': user.email ?? 'unknown',
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('INFO [_ensureProfile]: Profile created successfully');
    } catch (e, stackTrace) {
      final errorMsg = 'ERROR [_ensureProfile]: Failed to create profile for user ${user.id}. Error: $e\nStack: $stackTrace';
      debugPrint(errorMsg);
      _error = 'Profile creation failed: $e';
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
