using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using Swirl.Api.Data;
using Swirl.Api.Interfaces;
using Swirl.Api.Models;
using Swirl.Api.Requests;
using Swirl.Api.Responses;

namespace Swirl.Api.Services;

public partial class DailyTestService(
    AppDbContext dbContext,
    IStreakService streakService) : IDailyTestService
{
    private const int MinimumLearnedWords = 5;
    private const int MaximumQuestions = 30;

    private static readonly string[] ExerciseTypes =
    [
        "english_to_russian_choice",
        "russian_to_english_choice",
        "russian_to_english_input",
        "english_to_russian_input"
    ];

    private static readonly string[] ChoiceExerciseTypes =
    [
        "english_to_russian_choice",
        "russian_to_english_choice"
    ];

    public async Task<DailyTestResponse> GetDailyTestAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var today = GetServerDate();
        var learnedWords = await GetLearnedWordsAsync(userId, cancellationToken);

        if (learnedWords.Count < MinimumLearnedWords)
        {
            return new DailyTestResponse
            {
                Date = today,
                IsAvailable = false,
                Reason = "Not enough learned words"
            };
        }

        var selectedWords = Shuffle(learnedWords)
            .Take(Math.Min(MaximumQuestions, learnedWords.Count))
            .ToList();
        var shuffledExerciseTypes = Shuffle(ExerciseTypes);

        var exercises = selectedWords
            .Select((word, index) => CreateExercise(
                index + 1,
                word,
                learnedWords,
                shuffledExerciseTypes[index % shuffledExerciseTypes.Count]))
            .ToList();

        return new DailyTestResponse
        {
            Date = today,
            IsAvailable = true,
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

        var existingCompletedTest = await dbContext.DailyTests
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
        var checkedAnswers = request.Answers
            .Select(answer =>
            {
                var word = learnedWordsById[answer.WordId];
                var correctAnswer = GetCorrectAnswer(answer.ExerciseType, word);

                return new CheckedDailyTestAnswer(
                    answer.WordId,
                    answer.ExerciseType,
                    answer.UserAnswer ?? string.Empty,
                    Normalize(answer.UserAnswer) == Normalize(correctAnswer));
            })
            .ToList();

        var dailyTest = await dbContext.DailyTests
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
            dbContext.DailyTests.Add(dailyTest);
        }
        else
        {
            dbContext.DailyTestAnswers.RemoveRange(dailyTest.DailyTestAnswers);
        }

        dailyTest.CompletedAt = now;
        dailyTest.TotalQuestions = checkedAnswers.Count;
        dailyTest.CorrectAnswers = checkedAnswers.Count(answer => answer.IsCorrect);
        dailyTest.IsCompleted = true;

        dailyTest.DailyTestAnswers = checkedAnswers
            .Select(answer => new DailyTestAnswer
            {
                DailyTest = dailyTest,
                WordId = answer.WordId,
                ExerciseType = answer.ExerciseType,
                UserAnswerText = answer.UserAnswer,
                IsCorrect = answer.IsCorrect,
                AnsweredAt = now
            })
            .ToList();

        await dbContext.SaveChangesAsync(cancellationToken);
        var streak = await streakService.UpdateLearningActivityAsync(userId, cancellationToken);

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
        string type)
    {
        var options = new List<string>();

        if (ChoiceExerciseTypes.Contains(type))
        {
            options = CreateChoiceOptions(type, word, learnedWords);
            if (options.Count < 4)
            {
                type = type == "english_to_russian_choice"
                    ? "english_to_russian_input"
                    : "russian_to_english_input";
                options = [];
            }
        }

        return new DailyTestExerciseResponse
        {
            Id = id,
            WordId = word.Id,
            Type = type,
            QuestionText = GetQuestionText(type, word),
            QuestionImageUrl = null,
            QuestionAudioUrl = null,
            CorrectAnswer = GetCorrectAnswer(type, word),
            Options = options
        };
    }

    private static List<string> CreateChoiceOptions(
        string type,
        LearnedWord word,
        List<LearnedWord> learnedWords)
    {
        var correctAnswer = GetCorrectAnswer(type, word);
        var incorrectOptions = learnedWords
            .Where(candidate => candidate.Id != word.Id)
            .Select(candidate => UsesRussianAnswer(type) ? candidate.Russian : candidate.English)
            .Where(option => !string.Equals(option, correctAnswer, StringComparison.OrdinalIgnoreCase))
            .Distinct()
            .Take(3)
            .ToList();

        return incorrectOptions.Count < 3
            ? []
            : Shuffle([correctAnswer, .. incorrectOptions]).ToList();
    }

    private async Task<List<LearnedWord>> GetLearnedWordsAsync(
        Guid userId,
        CancellationToken cancellationToken) =>
        await dbContext.UserWordProgresses
            .Where(progress =>
                progress.UserId == userId
                && progress.Word.IsActive
                && progress.Word.Level.IsActive
                && progress.Word.Level.Section.IsActive)
            .OrderBy(progress => progress.WordId)
            .Select(progress => new LearnedWord(
                progress.WordId,
                progress.Word.English,
                progress.Word.Russian))
            .ToListAsync(cancellationToken);

    private static string? GetQuestionText(string type, LearnedWord word) =>
        type switch
        {
            "english_to_russian_choice" => word.English,
            "english_to_russian_input" => word.English,
            "russian_to_english_choice" => word.Russian,
            "russian_to_english_input" => word.Russian,
            _ => word.English
        };

    private static string GetCorrectAnswer(string type, LearnedWord word) =>
        UsesRussianAnswer(type)
            ? word.Russian
            : word.English;

    private static bool UsesRussianAnswer(string type) =>
        type is "english_to_russian_choice" or "english_to_russian_input";

    private static string Normalize(string? value) =>
        RepeatedSpacesRegex()
            .Replace((value ?? string.Empty).Trim().ToLowerInvariant(), " ");

    private static List<T> Shuffle<T>(IEnumerable<T> values) =>
        values
            .OrderBy(_ => Random.Shared.Next())
            .ToList();

    private static DateOnly GetServerDate() =>
        DateOnly.FromDateTime(DateTime.Now);

    private static DateTime CreateTimestamp() =>
        DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);

    private static ApiException CreateValidationException(string field, string message) =>
        new(
            StatusCodes.Status400BadRequest,
            "validation_error",
            "Validation failed",
            new Dictionary<string, string[]>
            {
                [field] = [message]
            });

    [GeneratedRegex(@"\s+")]
    private static partial Regex RepeatedSpacesRegex();

    private sealed record LearnedWord(int Id, string English, string Russian);

    private sealed record CheckedDailyTestAnswer(
        int WordId,
        string ExerciseType,
        string UserAnswer,
        bool IsCorrect);
}
