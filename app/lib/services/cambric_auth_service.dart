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
  bool _loading = false;
  String? _error;
  StreamSubscription<AuthState>? _authSubscription;

  User? get user => _user;
  CambricUserProfile? get profile => _profile;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _loading = false;
    
    final session = _client.auth.currentSession;
    if (session != null) {
      _user = session.user;
      _profile = CambricUserProfile.fromUser(_user!);
    }

    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
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
      _error = 'Connection error. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String displayName) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      if (response.user != null) {
        _user = response.user;
        _profile = CambricUserProfile.fromUser(_user!);
        
        try {
          await _client.from('digital_saver_user_profiles').insert({
            'id': _user!.id,
            'email': email,
            'display_name': displayName,
          });
        } catch (_) {}
        
        try {
          await _client.from('digital_saver_storage_stats').insert({
            'user_id': _user!.id,
          });
        } catch (_) {}
      }
      
      _loading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = _mapAuthError(e.message);
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _user = null;
    _profile = null;
    notifyListeners();
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) return 'Invalid email or password';
    if (message.contains('Email not confirmed')) return 'Please check your email to confirm';
    if (message.contains('User already registered')) return 'This email is already registered';
    if (message.contains('Password should be at least')) return 'Password must be at least 6 characters';
    if (message.contains('weak')) return 'Password is too weak';
    return message;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
