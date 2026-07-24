import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    return CambricUserProfile(
      id: user.id,
      email: user.email,
      displayName: user.userMetadata?['display_name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      createdAt: user.createdAt != null && user.createdAt.isNotEmpty ? DateTime.tryParse(user.createdAt) : null,
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

  User? get user => _user;
  CambricUserProfile? get profile => _profile;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Mark as ready immediately - Supabase is already initialized in main.dart
    // This prevents infinite loading
    _loading = false;
    _initialSessionChecked = true;
    
    try {
      final client = Supabase.instance.client;
      
      // Check existing session
      _checkExistingSession(client);
      
      // Set up auth state listener
      _subscription = client.auth.onAuthStateChange.listen((data) {
        _onAuthStateChange(client, data);
      });
    } catch (e) {
      _error = 'Failed to connect to server';
      _loading = false;
      notifyListeners();
    }
  }

  void _checkExistingSession(SupabaseClient client) {
    try {
      final session = client.auth.currentSession;
      if (session != null && session.user != null) {
        _user = session.user;
        _profile = CambricUserProfile.fromUser(_user!);
        _ensureProfile();
      }
    } catch (e) {
      // Ignore errors, user can still sign in
    }
    notifyListeners();
  }

  void _onAuthStateChange(SupabaseClient client, AuthState data) {
    try {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        _user = session!.user;
        _profile = CambricUserProfile.fromUser(_user!);
        _loading = false;
        _error = null;
        _ensureProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _profile = null;
        _error = null;
      } else if (event == AuthChangeEvent.tokenRefreshed && session?.user != null) {
        _user = session!.user;
        _profile = CambricUserProfile.fromUser(_user!);
      } else if (event == AuthChangeEvent.initialSession && session?.user != null) {
        _user = session!.user;
        _profile = CambricUserProfile.fromUser(_user!);
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

      if (result.user != null) {
        _user = result.user;
        _profile = CambricUserProfile.fromUser(_user!);
        _loading = false;
        _error = null;
        notifyListeners();
        _ensureProfile();
        return true;
      }
      
      _error = 'Sign in failed';
      _loading = false;
      notifyListeners();
      return false;
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

      if (response.user != null) {
        _user = response.user;
        _profile = CambricUserProfile.fromUser(_user!);
        _loading = false;
        notifyListeners();
        _ensureProfile();
        return true;
      }
      
      _error = 'Sign up pending. Check your email.';
      _loading = false;
      notifyListeners();
      return false;
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
    if (_user == null) return;
    try {
      final updates = <String, dynamic>{
        'id': _user!.id,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (displayName != null) updates['display_name'] = displayName;
      if (additionalData != null) updates.addAll(additionalData);
      await Supabase.instance.client.from('digital_saver_user_profiles').upsert(updates);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _ensureProfile() async {
    if (_user == null) return;
    try {
      await Supabase.instance.client.from('digital_saver_user_profiles').upsert({
        'id': _user!.id,
        'email': _user!.email,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
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
