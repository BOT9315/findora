import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../ar/presentation/ar_visual_finder_screen.dart';
import '../../memories/presentation/memory_detail_screen.dart';
import '../domain/search_query_model.dart';
import '../domain/search_result_item.dart';
import '../providers/search_provider.dart';
import '../services/voice_search_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isListening = false;
  String _liveSpokenWords = '';
  String _voiceLanguage = 'en'; // 'en' for English, 'hi' for Hindi / Hinglish

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchProvider.notifier).search(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    VoiceSearchService.instance.stopListening();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await VoiceSearchService.instance.stopListening();
      setState(() => _isListening = false);
      return;
    }

    setState(() {
      _isListening = true;
      _liveSpokenWords = '';
    });

    final started = await VoiceSearchService.instance.startListening(
      localeId: _voiceLanguage == 'hi' ? 'hi_IN' : 'en_IN',
      onResult: (words, isFinal) {
        setState(() {
          _liveSpokenWords = words;
          _searchController.text = words;
        });
        if (isFinal && words.trim().isNotEmpty) {
          _onQuerySubmitted(words.trim());
        }
      },
      onDone: () {
        if (mounted) {
          setState(() => _isListening = false);
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              action: SnackBarAction(
                label: 'Use Keyboard',
                onPressed: () {},
              ),
            ),
          );
        }
      },
    );

    if (!started && mounted) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _pickImageForSearch() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _searchController.text = 'Photo search';
      ref.read(searchProvider.notifier).searchWithImage(
            File(image.path),
            queryLabel: 'Photo reference query',
          );
    }
  }

  void _onQuerySubmitted(String val) async {
    await ref.read(searchProvider.notifier).search(val);
    final results = ref.read(searchProvider).results;
    if (results.isNotEmpty) {
      final top = results.first;
      final label = top.matchedObject?.label ?? 'item';
      final msg = 'Found $label in ${top.memory.locationLabel}, photographed ${DateFormat.yMMMd().format(top.memory.capturedAt)}.';
      await VoiceSearchService.instance.speakResultIfEnabled(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Belongings'),
        actions: [
          IconButton(
            tooltip: 'Live AR Finder',
            icon: const Icon(Icons.view_in_ar, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArVisualFinderScreen(
                    targetItemName: state.query.isNotEmpty ? state.query : null,
                    targetLocation: state.locationFilter,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search input box with Multimodal Visual trigger
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _onQuerySubmitted,
              decoration: InputDecoration(
                hintText: 'e.g. "Where is my college ID?", "black charger"',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchProvider.notifier).search('');
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.image_search, color: AppColors.primary),
                      tooltip: 'Search with reference photo',
                      onPressed: _pickImageForSearch,
                    ),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : AppColors.primary,
                      ),
                      tooltip: _isListening ? 'Listening...' : 'Voice search',
                      onPressed: _toggleVoiceSearch,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Active Voice Listening Indicator with Language Switcher
          if (_isListening)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _liveSpokenWords.isEmpty
                              ? (_voiceLanguage == 'hi' ? 'सुन रहा हूँ... बोलिए ("मेरा चार्जर कहाँ है")' : 'Listening... Speak your query')
                              : '"$_liveSpokenWords"',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        Text(
                          'Language: ${_voiceLanguage == 'hi' ? 'हिन्दी / Hinglish' : 'English'}',
                          style: TextStyle(fontSize: 10, color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                  // Voice Language Selector Button
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(44, 28)),
                    onPressed: () {
                      setState(() {
                        _voiceLanguage = _voiceLanguage == 'en' ? 'hi' : 'en';
                      });
                      // Restart listening with new locale
                      _toggleVoiceSearch().then((_) => _toggleVoiceSearch());
                    },
                    child: Text(
                      _voiceLanguage == 'en' ? 'हिन्दी' : 'EN',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: _toggleVoiceSearch,
                    child: const Text('Stop', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Filters Row (Date, Room, Category, Color Filters)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // 1. Time Filter Dropdown / Menu
                PopupMenuButton<TimeFilter>(
                  tooltip: 'Filter by Time',
                  initialValue: state.timeFilter,
                  onSelected: (filter) {
                    ref.read(searchProvider.notifier).setTimeFilter(filter);
                  },
                  itemBuilder: (context) => TimeFilter.values.map((f) {
                    return PopupMenuItem(
                      value: f,
                      child: Text(f.displayName),
                    );
                  }).toList(),
                  child: Chip(
                    avatar: const Icon(Icons.schedule, size: 14),
                    label: Text(state.timeFilter.displayName),
                    backgroundColor: state.timeFilter != TimeFilter.any
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Location / Room Filter Dropdown
                PopupMenuButton<String?>(
                  tooltip: 'Filter by Location',
                  initialValue: state.locationFilter,
                  onSelected: (loc) {
                    ref.read(searchProvider.notifier).setLocationFilter(loc);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String?>(
                      value: null,
                      child: Text('All Locations'),
                    ),
                    ...AppConstants.defaultLocations.map((loc) {
                      return PopupMenuItem<String?>(
                        value: loc,
                        child: Text(loc),
                      );
                    }),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.place_outlined, size: 14),
                    label: Text(state.locationFilter ?? 'All Locations'),
                    backgroundColor: state.locationFilter != null
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Category Filter Dropdown
                PopupMenuButton<String?>(
                  tooltip: 'Filter by Category',
                  initialValue: state.categoryFilter,
                  onSelected: (cat) {
                    ref.read(searchProvider.notifier).setCategoryFilter(cat);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...['Keys', 'Charger', 'College ID', 'Wallet', 'Headphones', 'Glasses', 'Backpack', 'Watch', 'Water Bottle', 'Laptop'].map((cat) {
                      return PopupMenuItem<String?>(
                        value: cat,
                        child: Text(cat),
                      );
                    }),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.category_outlined, size: 14),
                    label: Text(state.categoryFilter ?? 'All Categories'),
                    backgroundColor: state.categoryFilter != null
                        ? AppColors.secondary.withValues(alpha: 0.15)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),

                // 4. Color Filter Dropdown
                PopupMenuButton<String?>(
                  tooltip: 'Filter by Color',
                  initialValue: state.colorFilter,
                  onSelected: (col) {
                    ref.read(searchProvider.notifier).setColorFilter(col);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String?>(
                      value: null,
                      child: Text('All Colors'),
                    ),
                    ...['black', 'white', 'blue', 'red', 'green', 'yellow', 'silver', 'brown', 'grey', 'orange', 'purple', 'pink'].map((col) {
                      final title = col[0].toUpperCase() + col.substring(1);
                      return PopupMenuItem<String?>(
                        value: col,
                        child: Text(title),
                      );
                    }),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.palette_outlined, size: 14),
                    label: Text(state.colorFilter != null
                        ? state.colorFilter![0].toUpperCase() + state.colorFilter!.substring(1)
                        : 'All Colors'),
                    backgroundColor: state.colorFilter != null
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),

                // Clear Filters Action Chip
                if (state.hasActiveFilters)
                  ActionChip(
                    avatar: const Icon(Icons.close, size: 14),
                    label: const Text('Clear All Filters'),
                    onPressed: () {
                      ref.read(searchProvider.notifier).clearFilters();
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Content Area (Results or Empty/Loading)
          Expanded(
            child: state.isSearching
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Analyzing photos & semantic visual embeddings...'),
                      ],
                    ),
                  )
                : state.hasSearched
                    ? state.results.isEmpty
                        ? _SearchEmptyState(
                            query: state.query,
                            onSuggestionTap: (suggest) {
                              _searchController.text = suggest;
                              _onQuerySubmitted(suggest);
                            },
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: state.results.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = state.results[index];
                              return _SearchResultCard(item: item);
                            },
                          )
                    : _InitialSearchGuide(
                        onSuggestionTap: (suggest) {
                          _searchController.text = suggest;
                          _onQuerySubmitted(suggest);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends ConsumerWidget {
  final SearchResultItem item;

  const _SearchResultCard({required this.item});

  void _showExplainabilitySheet(BuildContext context, SearchResultItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final b = item.scoreBreakdown;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Match Explanation & Scoring',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.matchReason,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 14),
              _ScoreBar(label: 'AI Visual Semantic Similarity', score: b.semanticScore, color: AppColors.primary),
              const SizedBox(height: 8),
              _ScoreBar(label: 'Object & Attribute Recognition', score: b.objectScore, color: AppColors.secondary),
              const SizedBox(height: 8),
              _ScoreBar(label: 'Room & Metadata Match', score: b.metadataScore, color: Colors.teal),
              const SizedBox(height: 8),
              _ScoreBar(label: 'Observation Recency', score: b.recencyScore, color: Colors.amber),
              if (b.feedbackBoost != 0.0) ...[
                const SizedBox(height: 8),
                _ScoreBar(
                  label: b.feedbackBoost > 0 ? 'User Feedback Boost (+20%)' : 'User Feedback Penalty (-35%)',
                  score: b.feedbackBoost.abs(),
                  color: b.feedbackBoost > 0 ? AppColors.success : AppColors.danger,
                ),
              ],
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Combined Ranking Score:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${(item.combinedScore * 100).toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.observationDisclaimer,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final file = File(item.memory.thumbnailPath);
    final fallbackFile = File(item.memory.imagePath);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MemoryDetailScreen(
              memoryId: item.memory.id,
              highlightedObjectId: item.matchedObject?.id,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail with Matched Object Bounding Box Highlight
                Container(
                  width: 110,
                  height: 110,
                  color: isDark ? AppColors.darkSurfaceHighlight : AppColors.lightSurfaceHighlight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      file.existsSync()
                          ? Image.file(file, fit: BoxFit.cover)
                          : fallbackFile.existsSync()
                              ? Image.file(fallbackFile, fit: BoxFit.cover)
                              : const Icon(Icons.photo, color: Colors.grey),
                      if (item.matchedObject?.boundingBox != null)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final box = item.matchedObject!.boundingBox!;
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;
                            return Positioned(
                              left: box.left * w,
                              top: box.top * h,
                              width: box.width * w,
                              height: box.height * h,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.warning, width: 2),
                                  borderRadius: BorderRadius.circular(3),
                                  color: AppColors.warning.withValues(alpha: 0.2),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                // Metadata and Match Reason
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.memory.locationLabel,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => _showExplainabilitySheet(context, item),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(item.combinedScore * 100).toInt()}% match',
                                      style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.info_outline, size: 11, color: AppColors.secondary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.matchedObject?.label ?? 'Sighted Object',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(item.memory.capturedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.matchReason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Honest AI Observation Disclaimer & Search Feedback Actions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceHighlight,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 12, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.observationDisclaimer,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Feedback Thumbs Up
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      ref.read(searchProvider.notifier).setFeedback(item.memory.id, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Marked match as relevant (+20% ranking boost)'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Icon(
                        item.userFeedback == 1 ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        size: 15,
                        color: item.userFeedback == 1 ? AppColors.success : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Feedback Thumbs Down
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      ref.read(searchProvider.notifier).setFeedback(item.memory.id, false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Marked match as irrelevant (-35% ranking penalty)'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Icon(
                        item.userFeedback == -1 ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                        size: 15,
                        color: item.userFeedback == -1 ? AppColors.danger : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final Color color;

  const _ScoreBar({required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text('${(clamped * 100).toInt()}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clamped,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  final String query;
  final Function(String) onSuggestionTap;

  const _SearchEmptyState({required this.query, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No matches for "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try searching by object category, color, or a broader room label.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                'Charger',
                'Keys',
                'Wallet',
                'College ID',
                'Backpack',
              ].map((s) {
                return ActionChip(
                  label: Text(s),
                  onPressed: () => onSuggestionTap(s),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialSearchGuide extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const _InitialSearchGuide({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Try asking:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...[
            'Where is my college ID?',
            'Find my black charger',
            'When did I last see my keys?',
            'Show my headphones near my study table',
            'Wallet near my backpack',
            'Photos from yesterday',
          ].map((prompt) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.search, size: 18, color: AppColors.primary),
                title: Text(prompt, style: const TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.north_west, size: 14, color: Colors.grey),
                onTap: () => onSuggestionTap(prompt),
              ),
            );
          }),
        ],
      ),
    );
  }
}
