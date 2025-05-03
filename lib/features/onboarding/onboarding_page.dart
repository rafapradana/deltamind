import 'package:deltamind/core/constants/app_constants.dart';
import 'package:deltamind/core/routing/app_router.dart';
import 'package:deltamind/core/theme/app_theme.dart';
import 'package:deltamind/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Onboarding page with introduction to app features
class OnboardingPage extends StatefulWidget {
  /// Onboarding page constructor
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Create Automatic Quizzes',
      description:
          'Input your learning material and our AI generates personalized quizzes to help you study effectively.',
      icon: Icons.quiz,
    ),
    OnboardingSlide(
      title: 'Active Learning',
      description:
          'No more passive learning. Engage with your study materials through interactive quizzes and tests.',
      icon: Icons.psychology,
    ),
    OnboardingSlide(
      title: 'Analytics Dashboard',
      description:
          'Visualize your learning journey with detailed analytics. Track performance over time, identify weak areas, and see your improvement patterns.',
      icon: Icons.analytics,
    ),
    OnboardingSlide(
      title: 'Gamification',
      description:
          'Stay motivated with streak tracking, levels, achievements, and streak freeze features. Turn learning into a rewarding journey and compete with yourself.',
      icon: Icons.emoji_events,
    ),
    OnboardingSlide(
      title: 'Smart Notes',
      description:
          'Create and organize your study notes with our powerful note-taking feature. Easily reference your notes while preparing for quizzes.',
      icon: Icons.note_alt,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _navigateToLogin() {
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_slides[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildPageIndicator(),
                  ),
                  const SizedBox(height: 32),
                  _currentPage == _slides.length - 1
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _navigateToLogin,
                            child: const Text('Get Started'),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _navigateToLogin,
                              child: const Text('Skip'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeIn,
                                );
                              },
                              child: const Text('Next'),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            slide.icon,
            size: 100.0,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            style: AppTheme.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.description,
            style: AppTheme.bodyText,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageIndicator() {
    final List<Widget> indicators = [];
    for (int i = 0; i < _slides.length; i++) {
      indicators.add(
        Container(
          width: 10.0,
          height: 10.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == i
                ? AppTheme.primaryColor
                : AppTheme.borderColor,
          ),
        ),
      );
    }
    return indicators;
  }
}

/// Model class for onboarding slide content
class OnboardingSlide {
  /// Title of the slide
  final String title;

  /// Description text
  final String description;

  /// Icon to display
  final IconData icon;

  /// Constructor
  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
  });
}
