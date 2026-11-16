import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/findora_orbit_logo.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Visual Memory for Your Physical World',
      'subtitle':
          'Capture photos of your desk, shelves, backpack, or rooms. Findora indexes your surroundings with on-device computer vision so you can recall where items were left.',
      'icon': Icons.camera_alt_outlined,
      'badge': 'FINDORA ORBIT',
    },
    {
      'title': 'Bilingual Neural Search',
      'subtitle':
          'Search naturally in English or Hindi: "Where is my black charger?", "Mera chashma kahan hai?", or "Show my keys on study desk". Voice recognition with spoken summaries included.',
      'icon': Icons.mic_none_outlined,
      'badge': 'AI Multimodal Search',
    },
    {
      'title': '100% On-Device & Private',
      'subtitle':
          'No cloud servers. Your visual memories, object embeddings, and photos remain strictly inside your device\'s hardware-encrypted sandbox with optional biometric lock.',
      'icon': Icons.security_outlined,
      'badge': 'Zero Cloud Storage',
    },
    {
      'title': 'Honest Observational AI',
      'subtitle':
          'Findora displays photographic evidence with timestamps and location labels. It never claims to know where an item is right now if it was moved after the photo was taken.',
      'icon': Icons.visibility_outlined,
      'badge': 'Physical Reality First',
    },
  ];

  void _finish() {
    ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Cyberpunk background glows
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Header with Logo and Skip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const FindoraOrbitLogo(size: 28, animate: false),
                          const SizedBox(width: 10),
                          Text(
                            AppConstants.appName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _finish,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Slide Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Feature Icon or Logo Orb
                            index == 0
                                ? const FindoraOrbitLogo(size: 150, animate: true)
                                : Container(
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      color: AppColors.darkSurface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.darkBorderGlow,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.25),
                                          blurRadius: 30,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      slide['icon'] as IconData,
                                      size: 56,
                                      color: AppColors.accent,
                                    ),
                                  ),

                            const SizedBox(height: 36),

                            // Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                              ),
                              child: Text(
                                slide['badge'] as String,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Title
                            Text(
                              slide['title'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Subtitle
                            Text(
                              slide['subtitle'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.darkTextSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      // Page Indicator Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: _currentPage == i ? 24 : 6,
                            decoration: BoxDecoration(
                              color: _currentPage == i ? AppColors.accent : AppColors.darkSurfaceHighlight,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Continue / Finish Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (_currentPage < _slides.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _finish();
                            }
                          },
                          child: Text(
                            _currentPage < _slides.length - 1
                                ? 'Continue'
                                : 'Enter Findora',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Developer Credit
                      Text(
                        AppConstants.developerCredit,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
