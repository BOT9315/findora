import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/findora_orbit_logo.dart';
import '../providers/settings_provider.dart';
import 'about_screen.dart';
import 'diagnostic_logs_screen.dart';
import 'privacy_policy_screen.dart';
import '../../offline/presentation/offline_audit_screen.dart';
import '../../search/data/search_feedback_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _confirmWipeData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ALL Memories & Photos?'),
        content: const Text(
          'This action is irreversible. All captured photographs, detected object records, embeddings, and item histories will be permanently wiped from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(settingsProvider.notifier).wipeAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data has been deleted.'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  void _handleBackup(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(settingsProvider.notifier).createBackup();
    if (result.success && result.backupFilePath != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup archive created with ${result.totalMemories} memories!'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () {
              SharePlus.instance.share(ShareParams(files: [XFile(result.backupFilePath!)], text: 'FindMyStuff AI Backup'));
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feedback banner (if any)
            if (state.message != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(state.message!, style: const TextStyle(fontSize: 13, color: AppColors.success)),
                    ),
                  ],
                ),
              ),

            // Appearance Section
            _SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: RadioGroup<ThemeMode>(
                groupValue: themeMode,
                onChanged: (mode) {
                  if (mode != null) ref.read(themeModeProvider.notifier).setThemeMode(mode);
                },
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('System Default'),
                      value: ThemeMode.system,
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark Mode'),
                      value: ThemeMode.dark,
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      title: const Text('Light Mode'),
                      value: ThemeMode.light,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Security & Privacy Section
            _SectionHeader(title: 'Security & App Lock', icon: Icons.security_outlined),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Biometric App Lock'),
                    subtitle: Text(
                      state.canUseBiometrics
                          ? 'Require fingerprint, face, or PIN to open app'
                          : 'Biometrics unavailable on this device',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: state.isAppLockEnabled,
                    onChanged: (val) async {
                      await ref.read(settingsProvider.notifier).toggleAppLock(val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Spoken Search Results'),
                    subtitle: const Text(
                      'Optionally read out concise match locations using on-device TTS',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: state.speakResultsEnabled,
                    onChanged: (val) async {
                      await ref.read(settingsProvider.notifier).toggleSpeakResults(val);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                    title: const Text('Privacy & Data Processing Policy'),
                    subtitle: const Text('100% on-device vision guarantee', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined, color: AppColors.success),
                    title: const Text('Offline Privacy & Isolation Audit'),
                    subtitle: const Text('Verify local database, keystore & zero cloud sync', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const OfflineAuditScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.thumbs_up_down_outlined, color: AppColors.accent),
                    title: const Text('Search Ranking Feedback'),
                    subtitle: const Text('Reset personalized ranking preferences', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.refresh, size: 18),
                    onTap: () async {
                      final repo = SearchFeedbackRepository();
                      final count = await repo.getTotalFeedbackCount();
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Search Feedback Preferences'),
                            content: Text(
                              'You have recorded $count personalized feedback rating(s). Resetting will restore default objective visual ranking.',
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () async {
                                  await repo.clearAllFeedback();
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Search ranking preferences reset to default.')),
                                    );
                                  }
                                },
                                child: const Text('Reset Preferences'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Storage & AI Indexing Section
            _SectionHeader(title: 'Storage & AI Pipeline', icon: Icons.memory_outlined),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Storage Used', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        state.storageUsage?.formattedTotal ?? 'Calculating...',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Photos (App-Private)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text(state.storageUsage?.formattedPhotos ?? '-', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thumbnails', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text(state.storageUsage?.formattedThumbnails ?? '-', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SQLite Database', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text(state.storageUsage?.formattedDatabase ?? '-', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                    icon: const Icon(Icons.sync),
                    label: const Text('Re-index All Photographs with Vision Model'),
                    onPressed: () => ref.read(settingsProvider.notifier).reindexAllPhotos(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Backup & Restore Section
            _SectionHeader(title: 'Backup & Restore', icon: Icons.backup_outlined),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_upload_outlined, color: AppColors.primary),
                    title: const Text('Export ZIP Backup'),
                    subtitle: const Text('Exports database and photos into an archive', style: TextStyle(fontSize: 12)),
                    onTap: () => _handleBackup(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.developer_mode_outlined, color: AppColors.secondary),
                    title: const Text('Diagnostics & System Status'),
                    subtitle: const Text('View indexing logs and performance', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const DiagnosticLogsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const FindoraOrbitLogo(size: 24, animate: false),
                    title: const Text('About Findora & Developer Credit'),
                    subtitle: const Text('Never Lose What Matters. • Created & Developed by Ankush', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AboutFindoraScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Data Deletion
            _SectionHeader(title: 'Danger Zone', icon: Icons.warning_amber_outlined),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wipe All Local Memories',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Permanently deletes all saved photos, thumbnails, embeddings, and tracked object identities.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete All Local Data'),
                    onPressed: () => _confirmWipeData(context, ref),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // App Version Footer
            Center(
              child: Column(
                children: [
                  Text(
                    '${AppConstants.appName} v${AppConstants.appVersion}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.tagLine,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppConstants.developerCredit,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
