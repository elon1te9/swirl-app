using Microsoft.EntityFrameworkCore;
using Swirl.Api.Data;
using Swirl.Api.Interfaces;
using Swirl.Api.Models;
using Swirl.Api.Requests;
using Swirl.Api.Responses;

namespace Swirl.Api.Services;

public class DailyTestService : IDailyTestService
{
    private const int MinimumLearnedWords = 5;
    private const int MaximumQuestions = 30;

    private static readonly string[] ExerciseTypes =
    {
        "picture_to_english_input",
        "english_to_russian_choice",
        "russian_to_english_choice",
        "russian_to_english_input",
        "english_to_russian_input",
        "audio_to_russian_choice"
    };

    private static readonly string[] ChoiceExerciseTypes =
    {
        "english_to_russian_choice",
        "russian_to_english_choice",
        "audio_to_russian_choice"
    };

    private readonly AppDbContext _context;
    private readonly IStreakService _streakService;

    public DailyTestService(AppDbContext context, IStreakService streakService)
    {
        _context = context;
        _streakService = streakService;
    }

    public async Task<DailyTestResponse> GetDailyTestAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var today = GetServerDate();
        var isCompletedToday = await _context.DailyTests
            .AnyAsync(
                candidate =>
                    candidate.UserId == userId
                    && candidate.TestDate == today
                    && candidate.IsCompleted,
                cancellationToken);

        if (isCompletedToday)
        {
            return new DailyTestResponse
            {
                Date = today,
                IsAvailable = false,
                IsCompleted = true,
                Reason = "Daily test is already completed"
            };
        }

        var learnedWords = await GetLearnedWordsAsync(userId, cancellationToken);

        if (learnedWords.Count < MinimumLearnedWords)
        {
            return new DailyTestResponse
            {
                Date = today,
                IsAvailable = false,
                IsCompleted = false,
                Reason = "Not enough learned words"
            };
        }

