import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/image_bytes_cache.dart';
import '../../models/public_profile.dart';
import '../../providers/profile_provider.dart';

/// A user's round avatar. Shows, in order:
///   1. their custom picture (public_profiles.avatar_b64)
///   2. their Google photo (public_profiles.photo_url)
///   3. the first letter of [name] (or a person icon) on primary green.
///
/// The profile is fetched once per uid per session by [ProfileProvider].
class UserAvatar extends StatefulWidget {
  final String? uid;

  /// Fallback for the initial while the profile is loading or missing.
  final String name;
  final double size;

  /// Person icon instead of the initial for the default avatar.
  final bool iconFallback;

  const UserAvatar({
    super.key,
    required this.uid,
    this.name = '',
    this.size = 40,
    this.iconFallback = false,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(UserAvatar old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid) _load();
  }

  void _load() {
    final uid = widget.uid;
    if (uid == null || uid.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileProvider>().load(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.uid ?? '';
    final PublicProfile? profile = uid.isEmpty
        ? null
        : context.select<ProfileProvider, PublicProfile?>(
            (p) => p.profileFor(uid),
          );

    final size = widget.size;
    final fallback = _DefaultAvatar(
      name: profile?.name ?? widget.name,
      size: size,
      icon: widget.iconFallback,
    );

    Widget child = fallback;
    final bytes = profile?.hasCustomAvatar == true
        ? ImageBytesCache.decode('avatar_$uid', profile!.avatarBase64)
        : null;

    if (bytes != null) {
      child = Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        cacheWidth: (size * 3).round(),
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (profile?.photoUrl != null) {
      child = Image.network(
        profile!.photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        loadingBuilder: (_, img, progress) => progress == null ? img : fallback,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return ClipOval(
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool icon;

  const _DefaultAvatar({
    required this.name,
    required this.size,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: AppColors.primary,
      child: icon || trimmed.isEmpty
          ? Icon(Icons.person, size: size * 0.55, color: AppColors.white)
          : Text(
              trimmed[0].toUpperCase(),
              style: AppTextStyles.body1.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.4,
              ),
            ),
    );
  }
}
