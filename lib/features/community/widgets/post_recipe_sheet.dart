import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/media_service.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/photo_source_sheet.dart';
import '../../../shared/widgets/primary_button.dart';

/// What the user filled in before posting.
class PostDraft {
  final String caption;

  /// Compressed base64 JPEG, or null for no photo (default image is shown).
  final String? photoBase64;

  const PostDraft({required this.caption, this.photoBase64});
}

/// Bottom sheet asking for an optional caption and photo before posting.
/// Returns the draft, or null if dismissed.
Future<PostDraft?> showPostRecipeSheet(
  BuildContext context, {
  required String recipeName,
}) {
  return showModalBottomSheet<PostDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r24)),
    ),
    builder: (_) => _PostRecipeSheet(recipeName: recipeName),
  );
}

class _PostRecipeSheet extends StatefulWidget {
  final String recipeName;
  const _PostRecipeSheet({required this.recipeName});

  @override
  State<_PostRecipeSheet> createState() => _PostRecipeSheetState();
}

class _PostRecipeSheetState extends State<_PostRecipeSheet> {
  static const _maxLength = 200;
  static const _previewHeight = 180.0;

  final _ctrl = TextEditingController();
  final _media = MediaService();

  String? _photoB64;
  Uint8List? _photoBytes; // decoded once for the preview
  bool _processing = false;
  String? _photoError;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showPhotoSourceSheet(context);
    if (source == null || !mounted) return;

    setState(() {
      _processing = true;
      _photoError = null;
    });
    try {
      final b64 = await _media.pickPhoto(source);
      if (!mounted) return;
      if (b64 != null) {
        _photoB64 = b64;
        _photoBytes = base64Decode(b64);
      }
    } on MediaException catch (e) {
      if (mounted) _photoError = e.message;
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _removePhoto() {
    setState(() {
      _photoB64 = null;
      _photoBytes = null;
      _photoError = null;
    });
  }

  void _submit() {
    var caption = _ctrl.text.trim();
    if (caption.length > _maxLength) caption = caption.substring(0, _maxLength);
    Navigator.pop(context, PostDraft(caption: caption, photoBase64: _photoB64));
  }

  Widget _photoArea() {
    if (_processing) {
      return _box(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Preparing photo...',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final bytes = _photoBytes;
    if (bytes != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r16),
            child: SizedBox(
              height: _previewHeight,
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                cacheWidth: 800,
                gaplessPlayback: true,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Change'),
              ),
              TextButton.icon(
                onPressed: _removePhoto,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      );
    }

    return InkWell(
      onTap: _pickPhoto,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: _box(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Add a photo (optional)',
              style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Without one, a default picture is shown.',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _box({required Widget child}) {
    return Container(
      height: 140,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        // Lifts the sheet above the keyboard.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24,
            AppSpacing.s12,
            AppSpacing.s24,
            AppSpacing.s24,
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
              const SizedBox(height: AppSpacing.s24),
              Text('Post to community', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Share "${widget.recipeName}" so other cooks can view, rate and comment on it.',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              _photoArea(),
              if (_photoError != null) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  _photoError!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.s16),
              AppTextField(
                hint: 'Add a caption (optional)',
                controller: _ctrl,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: AppSpacing.s24),
              PrimaryButton(
                label: 'Post Recipe',
                onPressed: _processing ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
