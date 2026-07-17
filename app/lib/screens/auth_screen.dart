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
  
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                           MediaQuery.of(context).padding.top -
                           MediaQuery.of(context).padding.bottom - 48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildLogo(),
                  const SizedBox(height: 30),
                  _buildTitle(),
                  const SizedBox(height: 50),
                  _buildWhiteCard(auth: auth),
                  const SizedBox(height: 40),
                ],
              ),
            ),
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
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text('CAMBRIC', style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6), letterSpacing: 4,
        )).animate().fadeIn(delay: 200.ms, duration: 600.ms),
        const SizedBox(height: 8),
        Text('Digital Saver', style: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white,
        )).animate().fadeIn(delay: 300.ms, duration: 600.ms),
        const SizedBox(height: 8),
        Text('Health Monitoring System', style: GoogleFonts.inter(
          fontSize: 16, color: Colors.white.withOpacity(0.7),
        )).animate().fadeIn(delay: 400.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildWhiteCard({required AuthProvider auth}) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.75),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, -5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabBar(),
          const SizedBox(height: 24),
          SizedBox(
            height: 600,
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSignInForm(auth: auth),
                _buildSignUpForm(auth: auth),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
      ),
    );
  }

  Widget _buildSignInForm({required AuthProvider auth}) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Welcome back', style: GoogleFonts.inter(
            fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A5F),
          )),
          const SizedBox(height: 8),
          Text('Sign in to your Cambric account', style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF64748B),
          )),
          const SizedBox(height: 32),
          _buildTextField(controller: _signInEmailController, label: 'Email', hint: 'you@example.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          _buildTextField(controller: _signInPasswordController, label: 'Password', hint: 'Enter your password', icon: Icons.lock_outlined, obscureText: true),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showResetPasswordDialog(context),
              child: Text('Forgot password?', style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 16),
          if (auth.error != null) _buildErrorBox(auth.error!),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: auth.loading ? null : () => _handleSignIn(auth),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: auth.loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text('Sign In', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 28),
          _buildDivider(),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: auth.loading ? null : () => _handleGoogleSignIn(auth),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: Text('Continue with Google', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDB4437), side: BorderSide(color: const Color(0xFFDB4437).withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm({required AuthProvider auth}) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create account', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A5F))),
          const SizedBox(height: 8),
          Text('Join Cambric health ecosystem', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
          const SizedBox(height: 32),
          _buildTextField(controller: _signUpNameController, label: 'Full Name', hint: 'John Doe', icon: Icons.person_outlined),
          const SizedBox(height: 20),
          _buildTextField(controller: _signUpEmailController, label: 'Email', hint: 'you@example.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          _buildTextField(controller: _signUpPasswordController, label: 'Password', hint: 'Create a strong password', icon: Icons.lock_outlined, obscureText: true),
          const SizedBox(height: 20),
          _buildTextField(controller: _signUpConfirmController, label: 'Confirm Password', hint: 'Re-enter your password', icon: Icons.lock_outlined, obscureText: true),
          const SizedBox(height: 16),
          if (auth.error != null) _buildErrorBox(auth.error!),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text("By signing up, you agree to Cambric's Terms of Service and Privacy Policy", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)), textAlign: TextAlign.center),
          ),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: auth.loading ? null : () => _handleSignUp(auth),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: auth.loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text('Create Account', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 28),
          _buildDivider(),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: auth.loading ? null : () => _handleGoogleSignIn(auth),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: Text('Sign up with Google', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDB4437), side: BorderSide(color: const Color(0xFFDB4437).withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1E3A5F)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
        hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC2626))),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('or', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13))),
        const Expanded(child: Divider()),
      ],
    );
  }

  Future<void> _handleSignIn(AuthProvider auth) async {
    final email = _signInEmailController.text.trim();
    final password = _signInPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    auth.clearError();
    final success = await auth.signInWithEmail(email, password);
    if (success && mounted) {
      widget.onAuthSuccess?.call();
      Navigator.pop(context);
    }
  }

  Future<void> _handleSignUp(AuthProvider auth) async {
    final name = _signUpNameController.text.trim();
    final email = _signUpEmailController.text.trim();
    final password = _signUpPasswordController.text;
    final confirm = _signUpConfirmController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    auth.clearError();
    final success = await auth.signUpWithEmail(email, password, displayName: name);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!'), backgroundColor: Color(0xFF22C55E)),
      );
      widget.onAuthSuccess?.call();
      Navigator.pop(context);
    }
  }

  Future<void> _handleGoogleSignIn(AuthProvider auth) async {
    auth.clearError();
    await auth.signInWithGoogle();
  }

  void _showResetPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email and we will send you a password reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              await context.read<AuthProvider>().resetPassword(email);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset email sent!'), backgroundColor: Color(0xFF22C55E)),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
