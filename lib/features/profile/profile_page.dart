import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_colors.dart';
import 'package:deltamind/features/auth/auth_controller.dart';
import 'package:deltamind/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Profile page
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoading = false;
  Map<String, dynamic>? _profileData;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  /// Load user profile data
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final profile = await SupabaseService.getUserProfile(user.id);
        setState(() {
          _profileData = profile;
          _usernameController.text = profile?['username'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Update user profile
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        await SupabaseService.updateUserProfile(
          userId: user.id,
          username: _usernameController.text,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: AppColors.success,
          ),
        );

        await _loadProfile();
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Sign out user
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading ? null : _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  _buildProfileHeader(user),
                  const SizedBox(height: 24),

                  // Profile form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Information',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a username';
                                }
                                if (value.length < 3) {
                                  return 'Username must be at least 3 characters long';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _updateProfile,
                                child: const Text('Update Profile'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Account section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            title: const Text('Email'),
                            subtitle: Text(user?.email ?? 'Not available'),
                            leading: const Icon(Icons.email, color: AppColors.primary),
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text('User ID'),
                            subtitle: Text(
                              user?.id ?? 'Not available',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            leading: const Icon(Icons.perm_identity, color: AppColors.secondary),
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text('Joined'),
                            subtitle: Text(
                              user?.createdAt != null
                                  ? _formatDate(DateTime.parse(user!.createdAt))
                                  : 'Not available',
                            ),
                            leading: const Icon(Icons.calendar_today, color: AppColors.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            title: const Text('Sign Out'),
                            leading: const Icon(Icons.logout, color: AppColors.error),
                            onTap: _isLoading ? null : _signOut,
                          ),
                          // More actions can be added here
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Build profile header with avatar and name
  Widget _buildProfileHeader(user) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              _getInitials(),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _profileData?['username'] ?? user?.email?.split('@').first ?? 'User',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  /// Get user initials for avatar
  String _getInitials() {
    final username = _profileData?['username'] ?? '';
    if (username.isNotEmpty) {
      return username[0].toUpperCase();
    }
    
    final email = SupabaseService.currentUser?.email ?? '';
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    
    return 'U';
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 