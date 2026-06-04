import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../domain/models/section_model.dart';
import '../state/learning_provider.dart';

class SectionsScreen extends ConsumerStatefulWidget {
  const SectionsScreen({super.key});

  @override
  ConsumerState<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends ConsumerState<SectionsScreen> {
  static const _pageColor = Color(0xFF27233A);
  static const _cardColor = Color(0xCC27233A);
  static const _solidCardColor = Color(0xFF27233A);
  static const _accentColor = Color(0xFF97DBFF);
  static const _dangerColor = Color(0xFFD7263D);

  bool _isLoading = true;
  String? _errorMessage;
  List<SectionModel> _sections = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadSections);
  }

  Future<void> _loadSections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sections = await ref
          .read(learningControllerProvider)
          .loadSections();

      if (!mounted) {
        return;
      }

      setState(() {
        _sections = sections;
        _isLoading = false;
      });
    } on LearningUnauthorizedException {
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
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final error = _errorMessage;
    if (error != null) {
      return Center(
        child: _ErrorPanel(message: error, onRetry: _loadSections),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(29, 8, 29, 0),
          child: _Header(onBack: () => context.go(AppRoutes.home)),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSections,
            color: _pageColor,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(29, 0, 29, 28),
              children: [
                if (_sections.isEmpty)
                  const _EmptyPanel()
                else
                  for (final section in _sections) ...[
                    _SectionCard(
                      section: section,
                      onTap: () => context.go(
                        AppRoutes.levelsForSection(section.id.toString()),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _messageFromError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              splashRadius: 22,
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white70,
                size: 29,
              ),
            ),
          ),
          const Center(
            child: Text(
              'Все разделы',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.onTap});

  final SectionModel section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _sectionCardStyle(section.title);
    final levelsCount = _displayTotalLevels(section.totalLevels);
    final titleScale = MediaQuery.textScalerOf(context).scale(1);
    final titleSize = titleScale > 1.15 ? 43.0 : 48.0;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 147,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Positioned(
              right: style.imageRight,
              top: style.imageTop,
              bottom: style.imageBottom,
              child: _SectionImage(section: section, style: style),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, style.textRightPadding, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    maxLines: titleScale > 1.2 ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: style.title,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Outfit',
                      fontVariations: const [FontVariation('wght', 500)],
                      letterSpacing: -2.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _LevelCountPill(
                    label: '$levelsCount ${_levelWord(levelsCount)}',
                    style: style,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionImage extends StatelessWidget {
  const _SectionImage({required this.section, required this.style});

  final SectionModel section;
  final _SectionCardStyle style;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: style.imageOpacity,
      child: Transform.rotate(
        angle: style.imageAngle,
        child: Image.asset(
          _sectionLogoAssetPath(section.title),
          width: style.imageSize,
          height: style.imageSize,
          fit: BoxFit.contain,
          color: style.imageTint,
          colorBlendMode: BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _LevelCountPill extends StatelessWidget {
  const _LevelCountPill({required this.label, required this.style});

  final String label;
  final _SectionCardStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 82),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: style.pillBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: style.pillText,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Outfit',
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
        color: _SectionsScreenState._cardColor,
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
              backgroundColor: _SectionsScreenState._accentColor,
              foregroundColor: _SectionsScreenState._solidCardColor,
            ),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _SectionsScreenState._cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Разделы появятся после загрузки данных.',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}

class _SectionCardStyle {
  const _SectionCardStyle({
    required this.background,
    required this.title,
    required this.imageTint,
    required this.imageOpacity,
    required this.imageSize,
    required this.imageRight,
    required this.imageTop,
    required this.imageBottom,
    required this.imageAngle,
    required this.textRightPadding,
    required this.pillBackground,
    required this.pillText,
  });

  final Color background;
  final Color title;
  final Color imageTint;
  final double imageOpacity;
  final double imageSize;
  final double imageRight;
  final double imageTop;
  final double imageBottom;
  final double imageAngle;
  final double textRightPadding;
  final Color pillBackground;
  final Color pillText;
}

_SectionCardStyle _sectionCardStyle(String title) {
  switch (title.trim().toLowerCase()) {
    case 'science':
      return const _SectionCardStyle(
        background: Colors.white,
        title: Color(0xFF6F73D2),
        imageTint: Color(0xFF6F73D2),
        imageOpacity: 0.34,
        imageSize: 166,
        imageRight: -14,
        imageTop: -2,
        imageBottom: -28,
        imageAngle: -0.12,
        textRightPadding: 136,
        pillBackground: Color(0xFFBFC1EF),
        pillText: Colors.white,
      );
    case 'health':
      return const _SectionCardStyle(
        background: _SectionsScreenState._accentColor,
        title: Colors.white,
        imageTint: _SectionsScreenState._dangerColor,
        imageOpacity: 0.52,
        imageSize: 166,
        imageRight: -13,
        imageTop: -3,
        imageBottom: -22,
        imageAngle: -0.06,
        textRightPadding: 140,
        pillBackground: Color(0xFFDDF3FF),
        pillText: _SectionsScreenState._accentColor,
      );
    case 'wardrobe':
      return const _SectionCardStyle(
        background: _SectionsScreenState._dangerColor,
        title: Colors.white,
        imageTint: Color(0xFFFFCAD1),
        imageOpacity: 0.7,
        imageSize: 160,
        imageRight: -3,
        imageTop: 31,
        imageBottom: -35,
        imageAngle: -0.05,
        textRightPadding: 92,
        pillBackground: Color(0xFFEB939E),
        pillText: Colors.white,
      );
    case 'food':
    default:
      return const _SectionCardStyle(
        background: _SectionsScreenState._dangerColor,
        title: Colors.white,
        imageTint: _SectionsScreenState._accentColor,
        imageOpacity: 0.68,
        imageSize: 170,
        imageRight: -9,
        imageTop: -2,
        imageBottom: -26,
        imageAngle: -0.08,
        textRightPadding: 135,
        pillBackground: Color(0xFFFF8FA0),
        pillText: Colors.white,
      );
  }
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

int _displayTotalLevels(int totalLevels) {
  if (totalLevels <= 1) {
    return totalLevels.clamp(0, 1);
  }

  return totalLevels - 1;
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
