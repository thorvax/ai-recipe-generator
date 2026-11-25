import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// A simple read-only page made of headings + paragraphs.
/// Used for "About" and "Privacy Policy".
class InfoScreen extends StatelessWidget {
  final String title;
  final List<(String, String)> sections; // (heading, body)

  const InfoScreen({super.key, required this.title, required this.sections});

  factory InfoScreen.about() => const InfoScreen(
        title: 'About',
        sections: [
          (
            'MealMind',
            'MealMind turns the ingredients you already have at home into a '
                'recipe with measurements and step-by-step instructions.',
          ),
          (
            'How it works',
            'Your ingredients and preferences are sent to Google\'s Gemini AI, '
                'which writes the recipe. You can save recipes into categories '
                'and share them with the community.',
          ),
          (
            'Built with',
            'Flutter, Firebase, and the Gemini API. This is a student group '
                'project.',
          ),
          ('Version', '1.0.0'),
        ],
      );

  // NOTE: placeholder wording for a school project. Review it as a team.
  factory InfoScreen.privacy() => const InfoScreen(
        title: 'Privacy Policy',
        sections: [
          (
            'What we store',
            'Your username and email, the recipes you generate, the categories '
                'you create, and the recipes you save.',
          ),
          (
            'What other users can see',
            'Recipes you post, their ratings, and your comments are visible to '
                'other signed-in users, together with your username.',
          ),
          (
            'Photos',
            'Your profile picture, and any photos you add to posted recipes '
                'or comments, are compressed and stored in our database. '
                'Other signed-in users can see them. If you sign in with '
                'Google and have not set your own picture, your Google '
                'profile photo is shown instead. Removing your profile '
                'picture, deleting a post, or deleting a comment removes '
                'that photo. Only share photos you are comfortable making '
                'visible to other users.',
          ),
          (
            'Reports and moderation',
            'If you report a post, comment or profile picture, we store your '
                'report: what you reported, the reason you picked, any '
                'details you wrote, and your account ID. Only MealMind admins '
                'can read reports, and the person you reported is never told '
                'who reported them. Admins can delete any post or comment and '
                'remove any uploaded profile picture that breaks the rules. '
                'Admins cannot see your email, your password or your saved '
                'recipes.',
          ),
          (
            'AI-generated recipes',
            'The ingredients and notes you type are sent to Google\'s Gemini '
                'API to create recipes. Please do not enter personal '
                'information. Recipes are AI-generated and are not nutritional '
                'or medical advice; always check for allergens yourself.',
          ),
          (
            'Academic project',
            'MealMind is a school project and is not intended for public '
                'release.',
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(title, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s24),
          children: [
            for (final (heading, body) in sections) ...[
              Text(heading, style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.s8),
              Text(
                body,
                style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s24),
            ],
          ],
        ),
      ),
    );
  }
}
