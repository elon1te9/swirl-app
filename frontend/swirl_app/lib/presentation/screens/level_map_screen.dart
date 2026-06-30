import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/utils/api_error_utils.dart';
import '../../domain/models/level_model.dart';
import '../../domain/models/section_model.dart';
import '../state/learning_provider.dart';

class LevelMapScreen extends ConsumerStatefulWidget {
  const LevelMapScreen({required this.sectionId, super.key});

  final String sectionId;

  @override
  ConsumerState<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends ConsumerState<LevelMapScreen> {
  static const _pageColor = Color.fromRGBO(39, 35, 58, 1);
  static const _cardColor = Color.fromRGBO(39, 35, 58, 0.8);
  static const _solidCardColor = Color.fromRGBO(39, 35, 58, 1);
  static const _accentColor = Color.fromRGBO(151, 219, 255, 1);
  static const _purpleColor = Color.fromRGBO(111, 115, 210, 1);

  bool _isLoading = true;
  int? _loadingLevelId;
  String? _errorMessage;
  SectionModel? _section;
  List<LevelModel> _levels = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadLevelMap);
  }

  Future<void> _loadLevelMap() async {
    final sectionId = int.tryParse(widget.sectionId);
    if (sectionId == null || sectionId <= 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось открыть раздел.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final controller = ref.read(learningControllerProvider);
      final section = await controller.loadSection(sectionId);
      final levels = await controller.loadLevels(sectionId);

      if (!mounted) {
        return;
      }

      setState(() {
        _section = section;
        _levels = levels;
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

  Future<void> _openLevel(LevelModel level) async {
    if (level.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Этот уровень пока закрыт.')),
      );
      return;
    }

    setState(() {
      _loadingLevelId = level.id;
    });

    try {
      final details = await ref
          .read(learningControllerProvider)
          .loadLevelDetails(level.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _loadingLevelId = null;
      });

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return _LevelDetailsSheet(details: details);
        },
      );
    } on LearningUnauthorizedException {
      if (mounted) {
        context.go(AppRoutes.first);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingLevelId = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFromError(error))));
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
        child: _ErrorPanel(message: error, onRetry: _loadLevelMap),
      );
    }

    final section = _section;
    if (section == null) {
      return Center(
        child: _ErrorPanel(
          message: 'Раздел пока не загрузился.',
          onRetry: _loadLevelMap,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLevelMap,
      color: _pageColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(21, 12, 21, 28),
        children: [
          _Header(section: section),
          const SizedBox(height: 24),
          const Text(
            'Выберите уровень',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_levels.isEmpty)
            const _EmptyPanel()
          else
            _LevelMap(
              levels: _levels,
              loadingLevelId: _loadingLevelId,
              onLevelTap: _openLevel,
            ),
        ],
      ),
    );
  }

  String _messageFromError(Object error) {
    return friendlyErrorMessage(
      error,
      fallback: 'Не удалось загрузить уровни. Попробуйте еще раз.',
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.section});

  final SectionModel section;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => context.go(AppRoutes.sections),
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
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 54),
              child: Text(
                section.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelMap extends StatelessWidget {
  const _LevelMap({
    required this.levels,
    required this.loadingLevelId,
    required this.onLevelTap,
  });

  final List<LevelModel> levels;
  final int? loadingLevelId;
  final ValueChanged<LevelModel> onLevelTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemSpacing = width < 350 ? 98.0 : 104.0;
        final lastCenter = _nodeCenter(levels.length - 1, itemSpacing, width);
        final height = levels.length <= 1 ? 112.0 : lastCenter.dy + 54;

        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LevelConnectorPainter(
                    levels: levels,
                    itemSpacing: itemSpacing,
                  ),
                ),
              ),
              for (var index = 0; index < levels.length; index++)
                _PositionedLevel(
                  level: levels[index],
                  index: index,
                  itemSpacing: itemSpacing,
                  mapWidth: width,
                  isLoading: loadingLevelId == levels[index].id,
                  onTap: () => onLevelTap(levels[index]),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PositionedLevel extends StatelessWidget {
  const _PositionedLevel({
    required this.level,
    required this.index,
    required this.itemSpacing,
    required this.mapWidth,
    required this.isLoading,
    required this.onTap,
  });

  final LevelModel level;
  final int index;
  final double itemSpacing;
  final double mapWidth;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final center = _nodeCenter(index, itemSpacing, mapWidth);
    final labelOnRight = center.dx < mapWidth / 2;
    final labelWidth = (mapWidth - 150).clamp(118.0, 210.0);
    final labelLeft = labelOnRight
        ? center.dx + 60
        : center.dx - labelWidth - 60;
    final labelTop = center.dy - 16;

    return Stack(
      children: [
        Positioned(
          left: center.dx - 34,
          top: center.dy - 34,
          child: _LevelNode(level: level, isLoading: isLoading, onTap: onTap),
        ),
        Positioned(
          left: labelLeft.clamp(6.0, mapWidth - labelWidth - 6),
          top: labelTop,
          width: labelWidth,
          child: _LevelLabel(level: level, alignRight: !labelOnRight),
        ),
      ],
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.isLoading,
    required this.onTap,
  });

  final LevelModel level;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _levelStyle(level);

    return Semantics(
      button: true,
      enabled: !level.isLocked,
      label: level.title,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: style.background,
            shape: BoxShape.circle,
            border: Border.all(color: style.border, width: 4),
          ),
          child: Center(
            child: isLoading
                ? SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: style.foreground,
                    ),
                  )
                : _LevelNodeContent(level: level, style: style),
          ),
        ),
      ),
    );
  }
}

