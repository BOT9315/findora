import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/schema_constants.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/storage/file_storage_service.dart';
import '../../memories/data/memory_repository.dart';

class DiagnosticLogsScreen extends ConsumerStatefulWidget {
  const DiagnosticLogsScreen({super.key});

  @override
  ConsumerState<DiagnosticLogsScreen> createState() => _DiagnosticLogsScreenState();
}

class _DiagnosticLogsScreenState extends ConsumerState<DiagnosticLogsScreen> {
  final MemoryRepository _memoryRepository = MemoryRepository();
  final FileStorageService _storageService = FileStorageService.instance;
  final AppLockService _appLockService = AppLockService.instance;

  int _memoryCount = 0;
  int _indexedCount = 0;
  int _failedCount = 0;
  bool _canBiometrics = false;
  String _photosPath = '';
  String _thumbsPath = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    final mCount = await _memoryRepository.getMemoryCount();
    final iCount = await _memoryRepository.getIndexedCount();
    final fCount = await _memoryRepository.getFailedIndexingCount();
    final bio = await _appLockService.canCheckBiometrics();
    final pDir = await _storageService.photosDirectory;
    final tDir = await _storageService.thumbnailsDirectory;

    if (mounted) {
      setState(() {
        _memoryCount = mCount;
        _indexedCount = iCount;
        _failedCount = fCount;
        _canBiometrics = bio;
        _photosPath = pDir.path;
        _thumbsPath = tDir.path;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics & Status'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DiagnosticCard(
                    title: 'On-Device AI Engine',
                    icon: Icons.psychology_outlined,
                    isDark: isDark,
                    items: const [
                      {'key': 'Vision Pipeline', 'value': 'Visual Feature & Pattern Segmenter'},
                      {'key': 'Embedding Space', 'value': '64-Dimensional L2-Normalized Dense Vector'},
                      {'key': 'Cosine Similarity', 'value': 'Enabled (Real-time Matrix)'},
                      {'key': 'Network Access', 'value': 'Offline / 0 Cloud Requests'},
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DiagnosticCard(
                    title: 'Database & Indexing',
                    icon: Icons.storage_outlined,
                    isDark: isDark,
                    items: [
                      {'key': 'SQLite Database', 'value': SchemaConstants.databaseName},
                      {'key': 'Schema Version', 'value': 'v${SchemaConstants.databaseVersion}'},
                      {'key': 'Saved Memories', 'value': '$_memoryCount'},
                      {'key': 'Successfully Indexed', 'value': '$_indexedCount'},
                      {'key': 'Failed Indexing', 'value': '$_failedCount'},
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DiagnosticCard(
                    title: 'Storage & Security',
                    icon: Icons.security_outlined,
                    isDark: isDark,
                    items: [
                      {'key': 'Biometric Hardware', 'value': _canBiometrics ? 'Supported' : 'Unavailable'},
                      {'key': 'Photos Storage', 'value': _photosPath},
                      {'key': 'Thumbnails Storage', 'value': _thumbsPath},
                      {'key': 'Key Storage', 'value': 'Android EncryptedSharedPreferences'},
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DiagnosticCard(
                    title: 'Platform & Build',
                    icon: Icons.phone_android_outlined,
                    isDark: isDark,
                    items: [
                      {'key': 'Platform OS', 'value': Platform.operatingSystem},
                      {'key': 'Operating Version', 'value': Platform.operatingSystemVersion},
                      {'key': 'App Version', 'value': AppConstants.appVersion},
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final List<Map<String, String>> items;

  const _DiagnosticCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      item['key']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['value']!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
