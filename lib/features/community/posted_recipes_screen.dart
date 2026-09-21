import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/community_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'post_detail_screen.dart';
import 'widgets/post_card.dart';

/// Community tab: recipes posted by all users.
class PostedRecipesScreen extends StatelessWidget {
  const PostedRecipesScreen({super.key});

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

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      itemCount: community.posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, i) {
        final post = community.posts[i];
        return PostCard(
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s24, AppSpacing.s24, AppSpacing.s24, 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Community', style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.s16),
            Expanded(child: _body(context, community)),
          ],
        ),
      ),
    );
  }
}