class _LevelNodeContent extends StatelessWidget {
  const _LevelNodeContent({required this.level, required this.style});

  final LevelModel level;
  final _LevelStyle style;

  @override
  Widget build(BuildContext context) {
    if (level.isLocked) {
      if (level.isFinalTest) {
        return Icon(Icons.flag_rounded, color: style.foreground, size: 35);
      }

      return Text(
        '${level.levelNumber}',
        style: TextStyle(
          color: style.foreground,
          fontSize: 36,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (level.isFinalTest) {
      return Icon(Icons.flag_rounded, color: style.foreground, size: 31);
    }

    return Text(
      '${level.levelNumber}',
      style: TextStyle(
        color: style.foreground,
        fontSize: 36,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _LevelLabel extends StatelessWidget {
  const _LevelLabel({required this.level, required this.alignRight});

  final LevelModel level;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final color = level.isLocked
        ? _LevelMapScreenState._purpleColor
        : Colors.white;

    return Text(
      _levelMapTitle(level),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w500),
    );
  }
}

class _LevelConnectorPainter extends CustomPainter {
  const _LevelConnectorPainter({
    required this.levels,
    required this.itemSpacing,
  });

  final List<LevelModel> levels;
  final double itemSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.length < 2) {
      return;
    }

    for (var index = 1; index < levels.length; index++) {
      final previous = _nodeCenter(index - 1, itemSpacing, size.width);
      final current = _nodeCenter(index, itemSpacing, size.width);
      final controlY = (previous.dy + current.dy) / 2;
      final path = Path()
        ..moveTo(previous.dx, previous.dy)
        ..cubicTo(
          previous.dx,
          controlY,
          current.dx,
          controlY,
          current.dx,
          current.dy,
        );
      final isLockedSegment =
          levels[index].isLocked || levels[index - 1].isLocked;
      final paint = Paint()
        ..color = isLockedSegment
            ? _LevelMapScreenState._purpleColor
            : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      _drawDashedPath(canvas, path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LevelConnectorPainter oldDelegate) {
    return oldDelegate.levels != levels ||
        oldDelegate.itemSpacing != itemSpacing;
  }
}

class _LevelDetailsSheet extends StatelessWidget {
  const _LevelDetailsSheet({required this.details});

  final LevelDetailsModel details;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.58,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            33,
            30,
            33,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              _SheetHero(details: details),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(label: 'CEFR', value: _cefrText(details)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      label: 'Слова',
                      value: '${details.wordsCount}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _StatChip(
                      label: 'Упражнения',
                      value: '${details.exercisesCount}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DescriptionPanel(details: details),
              const SizedBox(height: 26),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(AppRoutes.tasksForLevel(details.id.toString()));
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _LevelMapScreenState._purpleColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Начать тренировку',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(AppRoutes.learnLevel(details.id.toString()));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _LevelMapScreenState._purpleColor,
                  side: const BorderSide(
                    color: _LevelMapScreenState._purpleColor,
                    width: 2,
                  ),
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  details.isFinalTest ? 'Повторить слова' : 'Изучить слова',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetHero extends StatelessWidget {
  const _SheetHero({required this.details});

  final LevelDetailsModel details;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 154,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 16,
            right: 106,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sheetTitle(details),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _LevelMapScreenState._solidCardColor,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _sheetSubtitle(details),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _LevelMapScreenState._purpleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Positioned(right: -8, top: 4, child: _LevelMascot(level: details)),
        ],
      ),
    );
  }
}

class _LevelMascot extends StatelessWidget {
  const _LevelMascot({required this.level});

  final LevelDetailsModel level;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 178,
      height: 178,
      child: Image.asset(
        _mascotAssetPath(level),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(199, 238, 255, 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _LevelMapScreenState._solidCardColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  color: _LevelMapScreenState._solidCardColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionPanel extends StatelessWidget {
  const _DescriptionPanel({required this.details});

  final LevelDetailsModel details;

  @override
  Widget build(BuildContext context) {
    final description = details.description.trim().isEmpty
        ? 'Описание уровня появится после загрузки данных.'
        : details.description.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(199, 238, 255, 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Описание',
            style: TextStyle(
              color: _LevelMapScreenState._solidCardColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: _LevelMapScreenState._solidCardColor,
              fontSize: 18,
              height: 1.22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
        color: _LevelMapScreenState._cardColor,
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
              backgroundColor: _LevelMapScreenState._accentColor,
              foregroundColor: _LevelMapScreenState._solidCardColor,
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
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _LevelMapScreenState._cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Уровни появятся после загрузки данных.',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}

class _LevelStyle {
  const _LevelStyle({
    required this.background,
    required this.foreground,
    required this.border,
    required this.sheetText,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final Color sheetText;
}

_LevelStyle _levelStyle(LevelModel level) {
  if (level.isLocked) {
    return const _LevelStyle(
      background: _LevelMapScreenState._purpleColor,
      foreground: _LevelMapScreenState._accentColor,
      border: _LevelMapScreenState._accentColor,
      sheetText: _LevelMapScreenState._solidCardColor,
    );
  }

  if (level.isCompleted) {
    return const _LevelStyle(
      background: _LevelMapScreenState._accentColor,
      foreground: _LevelMapScreenState._purpleColor,
      border: _LevelMapScreenState._purpleColor,
      sheetText: _LevelMapScreenState._pageColor,
    );
  }

  return const _LevelStyle(
    background: _LevelMapScreenState._accentColor,
    foreground: _LevelMapScreenState._purpleColor,
    border: _LevelMapScreenState._purpleColor,
    sheetText: _LevelMapScreenState._pageColor,
  );
}

Offset _nodeCenter(int index, double itemSpacing, double width) {
  final scale = (width / 351).clamp(0.88, 1.12);
  final xs = <double>[69, width - 70, 98, width - 82, 70, width - 93];
  final ys = <double>[44, 136, 258, 356, 454, 548];
  final safeIndex = index.clamp(0, ys.length - 1);

  return Offset(xs[safeIndex], ys[safeIndex] * scale);
}

String _levelMapTitle(LevelModel level) {
  if (level.isFinalTest) {
    return 'Тест по разделу';
  }

  switch (level.levelNumber) {
    case 1:
      return 'Базовый';
    case 2:
      return 'Легкий';
    case 3:
      return 'Средний';
    case 4:
      return 'Продвинутый';
    case 5:
      return 'Эксперт';
    default:
      return 'Уровень ${level.levelNumber}';
  }
}

String _sheetTitle(LevelModel level) {
  if (level.isFinalTest) {
    return 'Итог';
  }

  return 'Уровень ${level.levelNumber}';
}

String _sheetSubtitle(LevelModel level) {
  final cefr = _cefrText(level);
  final levelTitle = _levelMapTitle(level);

  if (cefr == '-' || level.isFinalTest) {
    return levelTitle;
  }

  return '$levelTitle · $cefr';
}

String _cefrText(LevelModel level) {
  final cefr = level.cefrLevel.trim();
  if (cefr.isEmpty) {
    return '-';
  }

  final parts = cefr.split('/');
  return parts.last.trim().isEmpty ? cefr : parts.last.trim();
}

String _mascotAssetPath(LevelModel level) {
  if (level.isFinalTest) {
    return 'images/mascot_levels/level_itog.png';
  }

  final number = level.levelNumber.clamp(1, 5);
  return 'images/mascot_levels/level_$number.png';
}

void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
  const dashWidth = 10.0;
  const dashSpace = 14.0;

  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final next = (distance + dashWidth).clamp(0.0, metric.length);
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance += dashWidth + dashSpace;
    }
  }
}
