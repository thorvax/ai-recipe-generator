import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/username_service.dart';
import 'app_text_field.dart';

enum UsernameAvailability { none, checking, available, taken, current }

/// Username input with the rules and a live "available / taken" line
/// (same behaviour and wording as the website's UsernameField).
/// Lower-cases what you type, and checks 400 ms after you stop typing.
/// Use inside a Form: its validator also refuses a taken name.
class UsernameField extends StatefulWidget {
  final TextEditingController controller;

  /// On Edit Profile: your own name counts as "current", not "taken".
  final String? currentUsername;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const UsernameField({
    super.key,
    required this.controller,
    this.currentUsername,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  State<UsernameField> createState() => _UsernameFieldState();
}

class _UsernameFieldState extends State<UsernameField> {
  final UsernameService _service = UsernameService();
  Timer? _debounce;
  UsernameAvailability _availability = UsernameAvailability.none;
  String _checked = '';
  // Free usernames offered when the typed one is taken.
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    // Edit Profile starts with your current name filled in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _update(widget.controller.text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String text) {
    // Stored in lower case, so show it that way while typing.
    final lower = text.toLowerCase();
    if (lower != text) {
      widget.controller.value = widget.controller.value.copyWith(text: lower);
    }
    _update(lower);
  }

  void _update(String text) {
    _debounce?.cancel();
    final username = UsernameService.normalize(text);

    if (username == widget.currentUsername) {
      setState(() => _availability = UsernameAvailability.current);
      return;
    }
    if (UsernameService.validate(username) != null) {
      setState(() => _availability = UsernameAvailability.none);
      return;
    }

    setState(() => _availability = UsernameAvailability.checking);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final free = await _service.isAvailable(username);
        // Ignore answers for text the user has already changed.
        if (!mounted ||
            UsernameService.normalize(widget.controller.text) != username) {
          return;
        }
        setState(() {
          _checked = username;
          _suggestions = [];
          _availability = free
              ? UsernameAvailability.available
              : UsernameAvailability.taken;
        });
        if (!free) _loadSuggestions(username);
      } catch (_) {
        // Offline: say nothing; saving checks again anyway.
        if (mounted) {
          setState(() => _availability = UsernameAvailability.none);
        }
      }
    });
  }

  Future<void> _loadSuggestions(String username) async {
    final names = await _service
        .findAvailableSuggestions(username)
        .catchError((_) => <String>[]);
    // Only if the user is still looking at the same taken name.
    if (!mounted || _checked != username) return;
    setState(() => _suggestions = names);
  }

  void _pick(String name) {
    widget.controller.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
    _update(name);
  }

  Widget _suggestionChips() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      child: Wrap(
        spacing: AppSpacing.s8,
        runSpacing: AppSpacing.s4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Try:', style: AppTextStyles.caption),
          for (final name in _suggestions)
            ActionChip(
              label: Text('@$name'),
              labelStyle: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: AppColors.white,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
              shape: const StadiumBorder(),
              visualDensity: VisualDensity.compact,
              onPressed: () => _pick(name),
            ),
        ],
      ),
    );
  }

  String? _validate(String? value) {
    final error = UsernameService.validate(value);
    if (error != null) return error;
    final taken = _availability == UsernameAvailability.taken &&
        _checked == UsernameService.normalize(value ?? '');
    return taken ? 'That username is already taken.' : null;
  }

  Widget _hint() {
    final username = UsernameService.normalize(widget.controller.text);
    final (text, color) = switch (_availability) {
      UsernameAvailability.available => (
          '✓ @$username is available',
          AppColors.primary,
        ),
      UsernameAvailability.taken => (
          'That username is already taken.',
          AppColors.error,
        ),
      UsernameAvailability.current => (
          'This is your current username.',
          AppColors.textSecondary,
        ),
      UsernameAvailability.checking => ('Checking...', AppColors.textSecondary),
      UsernameAvailability.none => (
          '3–20 characters: lowercase letters, numbers, dots or underscores. '
              'Other cooks see this name.',
          AppColors.textSecondary,
        ),
    };
    return Text(text, style: AppTextStyles.caption.copyWith(color: color));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          hint: 'Username',
          controller: widget.controller,
          textInputAction: widget.textInputAction,
          onChanged: _onChanged,
          onSubmitted: widget.onSubmitted,
          validator: _validate,
        ),
        const SizedBox(height: AppSpacing.s4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          child: _hint(),
        ),
        if (_availability == UsernameAvailability.taken &&
            _suggestions.isNotEmpty)
          _suggestionChips(),
      ],
    );
  }
}
