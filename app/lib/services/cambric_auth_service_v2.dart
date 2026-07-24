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
      createdAt: user.createdAt.isNotEmpty ? DateTime.tryParse(user.createdAt) : null,
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

/// Minimal AuthProvider - simplified for reliability
class AuthProvider extends ChangeNotifier {
  User? _user;
  CambricUserProfile? _profile;
  bool _loading = true;
  String? _error;
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
    // Wait for Supabase client to be ready
    SupabaseClient? client;
    for (int i = 0; i < 30 && client == null; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      try {
        client = Supabase.instance.client;
      } catch (_) {}
    }
    
    if (client == null) {
      _loading = false;
      _error = 'Failed to connect to server';
      notifyListeners();
      return;
    }

    // Listen for auth changes
    _subscription = client.auth.onAuthStateChange.listen((data) {
      _onAuthStateChange(client!, data);
    });
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
      } else if (event == AuthChangeEvent.initialSession && session?.user != null) {
        _user = session!.user;
        _profile = CambricUserProfile.fromUser(_user!);
        _loading = false;
        _error = null;
      } else if (event == AuthChangeEvent.tokenRefreshed && session?.user != null) {
        _user = session!.user;
        _profile = CambricUserProfile.fromUser(_user!);
      }
    } catch (e) {
      _loading = false;
    }
    
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    _loading = true;
    _error = null;
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
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    _user = null;
    _profile = null;
    _loading = false;
    notifyListeners();
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
    return 'Authentication failed. Please try again.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
