import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/utils/api_error_utils.dart';
import '../../core/utils/media_url_builder.dart';
import '../../domain/models/profile_model.dart';
import '../state/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _pageColor = Color(0xFF6F73D2);
  static const _cardColor = Color(0xCC27233A);
  static const _solidCardColor = Color(0xFF27233A);
  static const _accentColor = Color(0xFF97DBFF);

  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _errorMessage;
  ProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadProfile);
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await ref.read(profileControllerProvider).loadProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
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
        _errorMessage = _messageFromError(error);
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    await ref.read(profileControllerProvider).logout();

    if (mounted) {
      context.go(AppRoutes.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final error = _errorMessage;
    if (error != null) {
      return Center(
        child: _ErrorPanel(message: error, onRetry: _loadProfile),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return Center(
        child: _ErrorPanel(
          message: 'Профиль пока не загрузился.',
          onRetry: _loadProfile,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: _pageColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _ProfileHeader(
            profile: profile,
            onEdit: () => context.go(AppRoutes.profileEdit),
          ),
          const SizedBox(height: 32),
          _StreakPanel(profile: profile),
          const SizedBox(height: 22),
          _ProgressPanel(profile: profile),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isLoggingOut ? null : _logout,
              icon: _isLoggingOut
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.logout, size: 21),
              label: const Text(
                'Выйти',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.6),
                disabledForegroundColor: Colors.white60,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _messageFromError(Object error) {
    return friendlyErrorMessage(
      error,
      fallback: 'Не удалось загрузить профиль. Попробуйте еще раз.',
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onEdit});

  final ProfileModel profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AvatarCircle(
          name: profile.name,
          avatarUrl: profile.avatarUrl,
          size: 128,
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                profile.name.isEmpty ? 'Профиль' : profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StreakPanel extends StatelessWidget {
  const _StreakPanel({required this.profile});

  final ProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
      decoration: BoxDecoration(
        color: _ProfileScreenState._cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text(
            'Серия',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          _MetricRow(
            label: 'Текущая',
            value: '${profile.currentStreak}',
            emoji: '🔥',
          ),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'Рекорд',
            value: '${profile.bestStreak}',
            emoji: '💎',
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.profile});

  final ProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: _ProfileScreenState._cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Мой прогресс',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          if (profile.sectionsProgress.isEmpty)
            const Text(
              'Прогресс по разделам появится после первых уровней.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            )
          else
            for (final section in profile.sectionsProgress) ...[
              _SectionProgressRow(section: section),
              const SizedBox(height: 18),
            ],
          const Divider(color: Colors.white24, height: 28),
          _SimpleStatRow(
            label: 'Изучено слов:',
            value: '${profile.learnedWordsCount}',
          ),
          const SizedBox(height: 12),
          _SimpleStatRow(
            label: 'Пройдено уровней:',
            value: '${profile.completedLevelsCount}',
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.emoji,
  });

  final String label;
  final String value;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(emoji, style: const TextStyle(fontSize: 22)),
      ],
    );
  }
}

class _SectionProgressRow extends StatelessWidget {
  const _SectionProgressRow({required this.section});

  final SectionProgressModel section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                section.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _sectionProgressColor(section.title),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${section.progressPercent}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: LinearProgressIndicator(
            value: _progressValue(section.progressPercent),
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
            valueColor: AlwaysStoppedAnimation<Color>(
              _sectionProgressColor(section.title),
            ),
          ),
        ),
      ],
    );
  }
}

class _SimpleStatRow extends StatelessWidget {
  const _SimpleStatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 19),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.name,
    required this.avatarUrl,
    required this.size,
  });

  final String name;
  final String avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fullUrl = buildMediaUrl(avatarUrl);
    final fallback = _AvatarFallback(name: name, size: size);

    if (fullUrl == null) {
      return fallback;
    }

    return ClipOval(
      child: Image.network(
        fullUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty
        ? 'S'
        : String.fromCharCode(trimmed.runes.first);

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _ProfileScreenState._accentColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            color: _ProfileScreenState._solidCardColor,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ProfileScreenState._cardColor,
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
              backgroundColor: _ProfileScreenState._accentColor,
              foregroundColor: _ProfileScreenState._solidCardColor,
            ),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

double _progressValue(int progressPercent) {
  return progressPercent.clamp(0, 100) / 100;
}

Color _sectionProgressColor(String title) {
  switch (title.trim().toLowerCase()) {
    case 'food':
      return const Color(0xFFD7263D);
    case 'health':
      return const Color(0xFF97DBFF);
    case 'science':
      return const Color(0xFF8F8BE8);
    case 'wardrobe':
      return const Color(0xFFFFD166);
    default:
      return _ProfileScreenState._accentColor;
  }
}
