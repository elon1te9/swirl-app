import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/utils/api_error_utils.dart';
import '../../core/utils/media_url_builder.dart';
import '../../domain/models/level_model.dart';
import '../../domain/models/word_model.dart';
import '../state/learning_provider.dart';

class LearnWordScreen extends ConsumerStatefulWidget {
  const LearnWordScreen({required this.levelId, super.key});

  final String levelId;

  @override
  ConsumerState<LearnWordScreen> createState() => _LearnWordScreenState();
}

class _LearnWordScreenState extends ConsumerState<LearnWordScreen> {
  static const _pageColor = Color(0xFF27233A);
  static const _cardColor = Color(0xCC27233A);
  static const _solidCardColor = Color(0xFF27233A);
  static const _accentColor = Color(0xFF97DBFF);
  static const _purpleColor = Color(0xFF6F73D2);
  static const _dangerColor = Color(0xFFD7263D);

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<void>? _playerCompleteSubscription;

  bool _isLoading = true;
  bool _isMarkingLearned = false;
  bool _isPlayingAudio = false;
  String? _errorMessage;
  LevelDetailsModel? _levelDetails;
  List<WordModel> _words = const [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
        });
      }
    });
    Future.microtask(_loadWords);
  }

  @override
  void dispose() {
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    final levelId = int.tryParse(widget.levelId);
    if (levelId == null || levelId <= 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось открыть уровень.';
      });
      return;
    }

    await _audioPlayer.stop();
    setState(() {
      _isLoading = true;
      _isPlayingAudio = false;
      _isMarkingLearned = false;
      _errorMessage = null;
      _currentIndex = 0;
    });

    try {
      final controller = ref.read(learningControllerProvider);
      final details = await controller.loadLevelDetails(levelId);
      if (!mounted) {
        return;
      }

      setState(() {
        _levelDetails = details;
      });

      final words = await controller.loadLevelWords(levelId);

      if (!mounted) {
        return;
      }

      setState(() {
        _levelDetails = details;
        _words = words;
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

  Future<void> _playAudio(WordModel word) async {
    final url = buildMediaUrl(word.audioUrl);
    if (url == null) {
      return;
    }

    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlayingAudio = true;
      });
      await _audioPlayer.play(UrlSource(url));
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPlayingAudio = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось включить аудио.')),
      );
    }
  }

  Future<void> _goNext() async {
    if (_isMarkingLearned || _words.isEmpty) {
      return;
    }

    await _audioPlayer.stop();
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex += 1;
        _isPlayingAudio = false;
      });
      return;
    }

    await _finishLearning();
  }

  Future<void> _finishLearning() async {
    final levelId = int.tryParse(widget.levelId);
    if (levelId == null || levelId <= 0) {
      setState(() {
        _errorMessage = 'Не удалось открыть уровень.';
      });
      return;
    }

    setState(() {
      _isMarkingLearned = true;
    });

    try {
      final wordIds = _words
          .map((word) => word.id)
          .where((id) => id > 0)
          .toList();
      if (wordIds.isNotEmpty && _levelDetails?.isFinalTest != true) {
        await ref
            .read(learningControllerProvider)
            .markLevelWordsLearned(levelId, wordIds: wordIds);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isMarkingLearned = false;
      });
      await _showLearnedDialog();
    } on LearningUnauthorizedException {
      if (mounted) {
        context.go(AppRoutes.first);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isMarkingLearned = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFromError(error))));
    }
  }

  Future<void> _showLearnedDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _WordsCompleteSheet(
          details: _levelDetails,
          onStartTraining: () {
            Navigator.of(sheetContext).pop();
            context.go(AppRoutes.tasksForLevel(widget.levelId));
          },
        );
      },
    );
  }

  void _goBack() {
    final sectionId = _levelDetails?.sectionId;
    if (sectionId != null && sectionId > 0) {
      context.go(AppRoutes.levelsForSection(sectionId.toString()));
      return;
    }

    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(AppRoutes.sections);
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
        child: _ErrorPanel(
          message: error,
          onRetry: _loadWords,
          onBack: _goBack,
        ),
      );
    }

    if (_words.isEmpty) {
      return _EmptyLevelView(levelId: widget.levelId, onBack: _goBack);
    }

    final word = _words[_currentIndex];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(21, 8, 21, 0),
          child: _Header(title: _headerTitle(), onBack: _goBack),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(21, 12, 21, 20),
            children: [
              _WordProgress(current: _currentIndex + 1, total: _words.length),
              const SizedBox(height: 28),
              _WordCard(
                word: word,
                isPlayingAudio: _isPlayingAudio,
                onPlayAudio: () => _playAudio(word),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            21,
            0,
            21,
            18 + MediaQuery.paddingOf(context).bottom,
          ),
          child: _buildBottomAction(),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_currentIndex + 1} / ${_words.length}',
          style: const TextStyle(
            color: _accentColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _isMarkingLearned ? null : _goNext,
          style: FilledButton.styleFrom(
            backgroundColor: _accentColor,
            disabledBackgroundColor: _accentColor.withValues(alpha: 0.55),
            foregroundColor: _solidCardColor,
            disabledForegroundColor: _solidCardColor.withValues(alpha: 0.7),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isMarkingLearned
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: _solidCardColor,
                  ),
                )
              : Text(
                  _currentIndex == _words.length - 1
                      ? 'Завершить'
                      : 'Следующее слово',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  String _headerTitle() {
    final sectionTitle = _levelDetails?.sectionTitle.trim();
    if (sectionTitle != null && sectionTitle.isNotEmpty) {
      return sectionTitle;
    }

    return 'Учить слова';
  }

  String _messageFromError(Object error) {
    return friendlyErrorMessage(
      error,
      fallback: 'Не удалось загрузить слова. Попробуйте еще раз.',
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
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
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 54),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 31,
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

class _WordProgress extends StatelessWidget {
  const _WordProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : current / total;

    return LayoutBuilder(
      builder: (context, constraints) {
        final progressWidth = constraints.maxWidth * progress.clamp(0.0, 1.0);

        return Container(
          height: 10,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: progressWidth,
              decoration: BoxDecoration(
                color: _LearnWordScreenState._accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WordsCompleteSheet extends StatelessWidget {
  const _WordsCompleteSheet({
    required this.details,
    required this.onStartTraining,
  });

  final LevelDetailsModel? details;
  final VoidCallback onStartTraining;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          28,
          22,
          28,
          20 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _completeSheetLevelLabel(details),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              color: _LearnWordScreenState._purpleColor,
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Слова изучены',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: _LearnWordScreenState._solidCardColor,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.04,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 126,
                      height: 126,
                      child: Image.asset(
                        'images/mascot_levels/words_complete.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onStartTraining,
                  style: FilledButton.styleFrom(
                    backgroundColor: _LearnWordScreenState._purpleColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'К тренировке',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _completeSheetLevelLabel(LevelDetailsModel? details) {
  if (details == null) {
    return 'Уровень';
  }

  final section = details.sectionTitle.trim();
  final level = _completeSheetLevelName(details);
  if (section.isEmpty) {
    return level;
  }

  return '$section, $level';
}

String _completeSheetLevelName(LevelDetailsModel details) {
  if (details.isFinalTest) {
    return 'Тест';
  }

  switch (details.levelNumber) {
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
      return 'Уровень ${details.levelNumber}';
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.word,
    required this.isPlayingAudio,
    required this.onPlayAudio,
  });

  final WordModel word;
  final bool isPlayingAudio;
  final VoidCallback onPlayAudio;

  @override
  Widget build(BuildContext context) {
    final transcription = word.transcription.trim();
    final partOfSpeech = word.partOfSpeech.trim();
    final hasAudio = buildMediaUrl(word.audioUrl) != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: _LearnWordScreenState._cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WordImage(imageUrl: word.imageUrl),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayText(word.english, 'Word'),
                      softWrap: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _displayText(word.russian, 'Перевод'),
                      softWrap: true,
                      style: const TextStyle(
                        color: _LearnWordScreenState._accentColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _AudioButton(
                enabled: hasAudio,
                isPlaying: isPlayingAudio,
                onPressed: onPlayAudio,
              ),
            ],
          ),
          if (transcription.isNotEmpty || partOfSpeech.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (transcription.isNotEmpty)
                  _InfoChip(
                    label: transcription,
                    icon: Icons.record_voice_over,
                  ),
                if (partOfSpeech.isNotEmpty)
                  _InfoChip(label: partOfSpeech, icon: Icons.category_rounded),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WordImage extends StatelessWidget {
  const _WordImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final fullUrl = buildMediaUrl(imageUrl);

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _LearnWordScreenState._solidCardColor.withValues(
              alpha: 0.78,
            ),
          ),
          child: fullUrl == null
              ? const _MissingImage()
              : Image.network(
                  fullUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _MissingImage(),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _MissingImage extends StatelessWidget {
  const _MissingImage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.image_not_supported_rounded,
        color: _LearnWordScreenState._accentColor,
        size: 54,
      ),
    );
  }
}

class _AudioButton extends StatelessWidget {
  const _AudioButton({
    required this.enabled,
    required this.isPlaying,
    required this.onPressed,
  });

  final bool enabled;
  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: enabled ? 'Проиграть аудио' : 'Аудио нет',
      child: IconButton.filled(
        onPressed: enabled ? onPressed : null,
        style: IconButton.styleFrom(
          backgroundColor: enabled
              ? _LearnWordScreenState._accentColor
              : Colors.white.withValues(alpha: 0.16),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.16),
          foregroundColor: _LearnWordScreenState._solidCardColor,
          disabledForegroundColor: Colors.white54,
          fixedSize: const Size.square(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(
          isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
          size: 29,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _LearnWordScreenState._accentColor),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLevelView extends StatelessWidget {
  const _EmptyLevelView({required this.levelId, required this.onBack});

  final String levelId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        21,
        8,
        21,
        22 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _Header(title: 'Учить слова', onBack: onBack),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          decoration: BoxDecoration(
            color: _LearnWordScreenState._cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: _LearnWordScreenState._accentColor.withValues(
                    alpha: 0.18,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: _LearnWordScreenState._accentColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'В этом уровне нет новых слов.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Можно сразу перейти к тренировке.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.28,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => context.go(AppRoutes.tasksForLevel(levelId)),
                style: FilledButton.styleFrom(
                  backgroundColor: _LearnWordScreenState._accentColor,
                  foregroundColor: _LearnWordScreenState._solidCardColor,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'К тренировке',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _LearnWordScreenState._cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _LearnWordScreenState._dangerColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: _LearnWordScreenState._accentColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: _LearnWordScreenState._accentColor,
              foregroundColor: _LearnWordScreenState._solidCardColor,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Повторить',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
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
    );
  }
}

String _displayText(String value, String fallback) {
  final text = value.trim();
  return text.isEmpty ? fallback : text;
}
