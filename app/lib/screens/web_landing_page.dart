import 'package:flutter/material.dart';
import '../utils/download_helper.dart';

class WebLandingPage extends StatefulWidget {
  const WebLandingPage({super.key});

  @override
  State<WebLandingPage> createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  // Latest version
  static const String currentVersion = 'v3.4.2';
  
  // Download URLs - Exact files from v3.1.8 release
  static const String androidUrl = 'https://github.com/Cambric-software/Digital-saver/releases/download/v3.4.2/digital_saver_android_v3.4.2.apk';
  static const String windowsUrl = 'https://github.com/Cambric-software/Digital-saver/releases/download/v3.4.2/digital_saver_windows_v3.4.2.zip';
  static const String linuxUrl = 'https://github.com/Cambric-software/Digital-saver/releases/download/v3.4.2/digital_saver_linux_v3.4.2.tar.gz';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _downloadFile(String url, String filename) {
    downloadFile(url, filename);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Digital Saver Logo and Text
                  _buildLogoSection(),
                  
                  const SizedBox(height: 48),
                  
                  // Download Buttons
                  _buildDownloadButtons(),
                  
                  const SizedBox(height: 48),
                  
                  // Instructions
                  _buildInstructions(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Digital Saver Logo
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.asset(
              'assets/digital-saver-icon-transparent.png',
              width: 140,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.favorite, color: Colors.white, size: 70),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Digital Saver Text
        const Text(
          'Digital Saver',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [Shadow(color: Colors.black26, blurRadius: 20)],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Professional Health Monitoring',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Made by Cambric
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Made by ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/cambric-icon-transparent.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.business, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Cambric',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButtons() {
    return Column(
      children: [
        const Text(
          'Download App',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _DownloadButton(
              icon: Icons.android,
              label: 'Android',
              subtitle: 'APK $currentVersion',
              color: const Color(0xFF34A853),
              onTap: () => _downloadFile(androidUrl, 'digital_saver_android_v3.4.2.apk'),
            ),
            _DownloadButton(
              icon: Icons.window,
              label: 'Windows',
              subtitle: 'EXE / ZIP $currentVersion',
              color: const Color(0xFF0078D4),
              onTap: () => _downloadFile(windowsUrl, 'digital_saver_windows_v3.4.2.zip'),
            ),
            _DownloadButton(
              icon: Icons.computer,
              label: 'Linux',
              subtitle: 'AppImage / ZIP $currentVersion',
              color: const Color(0xFFE95420),
              onTap: () => _downloadFile(linuxUrl, 'digital_saver_linux_v3.4.2.tar.gz'),
            ),
            _DownloadButton(
              icon: Icons.apple,
              label: 'iOS',
              subtitle: 'Coming Soon',
              color: Colors.grey,
              onTap: null,
              isComingSoon: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white70, size: 24),
              SizedBox(width: 12),
              Text(
                'How to Download',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Windows Instructions
          _buildInstructionItem(
            icon: Icons.window,
            title: 'Windows',
            steps: const [
              '1. Click the Windows button above',
              '2. The ZIP file will download',
              '3. Extract the ZIP file',
              '4. Run the .exe file inside',
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Linux Instructions
          _buildInstructionItem(
            icon: Icons.computer,
            title: 'Linux',
            steps: const [
              '1. Click the Linux button above',
              '2. Download the AppImage or ZIP',
              '3. Make AppImage executable: chmod +x file.AppImage',
              '4. Run: ./file.AppImage',
              '   Or extract ZIP and run the executable',
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Android Instructions
          _buildInstructionItem(
            icon: Icons.android,
            title: 'Android',
            steps: const [
              '1. Click the Android button above',
              '2. Allow installation from unknown sources if needed',
              '3. Open the downloaded APK file',
              '4. Install and enjoy!',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String title,
    required List<String> steps,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...steps.map((step) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 4),
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        )),
      ],
    );
  }

}

class _DownloadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool isComingSoon;

  const _DownloadButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isComingSoon ? Colors.grey.withOpacity(0.2) : color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isComingSoon ? Colors.grey.withOpacity(0.3) : color.withOpacity(0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: isComingSoon ? Colors.grey : color,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: isComingSoon ? Colors.grey : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isComingSoon ? Colors.grey.withOpacity(0.7) : Colors.white70,
                  fontSize: 12,
                ),
              ),
              if (isComingSoon) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Coming Soon',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
