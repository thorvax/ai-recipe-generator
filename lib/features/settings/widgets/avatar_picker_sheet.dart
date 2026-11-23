import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

enum AvatarAction { camera, gallery, remove }

/// Take photo / Choose from gallery / Remove photo.
/// Returns the chosen action, or null if dismissed.
Future<AvatarAction?> showAvatarPickerSheet(
  BuildContext context, {
  required bool canRemove,
}) {
  return showModalBottomSheet<AvatarAction>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s8,
          AppSpacing.s12,
          AppSpacing.s8,
          AppSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.r4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Text('Profile photo', style: AppTextStyles.heading2),
            ),
            _tile(
              ctx,
              Icons.photo_camera_outlined,
              'Take photo',
              AvatarAction.camera,
            ),
            _tile(
              ctx,
              Icons.photo_library_outlined,
              'Choose from gallery',
              AvatarAction.gallery,
            ),
            if (canRemove)
              _tile(
                ctx,
                Icons.delete_outline,
                'Remove photo',
                AvatarAction.remove,
                color: AppColors.error,
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _tile(
  BuildContext ctx,
  IconData icon,
  String label,
  AvatarAction action, {
  Color color = AppColors.textPrimary,
}) {
  return ListTile(
    leading: Icon(icon, color: color),
    title: Text(label, style: AppTextStyles.body1.copyWith(color: color)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.r12),
    ),
    onTap: () => Navigator.pop(ctx, action),
  );
}
