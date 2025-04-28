import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/auth/auth_controller.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A circular avatar widget used in the dashboard app bar
/// that shows the user's initials and navigates to the profile page
/// when tapped
class ProfileAvatar extends ConsumerWidget {
  /// Creates a [ProfileAvatar]
  const ProfileAvatar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.profile),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            _getInitials(user),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
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
