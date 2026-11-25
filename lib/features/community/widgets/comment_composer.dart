import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/comment.dart';
import '../../../services/media_service.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/photo_source_sheet.dart';

/// What the composer sends.
class CommentDraft {
  /// Document id for this comment. The same draft sent again after an
  /// error keeps its id, so the retry cannot create a duplicate.
  final String id;
  final String text;
  final String? photoBase64;

  /// Top-level comment being replied to (null = new top-level comment).
  final String? parentId;
  final String? replyToUserName;

  const CommentDraft({
    required this.id,
    required this.text,
    this.photoBase64,
    this.parentId,
    this.replyToUserName,
  });
}

/// Comment box: "Replying to …" bar, photo attach, thumbnail and send.
///
/// Call [CommentComposerState.startReply] (through a GlobalKey) to reply.
class CommentComposer extends StatefulWidget {
  /// Sends the draft. Returns an error message, or null on success
  /// (the composer then clears itself).
  final Future<String?> Function(CommentDraft draft) onSend;

  const CommentComposer({super.key, required this.onSend});

  @override
  State<CommentComposer> createState() => CommentComposerState();
}

class CommentComposerState extends State<CommentComposer> {
  static const _maxLength = 500;
  static const _thumbSize = 64.0;

  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _media = MediaService();

  String? _parentId;
  String? _replyToName;
  String? _mention; // "@Name " pre-filled for a reply to a reply

  String? _photoB64;
  Uint8List? _photoBytes;
  bool _processing = false;
  bool _sending = false;
  String? _error;

  // Id of the draft being sent, and what it contained. Reused only when
  // the user retries the exact same comment after an error.
  String? _draftId;
  String? _draftSignature;

  static final _random = Random.secure();
  static const _idChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  /// A random 20-character id, the same shape as Firestore's auto ids.
  static String _newId() => String.fromCharCodes(Iterable.generate(
        20,
        (_) => _idChars.codeUnitAt(_random.nextInt(_idChars.length)),
      ));

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Starts a reply to [target]. Replies stay one level deep: a reply to a
  /// reply goes under the same top-level comment and mentions the person.
  void startReply(Comment target) {
    final isReplyToReply = target.parentId != null;
    setState(() {
      _parentId = target.parentId ?? target.id;
      _replyToName = target.userName;
      _error = null;
      if (isReplyToReply) {
        _mention = '@${target.userName} ';
        _ctrl.text = _mention!;
        _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
      } else {
        _mention = null;
      }
    });
    _focus.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      if (_mention != null && _ctrl.text == _mention) _ctrl.clear();
      _parentId = null;
      _replyToName = null;
      _mention = null;
    });
  }

  Future<void> _attachPhoto() async {
    final source = await showPhotoSourceSheet(context);
    if (source == null || !mounted) return;

    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final b64 = await _media.pickPhoto(source);
      if (b64 != null && mounted) {
        _photoB64 = b64;
        _photoBytes = base64Decode(b64);
      }
    } on MediaException catch (e) {
      if (mounted) _error = e.message;
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _removePhoto() {
    setState(() {
      _photoB64 = null;
      _photoBytes = null;
    });
  }

  /// A comment needs text (more than just the pre-filled "@Name") or a photo.
  bool get _hasContent {
    final text = _ctrl.text.trim();
    final onlyMention = _mention != null && text == _mention!.trim();
    return (text.isNotEmpty && !onlyMention) || _photoB64 != null;
  }

  Future<void> _send() async {
    if (_sending || _processing) return;
    if (!_hasContent) {
      setState(() => _error = 'Write something or add a photo.');
      return;
    }

    var text = _ctrl.text.trim();
    if (text.length > _maxLength) text = text.substring(0, _maxLength);

    // Same content as the failed attempt -> same id (no duplicate).
    // Anything changed -> it is a new comment with a new id.
    final signature =
        '$_parentId|${_photoB64?.length}|${_photoB64.hashCode}|$text';
    if (signature != _draftSignature || _draftId == null) {
      _draftId = _newId();
      _draftSignature = signature;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await widget.onSend(CommentDraft(
      id: _draftId!,
      text: text,
      photoBase64: _photoB64,
      parentId: _parentId,
      replyToUserName: _parentId == null ? null : _replyToName,
    ));
    if (!mounted) return;

    setState(() {
      _sending = false;
      if (error != null) {
        _error = error;
        return;
      }
      _ctrl.clear();
      _photoB64 = null;
      _photoBytes = null;
      _draftId = null;
      _draftSignature = null;
      _parentId = null;
      _replyToName = null;
      _mention = null;
    });
    if (error == null) _focus.unfocus();
  }

  Widget _replyBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s8),
      padding: const EdgeInsets.only(left: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              'Replying to $_replyToName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
            onPressed: _sending ? null : _cancelReply,
          ),
        ],
      ),
    );
  }

  Widget _thumbnail() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r8),
            child: Image.memory(
              _photoBytes!,
              width: _thumbSize,
              height: _thumbSize,
              fit: BoxFit.cover,
              cacheWidth: 200,
              gaplessPlayback: true,
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: Material(
              color: AppColors.textPrimary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sending ? null : _removePhoto,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 14, color: AppColors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _sending || _processing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_parentId != null) _replyBar(),
        if (_photoBytes != null) _thumbnail(),
        Row(
          children: [
            IconButton(
              tooltip: 'Add a photo',
              onPressed: busy ? null : _attachPhoto,
              icon: _processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _photoB64 == null
                          ? Icons.add_photo_alternate_outlined
                          : Icons.photo_outlined,
                      color: AppColors.textSecondary,
                    ),
            ),
            Expanded(
              child: AppTextField(
                hint: _parentId == null ? 'Add a comment...' : 'Write a reply...',
                controller: _ctrl,
                focusNode: _focus,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            IconButton(
              tooltip: 'Send',
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: AppColors.primary),
              onPressed: busy ? null : _send,
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            _error!,
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
