import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cambric_auth_service_v2.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onSignedIn;

  const AuthScreen({super.key, this.onSignedIn});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _tabIndex = 0;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _showPassword = true;
  bool _showConfirm = true;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _emailController.text = '';
    _passwordController.text = '';
    _nameController.text = '';
    _confirmController.text = '';
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _resetLoading() {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _startLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 60), () {
      _resetLoading();
      if (mounted) {
        setState(() => _errorMessage = 'Connection timed out. Please try again.');
      }
    });
  }

  Future<void> _handleSignIn() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    _startLoadingTimer();

    try {
      // Use AuthProvider to handle sign in properly
      final auth = context.read<AuthProvider>();
      final success = await auth.signIn(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 30));

      _loadingTimer?.cancel();

      if (success) {
        widget.onSignedIn?.call();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = auth.error ?? 'Sign in failed. Please check your credentials.';
          });
        }
      }
    } on TimeoutException {
      _loadingTimer?.cancel();
      if (mounted) setState(() => _errorMessage = 'Connection timed out. Please check your internet.');
    } catch (e) {
      _loadingTimer?.cancel();
      if (mounted) setState(() => _errorMessage = 'Error: $e');
    }

    _resetLoading();
  }

  Future<void> _handleSignUp() async {
    if (_isLoading) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    _startLoadingTimer();

    try {
      // Use AuthProvider to handle sign up properly
      final auth = context.read<AuthProvider>();
      final success = await auth.signUp(
        email: email,
        password: password,
        displayName: name,
      ).timeout(const Duration(seconds: 30));

      _loadingTimer?.cancel();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        widget.onSignedIn?.call();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = auth.error ?? 'Sign up pending. Please check your email to confirm.';
          });
        }
      }
    } on TimeoutException {
      _loadingTimer?.cancel();
      if (mounted) setState(() => _errorMessage = 'Connection timed out. Please check your internet.');
    } catch (e) {
      _loadingTimer?.cancel();
      if (mounted) setState(() => _errorMessage = 'Error: $e');
    }

    _resetLoading();
  }

  void _switchTab(int index) {
    if (_isLoading) return;
    setState(() {
      _tabIndex = index;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxCardHeight = screenHeight - 160;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A5F), Color(0xFF2563EB), Color(0xFF7C3AED)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 200,
                  maxHeight: maxCardHeight,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: _tabIndex == 0 ? _buildSignIn() : _buildSignUp(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 12),
        const Text(
          'Digital Saver',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(child: _tabButton('Sign In', 0)),
              Expanded(child: _tabButton('Sign Up', 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabButton(String label, int index) {
    final isSelected = _tabIndex == index;
    return GestureDetector(
      onTap: () => _switchTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildSignIn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Welcome back',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sign in to continue',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        _buildTextField(_emailController, 'Email', Icons.email_outlined, TextInputType.emailAddress),
        const SizedBox(height: 14),
        _buildPasswordField(),
        const SizedBox(height: 14),
        if (_errorMessage.isNotEmpty && _tabIndex == 0) ...[
          _buildErrorBox(_errorMessage),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 8),
        _buildSubmitButton('Sign In', _handleSignIn),
      ],
    );
  }

  Widget _buildSignUp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Create Account',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Join Cambric ecosystem',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        _buildTextField(_nameController, 'Full Name', Icons.person_outlined, TextInputType.name),
        const SizedBox(height: 14),
        _buildTextField(_emailController, 'Email', Icons.email_outlined, TextInputType.emailAddress),
        const SizedBox(height: 14),
        _buildPasswordField(),
        const SizedBox(height: 14),
        _buildTextField(_confirmController, 'Confirm Password', Icons.lock_outlined, TextInputType.visiblePassword, obscure: !_showConfirm, toggleVisibility: () => setState(() => _showConfirm = !_showConfirm)),
        const SizedBox(height: 14),
        if (_errorMessage.isNotEmpty && _tabIndex == 1) ...[
          _buildErrorBox(_errorMessage),
          const SizedBox(height: 14),
        ],
        const Text(
          'By continuing, you agree to Terms & Privacy Policy',
          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        _buildSubmitButton('Create Account', _handleSignUp),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, TextInputType keyboardType, {bool obscure = false, VoidCallback? toggleVisibility}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1E3A5F)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        suffixIcon: toggleVisibility != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
                onPressed: toggleVisibility,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_showPassword,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1E3A5F)),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF2563EB), size: 20),
        suffixIcon: IconButton(
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
