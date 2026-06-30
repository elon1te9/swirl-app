import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/utils/answer_normalizer.dart';
import '../../core/utils/api_error_utils.dart';
import '../../core/utils/media_url_builder.dart';
import '../../domain/models/level_model.dart';
import '../../domain/models/level_session_model.dart';
import '../state/continue_learning_provider.dart';
import '../state/learning_provider.dart';
import '../state/profile_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({required this.levelId, super.key});

  final String levelId;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  static const _pageColor = Color.fromRGBO(39, 35, 58, 1);
  static const _cardColor = Color.fromRGBO(39, 35, 58, 0.8);
  static const _solidCardColor = Color.fromRGBO(39, 35, 58, 1);
  static const _accentColor = Color.fromRGBO(151, 219, 255, 1);
  static const _successColor = Color.fromRGBO(53, 208, 111, 1);
  static const _purpleColor = Color.fromRGBO(111, 115, 210, 1);
  static const _dangerColor = Color.fromRGBO(215, 38, 61, 1);

  final TextEditingController _answerController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<void>? _playerCompleteSubscription;

  bool _isLoading = true;
  bool _isCompleting = false;
  bool _isPlayingAudio = false;
  String? _errorMessage;
  LevelSessionModel? _session;
  int _currentIndex = 0;
  DateTime _questionStartedAt = DateTime.now();
  String? _selectedAnswer;
  String? _answerError;
  bool? _lastAnswerCorrect;
  int? _sectionId;
  final List<LevelAnswerModel> _answers = [];

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
    Future.microtask(_loadSession);
  }

  @override
  void dispose() {
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final levelId = int.tryParse(widget.levelId);
    if (levelId == null || levelId <= 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось открыть тренировку.';
      });
      return;
    }

    await _audioPlayer.stop();
    setState(() {
      _isLoading = true;
      _isCompleting = false;
      _isPlayingAudio = false;
      _errorMessage = null;
      _session = null;
      _sectionId = null;
      _currentIndex = 0;
      _selectedAnswer = null;
      _answerError = null;
      _lastAnswerCorrect = null;
      _answers.clear();
      _answerController.clear();
      _questionStartedAt = DateTime.now();
    });

    try {
      final controller = ref.read(learningControllerProvider);
      final session = await controller.loadLevelSession(levelId);
      LevelDetailsModel? levelDetails;
      try {
        levelDetails = await controller.loadLevelDetails(levelId);
      } on LearningUnauthorizedException {
        rethrow;
      } catch (_) {
        levelDetails = null;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _session = session;
        final sectionId = levelDetails?.sectionId;
        _sectionId = sectionId != null && sectionId > 0 ? sectionId : null;
        _isLoading = false;
        _questionStartedAt = DateTime.now();
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

  Future<void> _playQuestionAudio(ExerciseModel exercise) async {
    final url = buildMediaUrl(exercise.questionAudioUrl);
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

  Future<void> _submitInputAnswer(ExerciseModel exercise) async {
    final answer = _answerController.text;
    if (_lastAnswerCorrect != null || _isCompleting) {
      return;
    }

    if (answer.trim().isEmpty) {
      setState(() {
        _answerError = 'Введите ответ.';
      });
      return;
    }

    setState(() {
      _answerError = null;
    });
    await _submitAnswer(exercise, answer);
  }

  Future<void> _selectChoiceAnswer(
    ExerciseModel exercise,
    String answer,
  ) async {
    if (_lastAnswerCorrect != null || _isCompleting) {
      return;
    }

    setState(() {
      _selectedAnswer = answer;
      _answerError = null;
    });
    await _submitAnswer(exercise, answer);
  }

  Future<void> _submitAnswer(ExerciseModel exercise, String answer) async {
    await _audioPlayer.stop();
    final isCorrect = _isCorrect(exercise, answer);
    final timeSpentMs = DateTime.now()
        .difference(_questionStartedAt)
        .inMilliseconds
        .clamp(0, 24 * 60 * 60 * 1000);

    setState(() {
      _isPlayingAudio = false;
      _lastAnswerCorrect = isCorrect;
      _answers.add(
        LevelAnswerModel(
          exerciseId: exercise.id,
          userAnswer: answer.trim(),
          isCorrect: isCorrect,
          timeSpentMs: timeSpentMs,
        ),
      );
    });
  }

  Future<void> _continue() async {
    final session = _session;
    if (session == null || _lastAnswerCorrect == null || _isCompleting) {
      return;
    }

    if (_currentIndex < session.exercises.length - 1) {
      setState(() {
        _currentIndex += 1;
        _selectedAnswer = null;
        _answerError = null;
        _lastAnswerCorrect = null;
        _answerController.clear();
        _questionStartedAt = DateTime.now();
      });
      return;
    }

    await _completeLevel();
  }

  Future<void> _completeLevel() async {
    final levelId = int.tryParse(widget.levelId);
    if (levelId == null || levelId <= 0) {
      setState(() {
        _errorMessage = 'Не удалось завершить тренировку.';
      });
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    try {
      final result = await ref
          .read(learningControllerProvider)
          .completeLevel(levelId, answers: List<LevelAnswerModel>.of(_answers));

      if (!mounted) {
        return;
      }

      setState(() {
        _isCompleting = false;
      });
      await _refreshProgressAfterCompletion(result);
      await _showResultSheet(result);
    } on LearningUnauthorizedException {
      if (mounted) {
        context.go(AppRoutes.first);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCompleting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFromError(error))));
    }
  }

  Future<void> _showResultSheet(CompleteLevelResultModel result) async {
    await showModalBottomSheet<void>(
      context: context,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ResultSheet(
          result: result,
          session: _session,
          onRetry: () {
            Navigator.of(sheetContext).pop();
            _loadSession();
          },
          onSections: () {
            Navigator.of(sheetContext).pop();
            _goToLevelSelection();
          },
        );
      },
      isScrollControlled: true,
    );
  }

  Future<void> _refreshProgressAfterCompletion(
    CompleteLevelResultModel result,
  ) async {
    await _ignoreRefreshError(
      ref.read(profileControllerProvider).loadProfile(),
    );
    await _ignoreRefreshError(
      ref.read(continueLearningControllerProvider).loadSections(),
    );

    if (!result.isLevelCompleted) {
      return;
    }

    final controller = ref.read(learningControllerProvider);
    final sectionId = _sectionId;
    if (sectionId != null && sectionId > 0) {
      await _ignoreRefreshError(controller.loadSection(sectionId));
      await _ignoreRefreshError(controller.loadLevels(sectionId));
    }

    final nextLevelId = result.openedNextLevelId;
    if (nextLevelId == null || nextLevelId <= 0 || _sectionId != null) {
      return;
    }

    try {
      final details = await controller.loadLevelDetails(nextLevelId);
      if (mounted && details.sectionId > 0) {
        setState(() {
          _sectionId = details.sectionId;
        });
      }
    } catch (_) {}
  }

  Future<void> _ignoreRefreshError(Future<dynamic> future) async {
    try {
      await future;
    } catch (_) {}
  }

  void _goToLevelSelection() {
    final sectionId = _sectionId;
    if (sectionId != null && sectionId > 0) {
      context.go(AppRoutes.levelsForSection(sectionId.toString()));
      return;
    }

    context.go(AppRoutes.sections);
  }

  void _goBack() {
    final sectionId = _sectionId;
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

  bool _isCorrect(ExerciseModel exercise, String answer) {
    if (exercise.isInput) {
      return normalizeAnswer(answer) == normalizeAnswer(exercise.correctAnswer);
    }

    return answer.trim() == exercise.correctAnswer.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      resizeToAvoidBottomInset: true,
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
          onRetry: _loadSession,
          onBack: _goBack,
        ),
      );
    }

    final session = _session;
    if (session == null || session.exercises.isEmpty) {
      return _EmptySessionView(onBack: _goBack);
    }

    final exercise = session.exercises[_currentIndex];
    final hasImage =
        !exercise.isAudioChoice && exercise.questionImageUrl.trim().isNotEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(21, 8, 21, 0),
          child: _Header(title: _headerTitle(session), onBack: _goBack),
        ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(21, 12, 21, 20),
            children: [
              _ExerciseProgress(
                current: _currentIndex + 1,
                total: session.exercises.length,
              ),
              const SizedBox(height: 20),
              _TaskCard(
                exercise: exercise,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasImage) ...[
                      _QuestionImage(imageUrl: exercise.questionImageUrl),
                      const SizedBox(height: 22),
                    ],
                    if (hasImage || exercise.isAudioChoice)
                      _QuestionBlock(exercise: exercise)
                    else
                      _TextQuestionPanel(exercise: exercise),
                    if (exercise.isAudioChoice) ...[
                      const SizedBox(height: 24),
                      _AudioPrompt(
                        enabled:
                            buildMediaUrl(exercise.questionAudioUrl) != null,
                        isPlaying: _isPlayingAudio,
                        onPlay: () => _playQuestionAudio(exercise),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (exercise.isInput)
                      _InputAnswer(
                        controller: _answerController,
                        enabled: _lastAnswerCorrect == null && !_isCompleting,
                        answerState: _lastAnswerCorrect,
                        onSubmitted: () => _submitInputAnswer(exercise),
                        onChanged: (_) {
                          if (_answerError != null) {
                            setState(() {
                              _answerError = null;
                            });
                          }
                        },
                      )
                    else
                      _ChoiceAnswers(
                        exercise: exercise,
                        selectedAnswer: _selectedAnswer,
                        answerState: _lastAnswerCorrect,
                        isAnswered: _lastAnswerCorrect != null,
                        onSelect: (answer) =>
                            _selectChoiceAnswer(exercise, answer),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            18 + MediaQuery.paddingOf(context).bottom,
          ),
          child: _BottomAction(
            exercise: exercise,
            state: _lastAnswerCorrect,
            errorText: _answerError,
            isCompleting: _isCompleting,
            onAnswer: exercise.isInput
                ? () => _submitInputAnswer(exercise)
                : null,
            onContinue: _continue,
          ),
        ),
      ],
    );
  }

  String _headerTitle(LevelSessionModel session) {
    final sectionTitle = session.sectionTitle.trim();
    if (sectionTitle.isNotEmpty) {
      return sectionTitle;
    }

    final title = session.title.trim();
    if (title.isNotEmpty) {
      return title;
    }

    return 'Тренировка';
  }

  String _messageFromError(Object error) {
    return friendlyErrorMessage(
      error,
      fallback: 'Не удалось загрузить тренировку. Попробуйте еще раз.',
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.exercise, required this.child});

  final ExerciseModel exercise;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: _TasksScreenState._cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [child],
      ),
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

