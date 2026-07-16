import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/cambric_auth_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthScreen({super.key, this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A5F),
              Color(0xFF2563EB),
              Color(0xFF7C3AED),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Cambric Logo
              _buildLogo(),
              const SizedBox(height: 40),
              // App Title
              _buildTitle(),
              const SizedBox(height: 30),
              // Auth Card
              Expanded(
                child: _buildAuthCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite,
        color: Color(0xFF2563EB),
        size: 40,
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'CAMBRIC',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Digital Saver',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Health Monitoring System',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 600.ms)
        .slideY(begin: 0.3);
  }

  Widget _buildAuthCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Sign In'),
                Tab(text: 'Sign Up'),
              ],
            ),
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSignInForm(),
                _buildSignUpForm(),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideY(begin: 0.3);
  }

  Widget _buildSignInForm() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome back',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to your Cambric account',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          // Email Field
          _buildTextField(
            controller: emailController,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          // Password Field
          _buildTextField(
            controller: passwordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outlined,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showResetPasswordDialog(context),
              child: Text(
                'Forgot password?',
                style: GoogleFonts.inter(
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Error Message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          // Sign In Button
          _buildPrimaryButton(
            label: 'Sign In',
            isLoading: _isLoading,
            onPressed: () async {
              setState(() => _error = null);
              final auth = context.read<AuthProvider>();
              final success = await auth.signInWithEmail(
                emailController.text.trim(),
                passwordController.text,
              );
              if (success && mounted) {
                widget.onAuthSuccess?.call();
              } else if (mounted) {
                setState(() => _error = auth.error);
              }
            },
          ),
          const SizedBox(height: 24),
          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          // Social Login
          _buildSocialButton(
            icon: Icons.g_mobiledata,
            label: 'Continue with Google',
            color: const Color(0xFFDB4437),
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              await auth.signInWithGoogle();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create account',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join Cambric health ecosystem',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          // Name Field
          _buildTextField(
            controller: nameController,
            label: 'Full Name',
            hint: 'John Doe',
            icon: Icons.person_outlined,
          ),
          const SizedBox(height: 16),
          // Email Field
          _buildTextField(
            controller: emailController,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          // Password Field
          _buildTextField(
            controller: passwordController,
            label: 'Password',
            hint: 'Create a strong password',
            icon: Icons.lock_outlined,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          // Confirm Password Field
          _buildTextField(
            controller: confirmController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            icon: Icons.lock_outlined,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          // Error Message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          // Terms
          Text(
            'By signing up, you agree to Cambric\'s Terms of Service and Privacy Policy',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Sign Up Button
          _buildPrimaryButton(
            label: 'Create Account',
            isLoading: _isLoading,
            onPressed: () async {
              setState(() => _error = null);

              // Validation
              if (nameController.text.trim().isEmpty) {
                setState(() => _error = 'Please enter your name');
                return;
              }
              if (emailController.text.trim().isEmpty) {
                setState(() => _error = 'Please enter your email');
                return;
              }
              if (passwordController.text.length < 6) {
                setState(() => _error = 'Password must be at least 6 characters');
                return;
              }
              if (passwordController.text != confirmController.text) {
                setState(() => _error = 'Passwords do not match');
                return;
              }

              final auth = context.read<AuthProvider>();
              final success = await auth.signUpWithEmail(
                emailController.text.trim(),
                passwordController.text,
                displayName: nameController.text.trim(),
              );
              if (success && mounted) {
                widget.onAuthSuccess?.call();
              } else if (mounted) {
                setState(() => _error = auth.error);
              }
            },
          ),
          const SizedBox(height: 24),
          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          // Social Sign Up
          _buildSocialButton(
            icon: Icons.g_mobiledata,
            label: 'Sign up with Google',
            color: const Color(0xFFDB4437),
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              await auth.signInWithGoogle();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Password',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email to receive a password reset link.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                context.read<AuthProvider>().resetPassword(emailController.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset email sent!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
