import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/diet_options.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/post_stats.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/secondary_button.dart';
import 'post_detail_screen.dart';
import 'widgets/post_card.dart';

/// Community tab: recipes posted by all users, with a search box and
/// dietary filter chips (the user's saved preferences are on by default).
class PostedRecipesScreen extends StatefulWidget {
  const PostedRecipesScreen({super.key});

  @override
  State<PostedRecipesScreen> createState() => _PostedRecipesScreenState();
}

class _PostedRecipesScreenState extends State<PostedRecipesScreen> {
  static const _debounce = Duration(milliseconds: 250);

  final _searchCtrl = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (mounted) context.read<CommunityProvider>().setSearch(text);
    });
  }

  void _clearAll() {
    _debounceTimer?.cancel();
    _searchCtrl.clear();
    context.read<CommunityProvider>().clearFilters(search: true);
  }

  /// Applies saved dietary preferences as default chips (only the
  /// difference, so manual toggles survive a change in Settings).
  void _syncDefaults(CommunityProvider community, List<String> saved) {
    if (community.defaultsApplied(saved)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) community.syncDietaryDefaults(saved);
    });
  }

  /// Preset options + the user's custom needs + any other active chip.
  List<String> _chipOptions(List<String> saved, Set<String> active) {
    final options = <String>[...kDietOptions];
    bool has(String s) =>
        options.any((o) => o.toLowerCase() == s.trim().toLowerCase());
    for (final s in [...saved, ...active]) {
      if (s.trim().isNotEmpty && !has(s)) options.add(s.trim());
    }
    return options;
  }

  /// Newest / Most liked / Most commented / Top rated.
  Widget _sortChips(CommunityProvider community) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Icon(Icons.sort_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s8),
          for (final sort in FeedSort.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s8),
              child: AppChip(
                label: sort.label,
                selected: community.sort == sort,
                onTap: () => community.setSort(sort),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChips(CommunityProvider community, List<String> saved) {
    final options = _chipOptions(saved, community.activeDiet);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s8),
              child: AppChip(
                label: option,
                selected: community.isDietActive(option),
                onTap: () => community.toggleDiet(option),
              ),
            ),
          if (community.activeDiet.isNotEmpty)
            TextButton.icon(
              onPressed: () => community.clearFilters(),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  Widget _defaultsNote(CommunityProvider community) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      child: Row(
        children: [
          const Icon(Icons.tune, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              'Showing recipes that match your dietary preferences',
              style: AppTextStyles.caption,
            ),
          ),
          TextButton(
            onPressed: () => community.clearFilters(),
            child: const Text('Show all'),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, CommunityProvider community) {
    if (community.isLoading) return const LoadingIndicator();

    if (community.errorMessage != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: community.errorMessage!,
      );
    }

    if (community.posts.isEmpty) {
      return const EmptyState(
        icon: Icons.groups_outlined,
        title: 'No posted recipes yet',
        message: 'Open a saved recipe and post it to share it with everyone.',
      );
    }

    final posts = community.visiblePosts;
    if (posts.isEmpty) {
      // Search and filters only see the loaded posts, so offer to look
      // further back before giving up.
      if (community.hasMore) {
        return EmptyState(
          icon: Icons.search_off,
          title: 'No recipes match yet',
          message: 'None of the latest recipes match. Load older recipes, '
              'or try a different search or filter.',
          actionLabel:
              community.isLoadingMore ? 'Loading...' : 'Load older recipes',
          onAction: community.isLoadingMore ? null : community.loadMore,
        );
      }
      return EmptyState(
        icon: Icons.search_off,
        title: 'No recipes match',
        message: 'Try a different search or turn off some filters.',
        actionLabel: 'Clear filters',
        onAction: _clearAll,
      );
    }

    final showLoadMore = community.hasMore;
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      itemCount: posts.length + (showLoadMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, i) {
        if (i == posts.length) {
          return SecondaryButton(
            label: 'Load more recipes',
            isLoading: community.isLoadingMore,
            onPressed: community.isLoadingMore ? null : community.loadMore,
          );
        }
        final post = posts[i];
        return PostCard(
          key: ValueKey(post.id),
          post: post,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(postId: post.id),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityProvider>();
    final saved = context.select<AuthProvider, List<String>>(
      (a) => a.dietaryNeeds,
    );
    _syncDefaults(community, saved);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s24,
          AppSpacing.s24,
          AppSpacing.s24,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Community', style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              hint: 'Search recipes, ingredients, cooks...',
              controller: _searchCtrl,
              prefixIcon: Icons.search,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (text) {
                _debounceTimer?.cancel();
                community.setSearch(text);
              },
            ),
            const SizedBox(height: AppSpacing.s12),
            _sortChips(community),
            const SizedBox(height: AppSpacing.s8),
            _filterChips(community, saved),
            if (community.filtersAreDefaults) _defaultsNote(community),
            const SizedBox(height: AppSpacing.s12),
            Expanded(child: _body(context, community)),
          ],
        ),
      ),
    );
  }
}
