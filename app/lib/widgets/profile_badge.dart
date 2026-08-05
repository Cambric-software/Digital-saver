import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cambric_auth_service_v2.dart';
import '../services/profile_check_service.dart';
import '../screens/profile_completion_screen.dart';

/// A badge that shows profile completeness status
class ProfileCompletenessBadge extends StatelessWidget {
  final bool showOnComplete;
  
  const ProfileCompletenessBadge({
    super.key,
    this.showOnComplete = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return const SizedBox.shrink();
        }
        
        return FutureBuilder<ProfileCheckResult>(
          future: ProfileCheckService().checkProfileCompleteness(auth),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            
            final result = snapshot.data!;
            
            if (result.isComplete && !showOnComplete) {
              return const SizedBox.shrink();
            }
            
            if (result.isComplete && showOnComplete) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22C55E)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user, size: 14, color: Color(0xFF22C55E)),
                    SizedBox(width: 4),
                    Text(
                      'Profile Complete',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // Show warning badge
            return GestureDetector(
              onTap: () => _showProfileCompletion(context, result.missingFields),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${result.missingFields.length} missing',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.amber,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  void _showProfileCompletion(BuildContext context, List<String> missingFields) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileCompletionScreen(
          missingFields: missingFields,
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

/// A complete profile card widget
class EnhancedProfileCard extends StatelessWidget {
  final VoidCallback? onEdit;
  final bool expanded;
  
  const EnhancedProfileCard({
    super.key,
    this.onEdit,
    this.expanded = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return FutureBuilder<ProfileCheckResult>(
          future: ProfileCheckService().checkProfileCompleteness(auth),
          builder: (context, snapshot) {
            final result = snapshot.data;
            final profile = result?.profile;
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: result?.isComplete == true
                      ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                      : [const Color(0xFF2563EB), const Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (result?.isComplete == true 
                        ? const Color(0xFF22C55E) 
                        : const Color(0xFF2563EB)).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            _getAvatarInitial(profile, auth),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.name ?? auth.user?.email ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  result?.isComplete == true 
                                      ? Icons.verified_user 
                                      : Icons.warning_amber,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  result?.isComplete == true 
                                      ? 'Profile Complete' 
                                      : '${result?.missingFields.length ?? 0} fields missing',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (onEdit != null)
                        IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                        ),
                    ],
                  ),
                  
                  if (expanded && profile != null) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Age', profile.age > 0 ? '${profile.age}' : '--'),
                        _buildStat('Blood', profile.bloodType ?? '--'),
                        _buildStat('BMI', profile.bmi > 0 ? profile.bmi.toStringAsFixed(1) : '--'),
                        _buildStat('Weight', profile.weightKg > 0 ? '${profile.weightKg.round()}kg' : '--'),
                      ],
                    ),
                    
                    if (profile.emergencyContactName?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emergency, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Emergency Contact',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    '${profile.emergencyContactName} • ${profile.emergencyContactPhone ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  static String _getAvatarInitial(UserProfile? profile, AuthProvider auth) {
    if (profile != null && profile.name.isNotEmpty) {
      return profile.name[0].toUpperCase();
    }
    final emailInitial = auth.user?.email?[0]?.toUpperCase();
    return emailInitial ?? '?';
  }
}
