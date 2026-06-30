import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/utils/api_error_utils.dart';
import '../../core/utils/media_url_builder.dart';
import '../../domain/models/avatar_model.dart';
import '../../domain/models/profile_model.dart';
import '../state/profile_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  static const _pageColor = Color.fromRGBO(111, 115, 210, 1);
  static const _cardColor = Color.fromRGBO(39, 35, 58, 0.8);
  static const _solidCardColor = Color.fromRGBO(39, 35, 58, 1);
  static const _accentColor = Color.fromRGBO(151, 219, 255, 1);

  final _nameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasLoadError = false;
  String? _errorMessage;
  List<AvatarModel> _avatars = const [];
  int? _selectedAvatarId;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
      _errorMessage = null;
    });

    try {
      final controller = ref.read(profileControllerProvider);
      final profile = await controller.loadProfile();
      final avatars = await controller.loadAvatars();

      if (!mounted) {
        return;
      }

      setState(() {
        _nameController.text = profile.name;
        _avatars = avatars;
        _selectedAvatarId = _findAvatarId(profile, avatars);
        _hasLoadError = false;
        _isLoading = false;
      });
    } on ProfileUnauthorizedException {
      if (mounted) {
        context.go(AppRoutes.first);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _hasLoadError = true;
        _errorMessage = friendlyErrorMessage(
          error,
          fallback: 'Не удалось загрузить профиль. Попробуйте еще раз.',
        );
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final avatarId = _selectedAvatarId;

    if (name.isEmpty) {
      setState(() {
        _hasLoadError = false;
        _errorMessage = 'Введите имя.';
      });
      return;
    }

    if (avatarId == null) {
      setState(() {
        _hasLoadError = false;
        _errorMessage = 'Выберите аватарку.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _hasLoadError = false;
      _errorMessage = null;
    });

    try {
      await ref
          .read(profileControllerProvider)
          .updateProfile(name: name, avatarId: avatarId);

      if (mounted) {
        context.go(AppRoutes.profile);
      }
    } on ProfileUnauthorizedException {
      if (mounted) {
        context.go(AppRoutes.first);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = friendlyErrorMessage(
        error,
        fallback: 'Не удалось сохранить профиль. Попробуйте еще раз.',
      );
      if (message.startsWith('Аватарка сохранена.')) {
        context.go(AppRoutes.profile);
        return;
      }

      setState(() {
        _isSaving = false;
        _hasLoadError = false;
        _errorMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _hasLoadError
            ? _EditLoadError(
                message:
                    _errorMessage ??
                    'Не удалось загрузить профиль. Попробуйте еще раз.',
                onRetry: _loadData,
                onBack: () => context.go(AppRoutes.profile),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final contentTopGap = (constraints.maxHeight * 0.09)
                      .clamp(28.0, 74.0)
                      .toDouble();
                  final keyboardBottom = MediaQuery.viewInsetsOf(
                    context,
                  ).bottom;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      28 + keyboardBottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 36,
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => context.go(AppRoutes.profile),
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: contentTopGap),
                          const Text(
                            'Редактировать профиль',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Имя',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _nameController,
                                  enabled: !_isSaving,
                                  maxLength: 40,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: Colors.white.withValues(
                                      alpha: 0.12,
                                    ),
                                    hintText: 'Ваше имя',
                                    hintStyle: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                const Text(
                                  'Аватарка',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _AvatarGrid(
                                  avatars: _avatars,
                                  selectedAvatarId: _selectedAvatarId,
                                  isSaving: _isSaving,
                                  onSelected: (avatarId) {
                                    setState(() {
                                      _selectedAvatarId = avatarId;
                                    });
                                  },
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _isSaving ? null : _save,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _accentColor,
                                      foregroundColor: _solidCardColor,
                                      textStyle: const TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox.square(
                                            dimension: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Сохранить'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _EditLoadError extends StatelessWidget {
  const _EditLoadError({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _ProfileEditScreenState._cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _ProfileEditScreenState._accentColor,
                foregroundColor: _ProfileEditScreenState._solidCardColor,
              ),
              child: const Text('Повторить'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onBack,
              child: const Text(
                'Назад',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarGrid extends StatelessWidget {
  const _AvatarGrid({
    required this.avatars,
    required this.selectedAvatarId,
    required this.isSaving,
    required this.onSelected,
  });

  final List<AvatarModel> avatars;
  final int? selectedAvatarId;
  final bool isSaving;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) {
      return const Text(
        'Аватарки не загрузились.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: avatars.map((avatar) {
        final isSelected = avatar.id == selectedAvatarId;
        final imageUrl = buildMediaUrl(avatar.imageUrl);

        return InkWell(
          borderRadius: BorderRadius.circular(42),
          onTap: isSaving ? null : () => onSelected(avatar.id),
          child: Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? _ProfileEditScreenState._accentColor
                    : Colors.white24,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: ClipOval(
              child: imageUrl == null
                  ? const ColoredBox(
                      color: _ProfileEditScreenState._accentColor,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: _ProfileEditScreenState._accentColor,
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

int? _findAvatarId(ProfileModel profile, List<AvatarModel> avatars) {
  for (final avatar in avatars) {
    if (avatar.imageUrl == profile.avatarUrl) {
      return avatar.id;
    }
  }

  return avatars.isEmpty ? null : avatars.first.id;
}