        var selectedWords = Shuffle(learnedWords)
            .Take(Math.Min(MaximumQuestions, learnedWords.Count))
            .ToList();
        var shuffledExerciseTypes = Shuffle(ExerciseTypes);
        var optionUsage = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);

        var exercises = selectedWords
            .Select((word, index) => CreateExercise(
                index + 1,
                word,
                learnedWords,
                shuffledExerciseTypes[index % shuffledExerciseTypes.Count],
                optionUsage))
            .ToList();

        return new DailyTestResponse
        {
            Date = today,
            IsAvailable = true,
            IsCompleted = false,
            ExercisesCount = exercises.Count,
            Exercises = exercises
        };
    }

    public async Task<CompleteDailyTestResponse> CompleteDailyTestAsync(
        Guid userId,
        CompleteDailyTestRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.Answers.Count == 0)
        {
            throw CreateValidationException("answers", "Answers are required");
        }

        var today = GetServerDate();
        var learnedWords = await GetLearnedWordsAsync(userId, cancellationToken);
        if (learnedWords.Count < MinimumLearnedWords)
        {
            throw new ApiException(
                StatusCodes.Status409Conflict,
                "not_enough_learned_words",
                "Learn more words to unlock the daily test");
        }

        var existingCompletedTest = await _context.DailyTests
            .AnyAsync(
                candidate =>
                    candidate.UserId == userId
                    && candidate.TestDate == today
                    && candidate.IsCompleted,
                cancellationToken);

        if (existingCompletedTest)
        {
            throw new ApiException(
                StatusCodes.Status409Conflict,
                "daily_test_already_completed",
                "Daily test is already completed");
        }

        var distinctAnswerWordIds = request.Answers
            .Select(answer => answer.WordId)
            .Distinct()
            .ToArray();

        if (distinctAnswerWordIds.Length != request.Answers.Count)
        {
            throw CreateValidationException("answers", "Daily test answers must not contain duplicate words");
        }

        if (request.Answers.Any(answer => !ExerciseTypes.Contains(answer.ExerciseType)))
        {
            throw CreateValidationException("answers", "Exercise type is not supported");
        }

        if (request.Answers.Count > Math.Min(MaximumQuestions, learnedWords.Count))
        {
            throw CreateValidationException("answers", "Too many answers for daily test");
        }

        var learnedWordsById = learnedWords.ToDictionary(word => word.Id);
        if (distinctAnswerWordIds.Any(wordId => !learnedWordsById.ContainsKey(wordId)))
        {
            throw CreateValidationException("answers", "Word ids must belong to learned words");
        }

        var now = CreateTimestamp();
        var checkedAnswers = new List<CheckedDailyTestAnswer>();
        foreach (var answer in request.Answers)
        {
            var word = learnedWordsById[answer.WordId];
            var correctAnswer = GetCorrectAnswer(answer.ExerciseType, word);
            var userAnswer = answer.UserAnswer ?? string.Empty;

            checkedAnswers.Add(new CheckedDailyTestAnswer
            {
                WordId = answer.WordId,
                ExerciseType = answer.ExerciseType,
                UserAnswer = userAnswer,
                IsCorrect = Normalize(userAnswer) == Normalize(correctAnswer)
            });
        }

        var dailyTest = await _context.DailyTests
            .Include(candidate => candidate.DailyTestAnswers)
            .FirstOrDefaultAsync(
                candidate => candidate.UserId == userId && candidate.TestDate == today,
                cancellationToken);

        if (dailyTest is null)
        {
            dailyTest = new DailyTest
            {
                UserId = userId,
                TestDate = today,
                StartedAt = now
            };
            _context.DailyTests.Add(dailyTest);
        }
        else
        {
            _context.DailyTestAnswers.RemoveRange(dailyTest.DailyTestAnswers);
        }

        dailyTest.CompletedAt = now;
        dailyTest.TotalQuestions = checkedAnswers.Count;
        dailyTest.CorrectAnswers = checkedAnswers.Count(answer => answer.IsCorrect);
        dailyTest.IsCompleted = true;

        dailyTest.DailyTestAnswers = new List<DailyTestAnswer>();
        foreach (var answer in checkedAnswers)
        {
            dailyTest.DailyTestAnswers.Add(new DailyTestAnswer
            {
                DailyTest = dailyTest,
                WordId = answer.WordId,
                ExerciseType = answer.ExerciseType,
                UserAnswerText = answer.UserAnswer,
                IsCorrect = answer.IsCorrect,
                AnsweredAt = now
            });
        }

        await _context.SaveChangesAsync(cancellationToken);
        var streak = await _streakService.UpdateLearningActivityAsync(userId, cancellationToken);

        return new CompleteDailyTestResponse
        {
            Completed = true,
            CorrectAnswers = dailyTest.CorrectAnswers,
            TotalAnswers = dailyTest.TotalQuestions,
            CurrentStreak = streak.CurrentStreak,
            BestStreak = streak.BestStreak
        };
    }

    private static DailyTestExerciseResponse CreateExercise(
        int id,
        LearnedWord word,
        List<LearnedWord> learnedWords,
        string type,
        Dictionary<string, int> optionUsage)
    {
        type = EnsureMediaIsAvailable(type, word);
        var options = new List<string>();

        if (ChoiceExerciseTypes.Contains(type))
        {
            options = CreateChoiceOptions(type, word, learnedWords, optionUsage);
            if (options.Count < 4)
            {
                type = UsesRussianAnswer(type)
                    ? "english_to_russian_input"
                    : "russian_to_english_input";
                options = new List<string>();
            }
        }

        return new DailyTestExerciseResponse
        {
            Id = id,
            WordId = word.Id,
            Type = type,
            QuestionText = GetQuestionText(type, word),
            QuestionImageUrl = type == "picture_to_english_input"
                ? word.ImageUrl
                : null,
            QuestionAudioUrl = type == "audio_to_russian_choice"
                ? word.AudioUrl
                : null,
            CorrectAnswer = GetCorrectAnswer(type, word),
            Options = options
        };
    }

    private static List<string> CreateChoiceOptions(
        string type,
        LearnedWord word,
        List<LearnedWord> learnedWords,
        Dictionary<string, int> optionUsage)
    {
        var correctAnswer = GetCorrectAnswer(type, word);
        var incorrectOptions = learnedWords
            .Where(candidate => candidate.Id != word.Id)
            .Select(candidate => UsesRussianAnswer(type) ? candidate.Russian : candidate.English)
            .Where(option => !string.IsNullOrWhiteSpace(option))
            .Where(option => !string.Equals(option, correctAnswer, StringComparison.OrdinalIgnoreCase))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(option => optionUsage.GetValueOrDefault(option))
            .ThenBy(_ => Random.Shared.Next())
            .Take(3)
            .ToList();

        if (incorrectOptions.Count < 3)
        {
            return new List<string>();
        }

        foreach (var incorrectOption in incorrectOptions)
        {
            optionUsage[incorrectOption] = optionUsage.GetValueOrDefault(incorrectOption) + 1;
        }

        var options = new List<string>();
        options.Add(correctAnswer);
        options.AddRange(incorrectOptions);

        return Shuffle(options);
    }

    private async Task<List<LearnedWord>> GetLearnedWordsAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        return await _context.UserWordProgresses
            .Where(progress =>
                progress.UserId == userId
                && progress.Word.IsActive
                && progress.Word.Level.IsActive
                && progress.Word.Level.Section.IsActive)
            .OrderBy(progress => progress.WordId)
            .Select(progress => new LearnedWord
            {
                Id = progress.WordId,
                English = progress.Word.English,
                Russian = progress.Word.Russian,
                ImageUrl = progress.Word.ImageUrl,
                AudioUrl = progress.Word.AudioUrl
            })
            .ToListAsync(cancellationToken);
    }

    private static string? GetQuestionText(string type, LearnedWord word)
    {
        if (type == "english_to_russian_choice" || type == "english_to_russian_input")
        {
            return word.English;
        }

        if (type == "russian_to_english_choice" || type == "russian_to_english_input")
        {
            return word.Russian;
        }

        if (type == "audio_to_russian_choice")
        {
            return null;
        }

        return word.English;
    }

    private static string GetCorrectAnswer(string type, LearnedWord word)
    {
        if (UsesRussianAnswer(type))
        {
            return word.Russian;
        }

        return word.English;
    }

    private static bool UsesRussianAnswer(string type)
    {
        return type == "english_to_russian_choice"
            || type == "english_to_russian_input"
            || type == "audio_to_russian_choice";
    }

    private static string EnsureMediaIsAvailable(string type, LearnedWord word)
    {
        if (type == "picture_to_english_input" && string.IsNullOrWhiteSpace(word.ImageUrl))
        {
            return "russian_to_english_input";
        }

        if (type == "audio_to_russian_choice" && string.IsNullOrWhiteSpace(word.AudioUrl))
        {
            return "english_to_russian_choice";
        }

        return type;
    }

    private static string Normalize(string? value)
    {
        return System.Text.RegularExpressions.Regex.Replace(
            (value ?? string.Empty).Trim().ToLowerInvariant(),
            @"\s+",
            " ");
    }

    private static List<T> Shuffle<T>(IEnumerable<T> values)
    {
        return values
            .OrderBy(_ => Random.Shared.Next())
            .ToList();
    }

    private static DateOnly GetServerDate()
    {
        return DateOnly.FromDateTime(DateTime.Now);
    }

    private static DateTime CreateTimestamp()
    {
        return DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
    }

    private static ApiException CreateValidationException(string field, string message)
    {
        return new ApiException(
            StatusCodes.Status400BadRequest,
            "validation_error",
            "Validation failed",
            new Dictionary<string, string[]>
            {
                [field] = new[] { message }
            });
    }

    private class LearnedWord
    {
        public int Id { get; set; }

        public string English { get; set; } = string.Empty;

        public string Russian { get; set; } = string.Empty;

        public string? ImageUrl { get; set; }

        public string? AudioUrl { get; set; }
    }

    private class CheckedDailyTestAnswer
    {
        public int WordId { get; set; }

        public string ExerciseType { get; set; } = string.Empty;

        public string UserAnswer { get; set; } = string.Empty;

        public bool IsCorrect { get; set; }
    }
}
