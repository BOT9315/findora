import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Data Processing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: AppColors.primary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Privacy By Design: Your photos and data never leave your phone.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _PolicySection(
              title: '1. Local On-Device AI Inference',
              content:
                  'Object recognition, color histogram extraction, visual segmentation, and 64-dimensional semantic embeddings run 100% locally on your smartphone using on-device processors. No photographs or features are ever uploaded to cloud servers or remote third-party AI models.',
              isDark: isDark,
            ),
            _PolicySection(
              title: '2. App-Private Managed Storage',
              content:
                  'Photographs and thumbnails are written directly into app-private isolated internal storage. Other third-party apps on your device cannot access or read your visual memory vault.',
              isDark: isDark,
            ),
            _PolicySection(
              title: '3. What Data Is Collected',
              content:
                  'Only information you explicitly capture is stored: photographs, timestamps, room/space labels you select, and optional notes. We do not access your contacts, microphone, precise GPS coordinates, or advertising identifiers.',
              isDark: isDark,
            ),
            _PolicySection(
              title: '4. Biometric App Lock & Keys',
              content:
                  'When enabled, biometric authentication protects access using the device\'s hardware-backed Keystore / Secure Enclave. Master encryption keys are stored inside secure system hardware.',
              isDark: isDark,
            ),
            _PolicySection(
              title: '5. Honest Observation Guarantee',
              content:
                  'FindMyStuff AI indexes visual observations from historical photos. It never claims to have telepathic or real-time knowledge of an item\'s current physical presence. If an item was moved after taking the photo, the application reflects only the last photographed sighting.',
              isDark: isDark,
            ),
            _PolicySection(
              title: '6. Full User Data Ownership & Deletion',
              content:
                  'You own all your data. You can delete individual memories, export an offline ZIP backup of all photos and metadata, or wipe all records permanently with a single tap in Settings.',
              isDark: isDark,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;
  final bool isDark;

  const _PolicySection({
    required this.title,
    required this.content,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
