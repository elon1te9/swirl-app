import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/utils/api_error_utils.dart';
import '../../core/utils/media_url_builder.dart';
import '../../domain/models/continue_learning_model.dart';
import '../../domain/models/profile_model.dart';
import '../state/continue_learning_provider.dart';
import '../state/profile_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _pageColor = Color.fromRGBO(111, 115, 210, 1);
  static const _cardColor = Color.fromRGBO(39, 35, 58, 0.8);
  static const _solidCardColor = Color.fromRGBO(39, 35, 58, 1);
  static const _accentColor = Color.fromRGBO(151, 219, 255, 1);
  static const _dangerColor = Color.fromRGBO(215, 38, 61, 1);

  bool _isLoading = true;
  String? _errorMessage;
  ProfileModel? _profile;
  ContinueLearningModel? _continueLearning;
  List<ContinueSectionModel> _sections = const [];

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
      final learningController = ref.read(continueLearningControllerProvider);
      final sections = await learningController.loadSections();
      final continueLearning = await learningController
          .loadContinueLearningFromSections(sections);

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _continueLearning = continueLearning;
        _sections = sections;
        _isLoading = false;
      });
    } on ProfileUnauthorizedException {
      if (mounted) {
        context.go(AppRoutes.first);
      }
    } on ContinueLearningUnauthorizedException {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const _CenteredStatus(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final error = _errorMessage;
    if (error != null) {
      return _CenteredStatus(
        child: _ErrorPanel(message: error, onRetry: _loadProfile),
      );
    }

    final profile = _profile;
    final continueLearning = _continueLearning;
    if (profile == null) {
      return _CenteredStatus(
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _Header(profile: profile),
          const SizedBox(height: 28),
          const Text(
            'Привет!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Готов изучать новые слова?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Image.asset(
            'images/mascot_home.png',
            height: 186,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          _StreakCard(
            currentStreak: profile.currentStreak,
            lastActivityDate: profile.lastActivityDate,
          ),
          const SizedBox(height: 22),
          _DailyTestCard(onTap: () => context.go(AppRoutes.dailyTest)),
          if (continueLearning != null) ...[
            const SizedBox(height: 18),
            _ContinueLearningCard(
              continueLearning: continueLearning,
              onTap: () => context.go(
                AppRoutes.levelsForSection(
                  continueLearning.section.id.toString(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _SectionsSummary(sections: _sections),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.go(AppRoutes.sections),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(left: 12),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 14,
              ),
              label: const Text(
                'Все разделы',
                style: TextStyle(color: Colors.white, fontSize: 14),
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
      fallback: 'Не удалось загрузить главную. Попробуйте еще раз.',
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final ProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 210),
          child: InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: () => context.go(AppRoutes.profile),
            child: Container(
              height: 51,
              padding: const EdgeInsets.fromLTRB(6, 5, 17, 6),
              decoration: BoxDecoration(
                color: _HomeScreenState._cardColor,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AvatarCircle(
                    name: profile.name,
                    avatarUrl: profile.avatarUrl,
                    size: 40,
                  ),
                  const SizedBox(width: 15),
                  Flexible(
                    child: Text(
                      profile.name.isEmpty ? 'Профиль' : profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        Container(
          height: 51,
          constraints: const BoxConstraints(minWidth: 74),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _HomeScreenState._cardColor,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${profile.currentStreak}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 4),
              const Text('🔥', style: TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.currentStreak,
    required this.lastActivityDate,
  });

  final int currentStreak;
  final DateTime? lastActivityDate;

  @override
  Widget build(BuildContext context) {
    final activeWeekdays = _activeWeekdayIndexes(
      currentStreak: currentStreak,
      lastActivityDate: lastActivityDate,
    );
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Серия',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 420;
            final dayWidth = isCompact ? 22.0 : 24.0;
            final dotSize = isCompact ? 21.0 : 23.0;

            return Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              decoration: BoxDecoration(
                color: _HomeScreenState._cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: isCompact ? 112 : 122,
                    child: Row(
                      children: [
                        Text(
                          '🔥',
                          style: TextStyle(fontSize: isCompact ? 26 : 28),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$currentStreak ${_dayWord(currentStreak)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isCompact ? 12 : 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(weekdays.length, (index) {
                        final isActive = activeWeekdays.contains(index);

                        return _WeekdayDot(
                          label: weekdays[index],
                          isActive: isActive,
                          width: dayWidth,
                          dotSize: dotSize,
                        );
                      }),
                    ),
                  ),
                  SizedBox(width: isCompact ? 2 : 4),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WeekdayDot extends StatelessWidget {
  const _WeekdayDot({
    required this.label,
    required this.isActive,
    required this.width,
    required this.dotSize,
  });

  final String label;
  final bool isActive;
  final double width;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? _HomeScreenState._accentColor
                  : Colors.transparent,
              border: Border.all(
                color: _HomeScreenState._accentColor,
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyTestCard extends StatelessWidget {
  const _DailyTestCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _HomeScreenState._cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: _HomeScreenState._accentColor,
              child: Icon(
                Icons.today_outlined,
                color: _HomeScreenState._solidCardColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ежедневный тест',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Повторите уже изученные слова.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({
    required this.continueLearning,
    required this.onTap,
  });

  final ContinueLearningModel continueLearning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final section = continueLearning.section;
    final style = _sectionCardStyle(section.title);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Продолжить обучение',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 340;
              final imageSize = isNarrow ? 154.0 : 176.0;
              final imageRight = isNarrow ? -54.0 : -42.0;

              return Container(
                constraints: const BoxConstraints(minHeight: 122),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: imageRight,
                      top: -28,
                      bottom: -42,
                      child: _ContinueSectionImage(
                        title: section.title,
                        size: imageSize,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      child: _ContinueLearningInfo(
                        continueLearning: continueLearning,
                        style: style,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContinueSectionImage extends StatelessWidget {
  const _ContinueSectionImage({required this.title, required this.size});

  final String title;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = _sectionCardStyle(title);

    return Opacity(
      opacity: 0.48,
      child: Image.asset(
        _sectionLogoAssetPath(title),
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: style.logo,
        colorBlendMode: BlendMode.srcIn,
      ),
    );
  }
}

class _ContinueArrowButton extends StatelessWidget {
  const _ContinueArrowButton({required this.style});

  final _SectionCardStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: style.arrowBackground,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(Icons.navigate_next, color: style.arrowIcon, size: 27),
    );
  }
}

class _ContinueLearningContent extends StatelessWidget {
  const _ContinueLearningContent({
    required this.continueLearning,
    required this.style,
  });

  final ContinueLearningModel continueLearning;
  final _SectionCardStyle style;

  @override
  Widget build(BuildContext context) {
    final section = continueLearning.section;
    final displayTotal = _displayTotalLevels(continueLearning.totalLevels);
    final displayCompleted = continueLearning.completedLevels.clamp(
      0,
      displayTotal,
    );
    final progressValue = displayTotal <= 0
        ? 0.0
        : (displayCompleted / displayTotal).clamp(0.0, 1.0);
    final progressText = displayTotal <= 0
        ? '$displayCompleted'
        : '$displayCompleted/$displayTotal';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: style.text,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          continueLearning.nextLevelText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: style.text.withValues(alpha: 0.9),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 8,
                  backgroundColor: style.progressBackground,
                  valueColor: AlwaysStoppedAnimation<Color>(style.progress),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              progressText,
              style: TextStyle(
                color: style.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContinueLearningInfo extends StatelessWidget {
  const _ContinueLearningInfo({
    required this.continueLearning,
    required this.style,
  });

  final ContinueLearningModel continueLearning;
  final _SectionCardStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 202),
            child: _ContinueLearningContent(
              continueLearning: continueLearning,
              style: style,
            ),
          ),
        ),
        const SizedBox(width: 18),
        _ContinueArrowButton(style: style),
      ],
    );
  }
}

class _SectionsSummary extends StatelessWidget {
  const _SectionsSummary({required this.sections});

  final List<ContinueSectionModel> sections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Разделы',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (sections.isEmpty)
          const _EmptySections()
        else
          SizedBox(
            height: 184,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sections.length,
              separatorBuilder: (_, _) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final section = sections[index];
                return _SectionProgressCard(section: section);
              },
            ),
          ),
      ],
    );
  }
}

class _SectionProgressCard extends StatelessWidget {
  const _SectionProgressCard({required this.section});

  final ContinueSectionModel section;

  @override
  Widget build(BuildContext context) {
    final style = _sectionCardStyle(section.title);
    final displayTotal = _displayTotalLevels(section.totalLevels);
    final displayCompleted = section.completedLevels.clamp(0, displayTotal);
    final progressValue = displayTotal <= 0
        ? 0.0
        : (displayCompleted / displayTotal).clamp(0.0, 1.0);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.go(AppRoutes.sections),
      child: Container(
        width: 125,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 3),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              _sectionLogoAssetPath(section.title),
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              color: style.logo,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(height: 7),
            Text(
              section.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: style.text,
                fontSize: 20,
                height: 1.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '$displayTotal ${_levelWord(displayTotal)}',
              maxLines: 1,
              style: TextStyle(
                color: style.text,
                fontSize: 11,
                height: 1.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: style.progressBackground,
                valueColor: AlwaysStoppedAnimation<Color>(style.progress),
                minHeight: 7,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '$displayCompleted/$displayTotal',
              style: TextStyle(
                color: style.text,
                fontSize: 12,
                height: 1.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
        color: _HomeScreenState._accentColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            color: _HomeScreenState._solidCardColor,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
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
        color: _HomeScreenState._cardColor,
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
              backgroundColor: _HomeScreenState._accentColor,
              foregroundColor: _HomeScreenState._solidCardColor,
            ),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

class _CenteredStatus extends StatelessWidget {
  const _CenteredStatus({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(child: child);
  }
}

class _EmptySections extends StatelessWidget {
  const _EmptySections();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _HomeScreenState._cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Разделы появятся после загрузки данных.',
        style: TextStyle(color: Colors.white, fontSize: 15),
      ),
    );
  }
}

class _SectionCardStyle {
  const _SectionCardStyle({
    required this.background,
    required this.text,
    required this.logo,
    required this.progress,
    required this.progressBackground,
    required this.arrowBackground,
    required this.arrowIcon,
  });

  final Color background;
  final Color text;
  final Color logo;
  final Color progress;
  final Color progressBackground;
  final Color arrowBackground;
  final Color arrowIcon;
}

String _dayWord(int count) {
  final value = count.abs();
  final lastTwo = value % 100;
  final last = value % 10;

  if (lastTwo >= 11 && lastTwo <= 14) {
    return 'дней';
  }

  if (last == 1) {
    return 'день';
  }

  if (last >= 2 && last <= 4) {
    return 'дня';
  }

  return 'дней';
}

String _sectionLogoAssetPath(String title) {
  switch (title.trim().toLowerCase()) {
    case 'science':
      return 'images/sections/science.png';
    case 'health':
      return 'images/sections/health.png';
    case 'wardrobe':
      return 'images/sections/wardrobe.png';
    case 'food':
    default:
      return 'images/sections/food.png';
  }
}

_SectionCardStyle _sectionCardStyle(String title) {
  switch (title.trim().toLowerCase()) {
    case 'food':
      return _SectionCardStyle(
        background: _HomeScreenState._dangerColor,
        text: Colors.white,
        logo: _HomeScreenState._accentColor,
        progress: _HomeScreenState._accentColor,
        progressBackground: Colors.white.withValues(alpha: 0.62),
        arrowBackground: Colors.white,
        arrowIcon: _HomeScreenState._dangerColor,
      );
    case 'health':
      return _SectionCardStyle(
        background: _HomeScreenState._accentColor,
        text: Colors.white,
        logo: _HomeScreenState._dangerColor.withValues(alpha: 0.82),
        progress: _HomeScreenState._pageColor,
        progressBackground: Colors.white.withValues(alpha: 0.72),
        arrowBackground: Colors.white,
        arrowIcon: _HomeScreenState._accentColor,
      );
    case 'science':
      return _SectionCardStyle(
        background: Colors.white,
        text: _HomeScreenState._pageColor,
        logo: _HomeScreenState._pageColor,
        progress: _HomeScreenState._pageColor,
        progressBackground: _HomeScreenState._accentColor.withValues(
          alpha: 0.48,
        ),
        arrowBackground: _HomeScreenState._pageColor,
        arrowIcon: Colors.white,
      );
    case 'wardrobe':
      return _SectionCardStyle(
        background: _HomeScreenState._dangerColor,
        text: Colors.white,
        logo: const Color.fromRGBO(255, 202, 209, 1),
        progress: _HomeScreenState._accentColor,
        progressBackground: Colors.white.withValues(alpha: 0.62),
        arrowBackground: Colors.white,
        arrowIcon: _HomeScreenState._dangerColor,
      );
    default:
      return _SectionCardStyle(
        background: Colors.white,
        text: _HomeScreenState._pageColor,
        logo: _HomeScreenState._pageColor,
        progress: _HomeScreenState._pageColor,
        progressBackground: _HomeScreenState._accentColor.withValues(
          alpha: 0.48,
        ),
        arrowBackground: _HomeScreenState._pageColor,
        arrowIcon: Colors.white,
      );
  }
}

int _displayTotalLevels(int totalLevels) {
  if (totalLevels <= 1) {
    return totalLevels.clamp(0, 1);
  }

  return totalLevels - 1;
}

Set<int> _activeWeekdayIndexes({
  required int currentStreak,
  required DateTime? lastActivityDate,
}) {
  if (currentStreak <= 0) {
    return const <int>{};
  }

  final fallbackDate = DateTime.now();
  final sourceDate = lastActivityDate ?? fallbackDate;
  final lastDate = DateTime(sourceDate.year, sourceDate.month, sourceDate.day);
  final weekStart = lastDate.subtract(Duration(days: lastDate.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));
  final firstStreakDate = lastDate.subtract(
    Duration(days: currentStreak.clamp(1, 3650) - 1),
  );
  final activeIndexes = <int>{};

  for (
    var date = firstStreakDate;
    !date.isAfter(lastDate);
    date = date.add(const Duration(days: 1))
  ) {
    if (date.isBefore(weekStart) || date.isAfter(weekEnd)) {
      continue;
    }

    activeIndexes.add(date.weekday - 1);
  }

  return activeIndexes;
}

String _levelWord(int count) {
  final value = count.abs();
  final lastTwo = value % 100;
  final last = value % 10;

  if (lastTwo >= 11 && lastTwo <= 14) {
    return 'уровней';
  }

  if (last == 1) {
    return 'уровень';
  }

  if (last >= 2 && last <= 4) {
    return 'уровня';
  }

  return 'уровней';
}
