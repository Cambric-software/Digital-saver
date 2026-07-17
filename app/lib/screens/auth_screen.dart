import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cambric_auth_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthScreen({super.key, this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _tabIndex = 0;

  final _signInEmail = TextEditingController();
  final _signInPassword = TextEditingController();
  final _signUpName = TextEditingController();
  final _signUpEmail = TextEditingController();
  final _signUpPassword = TextEditingController();
  final _signUpConfirm = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _showPassword = false;
  bool _showConfirm = false;

  // Separate auth instance to avoid rebuilds from main provider

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _signInEmail.dispose();
    _signInPassword.dispose();
    _signUpName.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    _signUpConfirm.dispose();
    super.dispose();
  }

  Future<void> _doSignIn() async {
    final email = _signInEmail.text.trim();
    final password = _signInPassword.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await CambricAuth.client.auth.signInWithPassword(email: email, password: password);
      if (mounted) {
        widget.onAuthSuccess?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = _mapError(e.toString()));
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _doSignUp() async {
    final name = _signUpName.text.trim();
    final email = _signUpEmail.text.trim();
    final password = _signUpPassword.text;
    final confirm = _signUpConfirm.text;

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
      _errorMessage = null;
    });

    try {
      final response = await CambricAuth.client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': name},
      );
      
      if (response.user != null) {
        // Create profile in database
        await CambricAuth.client.from('digital_saver_user_profiles').insert({
          'id': response.user!.id,
          'email': email,
          'display_name': name,
        });
        await CambricAuth.client.from('digital_saver_storage_stats').insert({
          'user_id': response.user!.id,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Check email to confirm.'), backgroundColor: Color(0xFF22C55E)),
        );
        widget.onAuthSuccess?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = _mapError(e.toString()));
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _mapError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (error.contains('Email not confirmed')) {
      return 'Please verify your email address';
    } else if (error.contains('User already registered')) {
      return 'An account with this email already exists';
    } else if (error.contains('Password should be at least')) {
      return 'Password must be at least 6 characters';
    }
    return 'An error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Expanded(child: _buildWhiteCard()),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: const Icon(Icons.favorite, color: Color(0xFF2563EB), size: 50),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text('CAMBRIC', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6), letterSpacing: 4)).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 8),
        Text('Digital Saver', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 8),
        Text('Health Monitoring System', style: GoogleFonts.inter(fontSize: 16, color: Colors.white.withOpacity(0.7))).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildWhiteCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _tabIndex == 0 ? _buildSignInForm() : _buildSignUpForm(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
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
          Expanded(child: _tabItem('Sign In', 0)),
          Expanded(child: _tabItem('Sign Up', 1)),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final isActive = _tabIndex == index;
    return GestureDetector(
      onTap: _isLoading ? null : () => setState(() {
        _tabIndex = index;
        _errorMessage = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
        )),
      ),
    );
  }

  Widget _buildSignInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Welcome back', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A5F))),
        const SizedBox(height: 8),
        Text('Sign in to your Cambric account', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
        const SizedBox(height: 32),
        _buildTextField(_signInEmail, 'Email', Icons.email_outlined, TextInputType.emailAddress),
        const SizedBox(height: 20),
        _buildTextField(_signInPassword, 'Password', Icons.lock_outlined, TextInputType.visiblePassword, obscure: !_showPassword, suffix: IconButton(
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        )),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showResetDialog,
            child: Text('Forgot password?', style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontWeight: FontWeight.w500)),
          ),
        ),
        if (_errorMessage != null) ...[const SizedBox(height: 16), _errorBox(_errorMessage!)],
        const SizedBox(height: 24),
        _primaryButton('Sign In', _doSignIn),
        const SizedBox(height: 28),
        _divider(),
        const SizedBox(height: 24),
        _googleButton('Continue with Google'),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Create account', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A5F))),
        const SizedBox(height: 8),
        Text('Join Cambric health ecosystem', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
        const SizedBox(height: 32),
        _buildTextField(_signUpName, 'Full Name', Icons.person_outlined, TextInputType.name),
        const SizedBox(height: 20),
        _buildTextField(_signUpEmail, 'Email', Icons.email_outlined, TextInputType.emailAddress),
        const SizedBox(height: 20),
        _buildTextField(_signUpPassword, 'Password', Icons.lock_outlined, TextInputType.visiblePassword, obscure: !_showPassword, suffix: IconButton(
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        )),
        const SizedBox(height: 20),
        _buildTextField(_signUpConfirm, 'Confirm Password', Icons.lock_outlined, TextInputType.visiblePassword, obscure: !_showConfirm, suffix: IconButton(
          icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
          onPressed: () => setState(() => _showConfirm = !_showConfirm),
        )),
        const SizedBox(height: 16),
        if (_errorMessage != null) ...[_errorBox(_errorMessage!), const SizedBox(height: 16)],
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text("By signing up, you agree to Cambric's Terms and Privacy Policy", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)), textAlign: TextAlign.center),
        ),
        _primaryButton('Create Account', _doSignUp),
        const SizedBox(height: 28),
        _divider(),
        const SizedBox(height: 24),
        _googleButton('Sign up with Google'),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, TextInputType keyboardType, {bool obscure = false, Widget? suffix}) {
    return TextField(
      key: ValueKey(ctrl.hashCode),
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1E3A5F)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 14))),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
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
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
            : Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('or', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13))),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _googleButton(String label) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : () async {
          try {
            await CambricAuth.client.auth.signInWithOAuth(OAuthProvider.google, redirectTo: 'com.cambric.digitalsaver://callback');
          } catch (e) {
            setState(() => _errorMessage = 'Google sign in failed');
          }
        },
        icon: const Icon(Icons.g_mobiledata, size: 28, color: Color(0xFFDB4437)),
        label: Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFDB4437),
          side: BorderSide(color: const Color(0xFFDB4437).withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  void _showResetDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your email to receive a password reset link.'),
            const SizedBox(height: 16),
            TextField(controller: ctrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final email = ctrl.text.trim();
              if (email.isEmpty) return;
              try {
                await CambricAuth.client.auth.resetPasswordForEmail(email, redirectTo: 'com.cambric.digitalsaver://reset-password');
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent!'), backgroundColor: Color(0xFF22C55E)),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to send reset email'), backgroundColor: Color(0xFFDC2626)),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
