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
            'Your name and email, the recipes you generate, the categories '
                'you create, and the recipes you save.',
          ),
          (
            'What other users can see',
            'Recipes you post, their ratings, and your comments are visible to '
                'other signed-in users, together with your name.',
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