class _ExerciseProgress extends StatelessWidget {
  const _ExerciseProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : current / total;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final progressWidth =
                constraints.maxWidth * progress.clamp(0.0, 1.0);

            return Container(
              height: 12,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: progressWidth,
                  decoration: BoxDecoration(
                    color: _TasksScreenState._accentColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 9),
        Text(
          'Задание $current из $total',
          style: const TextStyle(
            color: _TasksScreenState._accentColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({required this.exercise});

  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _questionTitle(exercise),
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _questionSubtitle(exercise),
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _TextQuestionPanel extends StatelessWidget {
  const _TextQuestionPanel({required this.exercise});

  final ExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: _TasksScreenState._accentColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _TasksScreenState._accentColor.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _TasksScreenState._accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              exercise.isInput ? Icons.edit_rounded : Icons.translate_rounded,
              color: _TasksScreenState._solidCardColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _questionTitle(exercise),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _questionSubtitle(exercise),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionImage extends StatelessWidget {
  const _QuestionImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final fullUrl = buildMediaUrl(imageUrl);

    return AspectRatio(
      aspectRatio: 1.05,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _TasksScreenState._solidCardColor.withValues(alpha: 0.78),
          ),
          child: fullUrl == null
              ? const _MissingMedia(icon: Icons.image_not_supported_rounded)
              : Image.network(
                  fullUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _MissingMedia(
                    icon: Icons.image_not_supported_rounded,
                  ),
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

class _AudioPrompt extends StatelessWidget {
  const _AudioPrompt({
    required this.enabled,
    required this.isPlaying,
    required this.onPlay,
  });

  final bool enabled;
  final bool isPlaying;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
      decoration: BoxDecoration(
        color: _TasksScreenState._accentColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _TasksScreenState._accentColor.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Прослушайте слово',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Tooltip(
            message: enabled ? 'Проиграть аудио' : 'Аудио нет',
            child: IconButton.filled(
              onPressed: enabled ? onPlay : null,
              style: IconButton.styleFrom(
                backgroundColor: enabled
                    ? _TasksScreenState._accentColor
                    : Colors.white.withValues(alpha: 0.16),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.16),
                foregroundColor: _TasksScreenState._solidCardColor,
                disabledForegroundColor: Colors.white54,
                fixedSize: const Size.square(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(
                isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                size: 31,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputAnswer extends StatelessWidget {
  const _InputAnswer({
    required this.controller,
    required this.enabled,
    required this.answerState,
    required this.onSubmitted,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool? answerState;
  final VoidCallback onSubmitted;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final state = answerState;
    final fillColor = state == null
        ? Colors.white
        : state
        ? _TasksScreenState._successColor
        : _TasksScreenState._dangerColor;
    final textColor = state == null || state
        ? _TasksScreenState._solidCardColor
        : Colors.white;
    final hintColor = textColor.withValues(alpha: 0.48);

    return TextField(
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: onChanged,
      onSubmitted: (_) {
        if (enabled) {
          onSubmitted();
        }
      },
      style: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Введите ответ',
        hintStyle: TextStyle(
          color: hintColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: fillColor,
        suffixIcon: Icon(
          Icons.edit_rounded,
          color: textColor.withValues(alpha: 0.62),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: _TasksScreenState._accentColor,
            width: 3,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _InputFeedback extends StatelessWidget {
  const _InputFeedback({required this.errorText, required this.answerState});

  final String? errorText;
  final bool? answerState;

  @override
  Widget build(BuildContext context) {
    final error = errorText;
    final state = answerState;
    if (error == null && state == null) {
      return const SizedBox.shrink();
    }

    final isError = error != null || state == false;
    final text = error ?? (state == true ? 'Верно!' : 'Неверно!');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isError
              ? _TasksScreenState._dangerColor
              : _TasksScreenState._successColor,
          fontSize: isError ? 16 : 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.exercise,
    required this.state,
    required this.errorText,
    required this.isCompleting,
    required this.onAnswer,
    required this.onContinue,
  });

  final ExerciseModel exercise;
  final bool? state;
  final String? errorText;
  final bool isCompleting;
  final VoidCallback? onAnswer;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isAnswered = state != null;
    final isInputWaiting = exercise.isInput && !isAnswered;

    final canPress = isInputWaiting || isAnswered;
    final text = isAnswered
        ? 'Далее'
        : exercise.isInput
        ? 'Ответить'
        : 'Выберите ответ';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InputFeedback(errorText: errorText, answerState: state),
        FilledButton(
          onPressed: canPress && !isCompleting
              ? (isAnswered ? onContinue : onAnswer)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: _TasksScreenState._accentColor,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
            foregroundColor: _TasksScreenState._solidCardColor,
            disabledForegroundColor: Colors.white54,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isCompleting
              ? const SizedBox.square(
                  dimension: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: _TasksScreenState._solidCardColor,
                  ),
                )
              : Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montserrat',
                  ),
                ),
        ),
      ],
    );
  }
}

class _ChoiceAnswers extends StatelessWidget {
  const _ChoiceAnswers({
    required this.exercise,
    required this.selectedAnswer,
    required this.answerState,
    required this.isAnswered,
    required this.onSelect,
  });

  final ExerciseModel exercise;
  final String? selectedAnswer;
  final bool? answerState;
  final bool isAnswered;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = exercise.options.isEmpty
        ? <String>[exercise.correctAnswer]
        : exercise.options;

    return Column(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          _ChoiceButton(
            option: options[index],
            index: index,
            isSelected: selectedAnswer == options[index],
            answerState: answerState,
            isAnswered: isAnswered,
            onTap: () => onSelect(options[index]),
          ),
          const SizedBox(height: 13),
        ],
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.option,
    required this.index,
    required this.isSelected,
    required this.answerState,
    required this.isAnswered,
    required this.onTap,
  });

  final String option;
  final int index;
  final bool isSelected;
  final bool? answerState;
  final bool isAnswered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = answerState == true
        ? _TasksScreenState._successColor
        : _TasksScreenState._dangerColor;
    final borderColor = isSelected ? selectedColor : Colors.transparent;
    final backgroundColor = isSelected ? selectedColor : Colors.white;
    final textColor = isSelected && answerState == false
        ? Colors.white
        : _TasksScreenState._solidCardColor;
    final markerBackground = isSelected
        ? Colors.white.withValues(alpha: answerState == false ? 0.24 : 0.56)
        : _TasksScreenState._accentColor.withValues(alpha: 0.24);
    final markerTextColor = isSelected && answerState == false
        ? Colors.white
        : _TasksScreenState._solidCardColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: isAnswered ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: markerBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _optionLetter(index),
                    style: TextStyle(
                      color: markerTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  textAlign: TextAlign.left,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({
    required this.result,
    required this.session,
    required this.onRetry,
    required this.onSections,
  });

  final CompleteLevelResultModel result;
  final LevelSessionModel? session;
  final VoidCallback onRetry;
  final VoidCallback onSections;

  @override
  Widget build(BuildContext context) {
    final completed = result.isLevelCompleted;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          28,
          24,
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
                            _resultLevelLabel(session),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              color: _TasksScreenState._purpleColor,
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            completed ? 'Уровень\nпройден' : 'Еще разок',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              color: _TasksScreenState._solidCardColor,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.04,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _resultLabel(result),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: completed
                                  ? _TasksScreenState._successColor
                                  : _TasksScreenState._dangerColor,
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              height: 1.08,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 118,
                      height: 118,
                      child: Image.asset(
                        completed
                            ? 'images/mascot_levels/level_win_1.png'
                            : 'images/mascot_levels/level_lose_1.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: completed ? onSections : onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: _TasksScreenState._purpleColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: Text(completed ? 'Завершить' : 'Повторить'),
                ),
                if (!completed) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onSections,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _TasksScreenState._purpleColor,
                      side: const BorderSide(
                        color: _TasksScreenState._purpleColor,
                        width: 2,
                      ),
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('К уровням'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySessionView extends StatelessWidget {
  const _EmptySessionView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        22 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _Header(title: 'Тренировка', onBack: onBack),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          decoration: BoxDecoration(
            color: _TasksScreenState._cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: _TasksScreenState._accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: _TasksScreenState._accentColor,
                  size: 46,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'В этом уровне пока нет упражнений.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Вернитесь к разделам и выберите другой уровень.',
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
                onPressed: onBack,
                style: FilledButton.styleFrom(
                  backgroundColor: _TasksScreenState._accentColor,
                  foregroundColor: _TasksScreenState._solidCardColor,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Назад'),
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
        color: _TasksScreenState._cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _TasksScreenState._dangerColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: _TasksScreenState._accentColor,
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
              backgroundColor: _TasksScreenState._accentColor,
              foregroundColor: _TasksScreenState._solidCardColor,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
    );
  }
}

class _MissingMedia extends StatelessWidget {
  const _MissingMedia({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(icon, color: _TasksScreenState._accentColor, size: 54),
    );
  }
}

String _questionTitle(ExerciseModel exercise) {
  if (exercise.isAudioChoice) {
    return 'Что звучит?';
  }

  if (exercise.type == 'picture_to_english_input') {
    return 'Что это?';
  }

  final text = exercise.questionText.trim();
  return text.isEmpty ? 'Задание' : text;
}

String _questionSubtitle(ExerciseModel exercise) {
  switch (exercise.type) {
    case 'picture_to_english_input':
      return 'Напишите слово на английском';
    case 'english_to_russian_choice':
      return 'Выберите перевод слова';
    case 'russian_to_english_choice':
      return 'Выберите слово на английском';
    case 'russian_to_english_input':
      return 'Напишите слово на английском';
    case 'english_to_russian_input':
      return 'Напишите перевод на русском';
    case 'audio_to_russian_choice':
      return 'Выберите перевод';
    default:
      return exercise.isInput ? 'Введите ответ' : 'Выберите ответ';
  }
}

String _optionLetter(int index) {
  const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
  if (index >= 0 && index < letters.length) {
    return letters[index];
  }

  return '${index + 1}';
}

String _resultLevelLabel(LevelSessionModel? session) {
  if (session == null) {
    return 'Уровень';
  }

  final section = session.sectionTitle.trim();
  final level = _resultLevelName(session);

  if (section.isEmpty) {
    return level;
  }

  return '$section, $level';
}

String _resultLevelName(LevelSessionModel session) {
  if (session.isFinalTest) {
    return 'Тест';
  }

  final match = RegExp(r'(\d+)\s*$').firstMatch(session.title.trim());
  final levelNumber = int.tryParse(match?.group(1) ?? '');
  switch (levelNumber) {
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
  }

  final title = session.title.trim();
  return title.isEmpty ? 'Уровень' : title;
}

String _resultLabel(CompleteLevelResultModel result) {
  if (result.isLevelCompleted) {
    return 'Без ошибок';
  }

  final mistakes = result.mistakesCount;
  if (mistakes == 1) {
    return '1 ошибка';
  }

  final lastTwo = mistakes.abs() % 100;
  final last = mistakes.abs() % 10;
  if (lastTwo < 11 || lastTwo > 14) {
    if (last >= 2 && last <= 4) {
      return '$mistakes ошибки';
    }
  }

  return '$mistakes ошибок';
}
