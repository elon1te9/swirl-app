import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/utils/answer_normalizer.dart';
import '../../core/utils/api_error_utils.dart';
import '../../core/utils/media_url_builder.dart';
import '../../domain/models/daily_test_model.dart';
import '../state/daily_test_provider.dart';
import '../state/profile_provider.dart';

class DailyTestScreen extends ConsumerStatefulWidget {
  const DailyTestScreen({super.key});

  @override
  ConsumerState<DailyTestScreen> createState() => _DailyTestScreenState();
}

class _DailyTestScreenState extends ConsumerState<DailyTestScreen> {
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
  bool _alreadyCompleted = false;
  String? _errorMessage;
  String? _unavailableMessage;
  DailyTestModel? _test;
  int _currentIndex = 0;
  String? _selectedAnswer;
  String? _answerError;
  bool? _lastAnswerCorrect;
  final List<DailyTestAnswerModel> _answers = [];

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
    Future.microtask(_loadDailyTest);
  }

  @override
  void dispose() {
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyTest() async {
    await _audioPlayer.stop();
    setState(() {
      _isLoading = true;
      _isCompleting = false;
      _isPlayingAudio = false;
      _alreadyCompleted = false;
      _errorMessage = null;
      _unavailableMessage = null;
      _test = null;
      _currentIndex = 0;
      _selectedAnswer = null;
      _answerError = null;
      _lastAnswerCorrect = null;
      _answers.clear();
      _answerController.clear();
    });

    try {
      final test = await ref.read(dailyTestControllerProvider).loadDailyTest();
      if (!mounted) {
        return;
      }

      setState(() {
        _test = test;
        _isLoading = false;
        if (test.isCompleted) {
          _alreadyCompleted = true;
          _unavailableMessage = _unavailableText(test.reason);
        } else if (!test.isAvailable) {
          _unavailableMessage = _unavailableText(test.reason);
        } else if (test.exercises.isEmpty) {
          _unavailableMessage = 'Тест пока пуст.';
        }
      });
    } on DailyTestUnauthorizedException {
      if (mounted) {
        context.go(AppRoutes.first);
      }
    } on DailyTestUnavailableException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _unavailableMessage = _messageFromError(error);
      });
    } on DailyTestAlreadyCompletedException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _alreadyCompleted = true;
        _unavailableMessage = _messageFromError(error);
      });
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

  Future<void> _playQuestionAudio(DailyTestExerciseModel exercise) async {
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

  Future<void> _submitInputAnswer(DailyTestExerciseModel exercise) async {
    if (_lastAnswerCorrect != null || _isCompleting) {
      return;
    }

    final answer = _answerController.text;
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
    DailyTestExerciseModel exercise,
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

  Future<void> _submitAnswer(
    DailyTestExerciseModel exercise,
    String answer,
  ) async {
    await _audioPlayer.stop();
    final isCorrect = _isCorrect(exercise, answer);

    setState(() {
      _isPlayingAudio = false;
      _lastAnswerCorrect = isCorrect;
      _answers.add(
        DailyTestAnswerModel(
          wordId: exercise.wordId,
          exerciseType: exercise.type,
          userAnswer: answer.trim(),
          isCorrect: isCorrect,
        ),
      );
    });
  }

  Future<void> _continue() async {
    final test = _test;
    if (test == null || _lastAnswerCorrect == null || _isCompleting) {
      return;
    }

    if (_currentIndex < test.exercises.length - 1) {
      setState(() {
        _currentIndex += 1;
        _selectedAnswer = null;
        _answerError = null;
        _lastAnswerCorrect = null;
        _answerController.clear();
      });
      return;
    }

    await _completeDailyTest();
  }

  Future<void> _completeDailyTest() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      final result = await ref
          .read(dailyTestControllerProvider)
          .completeDailyTest(answers: List<DailyTestAnswerModel>.of(_answers));
      if (!mounted) {
        return;
      }

      setState(() {
        _isCompleting = false;
      });
      await _refreshProfileAfterCompletion();
      await _showResultSheet(result);
    } on DailyTestUnauthorizedException {
      if (mounted) {
        context.go(AppRoutes.first);
      }
    } on DailyTestUnavailableException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCompleting = false;
        _unavailableMessage = _messageFromError(error);
      });
    } on DailyTestAlreadyCompletedException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCompleting = false;
        _alreadyCompleted = true;
        _unavailableMessage = _messageFromError(error);
      });
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

  Future<void> _refreshProfileAfterCompletion() async {
    try {
      await ref.read(profileControllerProvider).loadProfile();
    } catch (_) {}
  }

  Future<void> _showResultSheet(CompleteDailyTestResultModel result) async {
    await showModalBottomSheet<void>(
      context: context,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ResultSheet(
          result: result,
          onFinish: () {
            Navigator.of(sheetContext).pop();
            context.go(AppRoutes.home);
          },
        );
      },
      isScrollControlled: true,
    );
  }

  bool _isCorrect(DailyTestExerciseModel exercise, String answer) {
    if (exercise.isInput) {
      return normalizeAnswer(answer) == normalizeAnswer(exercise.correctAnswer);
    }

    return answer.trim() == exercise.correctAnswer.trim();
  }

  void _goHome() {
    context.go(AppRoutes.home);
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
        child: _ErrorPanel(message: error, onRetry: _loadDailyTest),
      );
    }

    final unavailable = _unavailableMessage;
    final test = _test;
    if (unavailable != null ||
        test == null ||
        !test.isAvailable ||
        test.exercises.isEmpty) {
      return _StatusView(
        title: _alreadyCompleted ? 'Уже готово' : 'Тест недоступен',
        message: unavailable ?? 'Изучите больше слов, чтобы открыть тест.',
        icon: _alreadyCompleted
            ? Icons.check_circle_outline_rounded
            : Icons.lock_outline_rounded,
        onHome: _goHome,
        onRetry: _alreadyCompleted ? null : _loadDailyTest,
      );
    }

    final exercise = test.exercises[_currentIndex];
    final hasImage =
        !exercise.isAudioChoice && exercise.questionImageUrl.trim().isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(21, 8, 21, 0),
          child: _Header(title: 'Daily', onBack: _goHome),
        ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(21, 12, 21, 20),
            children: [
              _ExerciseProgress(
                current: _currentIndex + 1,
                total: test.exercises.length,
              ),
              const SizedBox(height: 20),
              _TaskCard(
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

  String _messageFromError(Object error) {
    return friendlyErrorMessage(
      error,
      fallback: 'Не удалось загрузить тест. Попробуйте еще раз.',
    );
  }

  String _unavailableText(String reason) {
    final normalizedReason = reason.trim().toLowerCase();

    if (normalizedReason.isEmpty ||
        normalizedReason == 'not enough learned words') {
      return 'Изучите больше слов, чтобы открыть ежедневный тест.';
    }

    if (normalizedReason == 'daily test is already completed' ||
        normalizedReason == 'daily_test_already_completed') {
      return 'Ежедневный тест уже пройден сегодня.';
    }

    return reason;
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
                  fontSize: 30,
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
                    color: _DailyTestScreenState._accentColor,
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
            color: _DailyTestScreenState._accentColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: _DailyTestScreenState._cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
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
            color: _DailyTestScreenState._solidCardColor.withValues(
              alpha: 0.78,
            ),
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

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({required this.exercise});

  final DailyTestExerciseModel exercise;

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

  final DailyTestExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: _DailyTestScreenState._accentColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _DailyTestScreenState._accentColor.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _DailyTestScreenState._accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              exercise.isInput ? Icons.edit_rounded : Icons.translate_rounded,
              color: _DailyTestScreenState._solidCardColor,
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
        color: _DailyTestScreenState._accentColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _DailyTestScreenState._accentColor.withValues(alpha: 0.28),
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
                    ? _DailyTestScreenState._accentColor
                    : Colors.white.withValues(alpha: 0.16),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.16),
                foregroundColor: _DailyTestScreenState._solidCardColor,
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
        ? _DailyTestScreenState._successColor
        : _DailyTestScreenState._dangerColor;
    final textColor = state == null || state
        ? _DailyTestScreenState._solidCardColor
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
            color: _DailyTestScreenState._accentColor,
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

class _ChoiceAnswers extends StatelessWidget {
  const _ChoiceAnswers({
    required this.exercise,
    required this.selectedAnswer,
    required this.answerState,
    required this.isAnswered,
    required this.onSelect,
  });

  final DailyTestExerciseModel exercise;
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
        ? _DailyTestScreenState._successColor
        : _DailyTestScreenState._dangerColor;
    final borderColor = isSelected ? selectedColor : Colors.transparent;
    final backgroundColor = isSelected ? selectedColor : Colors.white;
    final textColor = isSelected && answerState == false
        ? Colors.white
        : _DailyTestScreenState._solidCardColor;
    final markerBackground = isSelected
        ? Colors.white.withValues(alpha: answerState == false ? 0.24 : 0.56)
        : _DailyTestScreenState._accentColor.withValues(alpha: 0.24);
    final markerTextColor = isSelected && answerState == false
        ? Colors.white
        : _DailyTestScreenState._solidCardColor;

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

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.exercise,
    required this.state,
    required this.errorText,
    required this.isCompleting,
    required this.onAnswer,
    required this.onContinue,
  });

  final DailyTestExerciseModel exercise;
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
            backgroundColor: _DailyTestScreenState._accentColor,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
            foregroundColor: _DailyTestScreenState._solidCardColor,
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
                    color: _DailyTestScreenState._solidCardColor,
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

class _InputFeedback extends StatelessWidget {
  const _InputFeedback({required this.errorText, required this.answerState});

  final String? errorText;
  final bool? answerState;

  @override
  Widget build(BuildContext context) {
    final text = errorText ?? _answerStateText(answerState);
    if (text == null) {
      return const SizedBox(height: 0);
    }

    final color = errorText != null || answerState == false
        ? _DailyTestScreenState._dangerColor
        : _DailyTestScreenState._successColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({required this.result, required this.onFinish});

  final CompleteDailyTestResultModel result;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
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
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ежедневный тест',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: _DailyTestScreenState._purpleColor,
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Готово',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: _DailyTestScreenState._solidCardColor,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.04,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${result.correctAnswers} из ${result.totalAnswers}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              color: _DailyTestScreenState._successColor,
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
                        'images/mascot_levels/level_win_1.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onFinish,
                  style: FilledButton.styleFrom(
                    backgroundColor: _DailyTestScreenState._purpleColor,
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
                  child: const Text('Завершить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.title,
    required this.message,
    required this.icon,
    required this.onHome,
    required this.onRetry,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onHome;
  final VoidCallback? onRetry;

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
        _Header(title: 'Daily', onBack: onHome),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          decoration: BoxDecoration(
            color: _DailyTestScreenState._cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: _DailyTestScreenState._accentColor.withValues(
                    alpha: 0.18,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: _DailyTestScreenState._accentColor,
                  size: 46,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.28,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onHome,
                style: FilledButton.styleFrom(
                  backgroundColor: _DailyTestScreenState._accentColor,
                  foregroundColor: _DailyTestScreenState._solidCardColor,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('На главную'),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRetry,
                  child: const Text(
                    'Обновить',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
        color: _DailyTestScreenState._cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _DailyTestScreenState._dangerColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: _DailyTestScreenState._accentColor,
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
              backgroundColor: _DailyTestScreenState._accentColor,
              foregroundColor: _DailyTestScreenState._solidCardColor,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Повторить'),
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
      child: Icon(icon, color: _DailyTestScreenState._accentColor, size: 54),
    );
  }
}

String _questionTitle(DailyTestExerciseModel exercise) {
  if (exercise.isAudioChoice) {
    return 'Что звучит?';
  }

  if (exercise.type == 'picture_to_english_input') {
    return 'Что это?';
  }

  final text = exercise.questionText.trim();
  return text.isEmpty ? 'Задание' : text;
}

String _questionSubtitle(DailyTestExerciseModel exercise) {
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

String? _answerStateText(bool? answerState) {
  if (answerState == null) {
    return null;
  }

  return answerState ? 'Верно' : 'Неверно';
}

String _optionLetter(int index) {
  const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
  if (index >= 0 && index < letters.length) {
    return letters[index];
  }

  return '${index + 1}';
}
