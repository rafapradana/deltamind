import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/auth/auth_controller.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A circular avatar widget used in the dashboard app bar
/// that shows the user's profile picture or initials
/// and navigates to the profile page when tapped
class ProfileAvatar extends ConsumerStatefulWidget {
  /// Creates a [ProfileAvatar]
  const ProfileAvatar({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<ProfileAvatar> {
  String? _avatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// Load profile data to get avatar URL
  Future<void> _loadProfileData() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await SupabaseService.getUserProfile(user.id);
      if (profile != null && mounted) {
        setState(() {
          _avatarUrl = profile['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint('Error loading profile avatar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.profile),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child:
            _isLoading
                ? const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                ? Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      _avatarUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildInitialsAvatar(user);
                      },
                    ),
                  ),
                )
                : _buildInitialsAvatar(user),
      ),
    );
  }

  /// Build avatar with user initials
  Widget _buildInitialsAvatar(user) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      child: Text(
        _getInitials(user),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// Get user initials for avatar
  String _getInitials(user) {
    if (user == null) return 'U';

    final email = user.email ?? '';
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }

    return 'U';
  }
}
