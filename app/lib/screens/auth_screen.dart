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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A5F),
              Color(0xFF2563EB),
              Color(0xFF7C3AED),
            ],
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
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFF2563EB),
                      size: 50,
                    ),
                  ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                  
                  const SizedBox(height: 30),
                  
                  // Title
                  Text(
                    'CAMBRIC',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 4,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Digital Saver',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Health Monitoring System',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                  
                  const SizedBox(height: 50),
                  
                  // Big White Box - Tall and wide
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.75,
                    ),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tab Bar
                        Container(
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
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            unselectedLabelStyle: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            tabs: const [
                              Tab(text: 'Sign In'),
                              Tab(text: 'Sign Up'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Tab Content - Tall
                        SizedBox(
                          height: 600,
                          child: TabBarView(
                            controller: _tabController,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildSignInForm(),
                              _buildSignUpForm(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideY(begin: 0.1),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome back',
            style: GoogleFonts.inter(
              fontSize: 26,
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
          
          _buildTextField(
            controller: emailController,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: passwordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outlined,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          
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
          
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14)),
                  ),
                ],
              ),
            ),
          
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _error = null);
                if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
                  setState(() => _error = 'Please enter email and password');
                  return;
                }
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : Text('Sign In', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          
          const SizedBox(height: 28),
          
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('or', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                await auth.signInWithGoogle();
              },
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: Text('Continue with Google', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDB4437),
                side: BorderSide(color: const Color(0xFFDB4437).withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create account',
            style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A5F)),
          ),
          const SizedBox(height: 8),
          Text(
            'Join Cambric health ecosystem',
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),
          
          _buildTextField(controller: nameController, label: 'Full Name', hint: 'John Doe', icon: Icons.person_outlined),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: emailController, label: 'Email', hint: 'you@example.com',
            icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: passwordController, label: 'Password', hint: 'Create a strong password',
            icon: Icons.lock_outlined, obscureText: true,
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: confirmController, label: 'Confirm Password', hint: 'Re-enter your password',
            icon: Icons.lock_outlined, obscureText: true,
          ),
          const SizedBox(height: 16),
          
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14))),
                ],
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'By signing up, you agree to Cambric\'s Terms of Service and Privacy Policy',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _error = null);
                
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : Text('Create Account', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          
          const SizedBox(height: 28),
          
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('or', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                await auth.signInWithGoogle();
              },
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: Text('Sign up with Google', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDB4437),
                side: BorderSide(color: const Color(0xFFDB4437).withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
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
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: GoogleFonts.inter(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 22),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Password', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email to receive a password reset link.', style: GoogleFonts.inter(fontSize: 14)),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                context.read<AuthProvider>().resetPassword(emailController.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset email sent!'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
