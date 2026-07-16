import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/ble_service.dart';
import '../services/emergency_service.dart';
import '../services/storage_service.dart';
import '../services/user_profile_service.dart';
import '../services/cambric_auth_service.dart';
import '../services/smart_data_service.dart';
import '../models/health_models.dart';
import 'auth_screen.dart';
class _CambricAccountCard extends StatelessWidget {
  final bool isAuthenticated;
  final CambricUserProfile? profile;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  const _CambricAccountCard({
    required this.isAuthenticated,
    this.profile,
    required this.onSignIn,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAuthenticated
              ? [const Color(0xFF2563EB), const Color(0xFF7C3AED)]
              : [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isAuthenticated
                ? const Color(0xFF2563EB).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'CAMBRIC',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const Spacer(),
              if (isAuthenticated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Connected',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // User Info or Sign In
          if (isAuthenticated) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    (profile?.displayName ?? profile?.email ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? 'Cambric User',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        profile?.email ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout, size: 18),
                label: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            const Icon(Icons.account_circle, color: Color(0xFF2563EB), size: 48),
            const SizedBox(height: 12),
            Text(
              'Sign in to Cambric',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Access your health data across all Cambric products',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSignIn,
                    icon: const Icon(Icons.login, size: 18),
                    label: Text('Sign In', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}

// ===========================================================================
// SYNC STATUS CARD
// ===========================================================================

class _SyncStatusCard extends StatefulWidget {
  final String? userId;

  const _SyncStatusCard({this.userId});

  @override
  State<_SyncStatusCard> createState() => _SyncStatusCardState();
}

class _SyncStatusCardState extends State<_SyncStatusCard> {
  final UserProfileService _service = UserProfileService();
  SyncStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await _service.getSyncStatus(widget.userId);
    if (mounted) {
      setState(() {
        _status = status;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_sync, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              Text(
                'Cloud Sync',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _status?.needsSync == true
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status?.statusText ?? 'Unknown',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _status?.needsSync == true
                        ? const Color(0xFFD97706)
                        : const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_status?.lastSyncTime != null) ...[
            Text(
              'Last synced: ${_formatLastSync(_status!.lastSyncTime!)}',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
            ),
          ] else ...[
            Text(
              'Your data will sync automatically when signed in',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  String _formatLastSync(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

// ===========================================================================
// DATA MANAGEMENT CARD
// ===========================================================================

class _DataManagementCard extends StatefulWidget {
  final String? userId;

  const _DataManagementCard({this.userId});

  @override
  State<_DataManagementCard> createState() => _DataManagementCardState();
}

class _DataManagementCardState extends State<_DataManagementCard> {
  final SmartDataService _dataService = SmartDataService();
  StorageStats? _stats;
  bool _loading = true;
  bool _cleaning = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (widget.userId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final stats = await _dataService.getStorageStats(widget.userId!);
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _performCleanup() async {
    if (widget.userId == null) return;

    setState(() => _cleaning = true);

    try {
      final report = await _dataService.performSmartCleanup(widget.userId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(report.summary),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cleanup failed. Please try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _cleaning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null || _loading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              Text(
                'Data Management',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Storage Usage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Storage Used',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
              ),
              Text(
                _stats?.formattedSize ?? 'Calculating...',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Total Records
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Records',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
              ),
              Text(
                '${_stats?.totalRecords ?? 0}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          // Smart Cleanup Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cleaning ? null : _performCleanup,
              icon: _cleaning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high, size: 18),
              label: Text(
                _cleaning ? 'Cleaning...' : 'Smart Cleanup',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Removes redundant data while preserving important health trends',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
