import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _showPassword = true;
  bool _showConfirm = true;

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
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _nameFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _requestFocus(FocusNode node) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) node.requestFocus();
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

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && mounted) {
        widget.onSignedIn?.call();
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _mapError(e.message));
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Connection error. Please try again.');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleSignUp() async {
    if (_isLoading) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name');
      _requestFocus(_nameFocus);
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      _requestFocus(_emailFocus);
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      _requestFocus(_passwordFocus);
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      _requestFocus(_confirmFocus);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': name},
      );

      if (response.user != null) {
        try {
          await Supabase.instance.client.from('digital_saver_user_profiles').insert({
            'id': response.user!.id,
            'email': email,
            'display_name': name,
          });
          await Supabase.instance.client.from('digital_saver_storage_stats').insert({
            'user_id': response.user!.id,
          });
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Check email to confirm.'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        widget.onSignedIn?.call();
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _mapError(e.message));
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Connection error. Please try again.');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  String _mapError(String message) {
    if (message.contains('Invalid login credentials')) return 'Invalid email or password';
    if (message.contains('Email not confirmed')) return 'Please check your email to confirm';
    if (message.contains('User already registered')) return 'This email is already registered';
    if (message.contains('Password should be at least')) return 'Password must be at least 6 characters';
    return message;
  }

  void _switchTab(int index) {
    if (_isLoading) return;
    setState(() {
      _tabIndex = index;
      _errorMessage = '';
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      if (index == 0) {
        _emailFocus.requestFocus();
      } else {
        _nameFocus.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildLogo(),
              const SizedBox(height: 30),
              _buildTitle(),
              const SizedBox(height: 50),
              Expanded(child: _buildCard()),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: const Icon(Icons.favorite, color: Color(0xFF2563EB), size: 50),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'CAMBRIC',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Digital Saver',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Health Monitoring System',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _tabIndex == 0 ? _buildSignIn() : _buildSignUp(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _tabButton('Sign In', 0)),
          Expanded(child: _tabButton('Sign Up', 1)),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isSelected = _tabIndex == index;
    return GestureDetector(
      onTap: () => _switchTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
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
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in to continue',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 32),
        _inputField(_emailController, _emailFocus, 'Email', Icons.email_outlined, TextInputType.emailAddress),
        const SizedBox(height: 20),
        _passwordField(_passwordController, _passwordFocus, 'Password'),
        const SizedBox(height: 16),
        if (_errorMessage.isNotEmpty && _tabIndex == 0) _errorBox(),
        const SizedBox(height: 24),
        _submitButton('Sign In', _handleSignIn),
        const SizedBox(height: 28),
        _divider(),
        const SizedBox(height: 24),
        _googleButton(),
      ],
    );
  }

  Widget _buildSignUp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Create account',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Join Cambric ecosystem',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 32),
        _inputField(_nameController, _nameFocus, 'Full Name', Icons.person_outlined, TextInputType.name),
        const SizedBox(height: 20),
        _inputField(_emailController, _emailFocus, 'Email', Icons.email_outlined, TextInputType.emailAddress),
        const SizedBox(height: 20),
        _passwordField(_passwordController, _passwordFocus, 'Password'),
        const SizedBox(height: 20),
        _inputField(_confirmController, _confirmFocus, 'Confirm Password', Icons.lock_outlined, TextInputType.visiblePassword, obscure: !_showConfirm, toggleObscure: () => setState(() => _showConfirm = !_showConfirm)),
        const SizedBox(height: 16),
        if (_errorMessage.isNotEmpty && _tabIndex == 1) _errorBox(),
        const SizedBox(height: 16),
        const Text(
          'By continuing, you agree to our Terms & Privacy Policy',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _submitButton('Create Account', _handleSignUp),
        const SizedBox(height: 28),
        _divider(),
        const SizedBox(height: 24),
        _googleButton(),
      ],
    );
  }

  Widget _inputField(TextEditingController controller, FocusNode focusNode, String label, IconData icon, TextInputType keyboardType, {bool obscure = false, VoidCallback? toggleObscure}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1E3A5F)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
      ),
    );
  }

  Widget _passwordField(TextEditingController controller, FocusNode focusNode, String label) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !_showPassword,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1E3A5F)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF2563EB), size: 20),
        suffixIcon: IconButton(
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
      ),
    );
  }

  Widget _errorBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('or', style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 13)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _googleButton() {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : () async {
          try {
            await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
          } catch (e) {
            if (mounted) setState(() => _errorMessage = 'Google sign in failed');
          }
        },
        icon: const Icon(Icons.g_mobiledata, size: 28, color: Color(0xFFDB4437)),
        label: Text(_tabIndex == 0 ? 'Sign in with Google' : 'Sign up with Google', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFDB4437),
          side: BorderSide(color: const Color(0xFFDB4437).withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
