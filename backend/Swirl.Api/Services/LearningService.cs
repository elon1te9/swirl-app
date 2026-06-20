using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using Swirl.Api.Data;
using Swirl.Api.Interfaces;
using Swirl.Api.Models;
using Swirl.Api.Requests;
using Swirl.Api.Responses;

namespace Swirl.Api.Services;

public class LearningService : ILearningService
{
    private const string LockedStatus = "locked";
    private const string AvailableStatus = "available";
    private const string CompletedStatus = "completed";

    private static readonly HashSet<string> ChoiceExerciseTypes = new()
    {
        "english_to_russian_choice",
        "russian_to_english_choice",
        "audio_to_russian_choice"
    };

    private readonly AppDbContext _context;

    public LearningService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<LevelSessionResponse> GetLevelSessionAsync(
        Guid userId,
        int levelId,
        CancellationToken cancellationToken = default)
    {
        var access = await GetAccessibleLevelAsync(userId, levelId, cancellationToken);
        var exercises = await GetActiveExercisesForLevelAsync(levelId, cancellationToken);
        var optionWords = await GetOptionWordsForLevelAsync(access.Level.SectionId, cancellationToken);
        var optionUsage = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);

        return new LevelSessionResponse
        {
            LevelId = access.Level.Id,
            Title = access.Level.Title,
            SectionTitle = access.Level.Section.Title,
            IsFinalTest = access.Level.IsFinalTest,
            Exercises = exercises
                .Select(exercise => CreateExerciseResponse(exercise, optionWords, optionUsage))
                .ToList()
        };
    }

    public async Task<CompleteLevelResponse> CompleteLevelAsync(
        Guid userId,
        int levelId,
        CompleteLevelRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.Answers.Count == 0)
        {
            throw CreateValidationException("answers", "Answers are required");
        }

        var access = await GetAccessibleLevelAsync(userId, levelId, cancellationToken);
        var exercises = await GetActiveExercisesForLevelAsync(levelId, cancellationToken);
        ValidateAnswersBelongToLevel(request, exercises);

        var exercisesById = exercises.ToDictionary(exercise => exercise.Id);
        var now = CreateTimestamp();
        var checkedAnswers = new List<CheckedAnswer>();
        foreach (var answer in request.Answers)
        {
            var exercise = exercisesById[answer.ExerciseId];
            var userAnswer = answer.UserAnswer ?? string.Empty;
            var isCorrect = NormalizeAnswer(userAnswer) == NormalizeAnswer(exercise.CorrectAnswer);

            checkedAnswers.Add(new CheckedAnswer
            {
                ExerciseId = answer.ExerciseId,
                UserAnswer = userAnswer,
                IsCorrect = isCorrect,
                TimeSpentMs = answer.TimeSpentMs
            });
        }

        var mistakesCount = checkedAnswers.Count(answer => !answer.IsCorrect);
        var isSuccessful = mistakesCount == 0;

        var attempt = new LevelAttempt
        {
            UserId = userId,
            LevelId = levelId,
            StartedAt = now,
            CompletedAt = now,
            MistakesCount = mistakesCount,
            IsSuccessful = isSuccessful
        };
        _context.LevelAttempts.Add(attempt);

        foreach (var answer in checkedAnswers)
        {
            _context.UserAnswers.Add(new UserAnswer
            {
                Attempt = attempt,
                ExerciseId = answer.ExerciseId,
                UserAnswerText = answer.UserAnswer,
                IsCorrect = answer.IsCorrect,
                AnsweredAt = now,
                TimeSpentMs = answer.TimeSpentMs
            });
        }

        var progress = await GetOrCreateLevelProgressAsync(userId, access.Level, access.Progress, now);
        progress.AttemptsCount++;

        int? openedNextLevelId = null;
        if (isSuccessful)
        {
            progress.Status = CompletedStatus;
            if (progress.CompletedAt is null)
            {
                progress.CompletedAt = now;
            }

            openedNextLevelId = await UnlockNextLevelAsync(userId, access.Level, now, cancellationToken);
        }

        var profile = await UpdateStreakAsync(userId, cancellationToken);

        await _context.SaveChangesAsync(cancellationToken);

        return new CompleteLevelResponse
        {
            IsLevelCompleted = isSuccessful,
            MistakesCount = mistakesCount,
            OpenedNextLevelId = openedNextLevelId,
            CurrentStreak = profile.CurrentStreak,
            BestStreak = profile.BestStreak
        };
    }

    private static ExerciseResponse CreateExerciseResponse(
        Exercise exercise,
        List<OptionWord> optionWords,
        Dictionary<string, int> optionUsage)
    {
        var options = new List<string>();
        if (ChoiceExerciseTypes.Contains(exercise.Type))
        {
            options = CreateChoiceOptions(exercise, optionWords, optionUsage);
        }

        return new ExerciseResponse
        {
            Id = exercise.Id,
            Type = exercise.Type,
            QuestionText = exercise.QuestionText,
            QuestionImageUrl = exercise.Type == "picture_to_english_input"
                ? exercise.Word.ImageUrl
                : null,
            QuestionAudioUrl = exercise.Type == "audio_to_russian_choice"
                ? exercise.Word.AudioUrl
                : null,
            CorrectAnswer = exercise.CorrectAnswer,
            Options = options
        };
    }

    private static List<string> CreateChoiceOptions(
        Exercise exercise,
        List<OptionWord> optionWords,
        Dictionary<string, int> optionUsage)
    {
        var correctAnswer = exercise.CorrectAnswer;
        var incorrectOptions = optionWords
            .Where(word => word.Id != exercise.WordId)
            .Select(word => UsesRussianAnswer(exercise.Type) ? word.Russian : word.English)
            .Concat(exercise.ExerciseOptions
                .Where(option => !option.IsCorrect)
                .OrderBy(option => option.SortOrder)
                .ThenBy(option => option.Id)
                .Select(option => option.OptionText))
            .Where(option => !string.IsNullOrWhiteSpace(option))
            .Where(option => !string.Equals(option, correctAnswer, StringComparison.OrdinalIgnoreCase))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(option => optionUsage.GetValueOrDefault(option))
            .ThenBy(_ => Random.Shared.Next())
            .Take(3)
            .ToList();

        foreach (var incorrectOption in incorrectOptions)
        {
            optionUsage[incorrectOption] = optionUsage.GetValueOrDefault(incorrectOption) + 1;
        }

        var options = new List<string> { correctAnswer };
        options.AddRange(incorrectOptions);

        return ShuffleOptions(options);
    }

    private async Task<LevelAccess> GetAccessibleLevelAsync(
        Guid userId,
        int levelId,
        CancellationToken cancellationToken)
    {
        var level = await _context.Levels
            .Include(candidate => candidate.Section)
            .FirstOrDefaultAsync(
                candidate =>
                    candidate.Id == levelId
                    && candidate.IsActive
                    && candidate.Section.IsActive,
                cancellationToken);

        if (level is null)
        {
            throw new ApiException(
                StatusCodes.Status404NotFound,
                "not_found",
                "Resource not found");
        }

        var progress = await _context.UserLevelProgresses
            .FirstOrDefaultAsync(
                candidate => candidate.UserId == userId && candidate.LevelId == levelId,
                cancellationToken);

        var status = progress?.Status ?? await GetFallbackLevelStatusAsync(level, cancellationToken);
        if (status == LockedStatus)
        {
            throw new ApiException(
                StatusCodes.Status409Conflict,
                "level_locked",
                "This level is locked");
        }

        return new LevelAccess
        {
            Level = level,
            Progress = progress
        };
    }

    private async Task<List<Exercise>> GetActiveExercisesForLevelAsync(
        int levelId,
        CancellationToken cancellationToken)
    {
        return await _context.Exercises
            .Include(exercise => exercise.Word)
            .Include(exercise => exercise.ExerciseOptions)
            .Where(exercise => exercise.LevelId == levelId && exercise.IsActive)
            .OrderBy(exercise => exercise.SortOrder ?? int.MaxValue)
            .ThenBy(exercise => exercise.Id)
            .ToListAsync(cancellationToken);
    }

    private async Task<List<OptionWord>> GetOptionWordsForLevelAsync(
        int sectionId,
        CancellationToken cancellationToken)
    {
        return await _context.Words
            .Where(word =>
                word.IsActive
                && word.Level.IsActive
                && !word.Level.IsFinalTest
                && word.Level.SectionId == sectionId)
            .OrderBy(word => word.Level.SortOrder)
            .ThenBy(word => word.Id)
            .Select(word => new OptionWord
            {
                Id = word.Id,
                English = word.English,
                Russian = word.Russian
            })
            .ToListAsync(cancellationToken);
    }

    private static void ValidateAnswersBelongToLevel(
        CompleteLevelRequest request,
        List<Exercise> exercises)
    {
        var activeExerciseIds = exercises
            .Select(exercise => exercise.Id)
            .ToHashSet();
        var submittedExerciseIds = request.Answers
            .Select(answer => answer.ExerciseId)
            .ToArray();
        var distinctSubmittedExerciseIds = submittedExerciseIds.ToHashSet();

        if (distinctSubmittedExerciseIds.Count != submittedExerciseIds.Length)
        {
            throw CreateValidationException("answers", "Each exercise can be answered only once");
        }

        if (submittedExerciseIds.Any(exerciseId => !activeExerciseIds.Contains(exerciseId)))
        {
            throw CreateValidationException("answers", "Exercise ids must belong to the level");
        }

        if (!activeExerciseIds.SetEquals(distinctSubmittedExerciseIds))
        {
            throw CreateValidationException("answers", "Answers must include all active level exercises");
        }
    }

    private async Task<UserLevelProgress> GetOrCreateLevelProgressAsync(
        Guid userId,
        Level level,
        UserLevelProgress? progress,
        DateTime now)
    {
        if (progress is not null)
        {
            return progress;
        }

        var createdProgress = new UserLevelProgress
        {
            UserId = userId,
            LevelId = level.Id,
            Status = AvailableStatus,
            WordsLearned = false,
            AttemptsCount = 0,
            UnlockedAt = now
        };
        _context.UserLevelProgresses.Add(createdProgress);

        return createdProgress;
    }

    private async Task<int?> UnlockNextLevelAsync(
        Guid userId,
        Level completedLevel,
        DateTime now,
        CancellationToken cancellationToken)
    {
        if (completedLevel.IsFinalTest)
        {
            return null;
        }

        var sectionLevels = await _context.Levels
            .Where(level => level.SectionId == completedLevel.SectionId && level.IsActive)
            .OrderBy(level => level.SortOrder)
            .ToListAsync(cancellationToken);

        var normalLevels = sectionLevels
            .Where(level => !level.IsFinalTest)
            .ToList();

        var nextNormalLevel = normalLevels
            .FirstOrDefault(level => level.SortOrder > completedLevel.SortOrder);

        if (nextNormalLevel is not null)
        {
            var nextProgress = await GetOrCreateProgressForUnlockAsync(
                userId,
                nextNormalLevel,
                now,
                cancellationToken);

            if (nextProgress.Status == LockedStatus)
            {
                nextProgress.Status = AvailableStatus;
                nextProgress.UnlockedAt = now;
                return nextNormalLevel.Id;
            }
        }

        var normalLevelIds = normalLevels.Select(level => level.Id).ToArray();
        var completedNormalLevelIds = await _context.UserLevelProgresses
            .Where(progress =>
                progress.UserId == userId
                && progress.Status == CompletedStatus
                && normalLevelIds.Contains(progress.LevelId))
            .Select(progress => progress.LevelId)
            .ToListAsync(cancellationToken);
        completedNormalLevelIds.Add(completedLevel.Id);

        if (normalLevels.All(level => completedNormalLevelIds.Contains(level.Id)))
        {
            var finalTest = sectionLevels.FirstOrDefault(level => level.IsFinalTest);
            if (finalTest is not null)
            {
                var finalProgress = await GetOrCreateProgressForUnlockAsync(
                    userId,
                    finalTest,
                    now,
                    cancellationToken);

                if (finalProgress.Status == LockedStatus)
                {
                    finalProgress.Status = AvailableStatus;
                    finalProgress.UnlockedAt = now;
                    return finalTest.Id;
                }
            }
        }

        return null;
    }

    private async Task<UserLevelProgress> GetOrCreateProgressForUnlockAsync(
        Guid userId,
        Level level,
        DateTime now,
        CancellationToken cancellationToken)
    {
        var progress = await _context.UserLevelProgresses
            .FirstOrDefaultAsync(
                candidate => candidate.UserId == userId && candidate.LevelId == level.Id,
                cancellationToken);

        if (progress is not null)
        {
            return progress;
        }

        progress = new UserLevelProgress
        {
            UserId = userId,
            LevelId = level.Id,
            Status = LockedStatus,
            WordsLearned = false,
            AttemptsCount = 0,
            UnlockedAt = null
        };
        _context.UserLevelProgresses.Add(progress);

        return progress;
    }

    private async Task<string> GetFallbackLevelStatusAsync(
        Level level,
        CancellationToken cancellationToken)
    {
        if (level.IsFinalTest)
        {
            return LockedStatus;
        }

        var firstNormalLevelId = await _context.Levels
            .Where(candidate =>
                candidate.SectionId == level.SectionId
                && candidate.IsActive
                && !candidate.IsFinalTest)
            .OrderBy(candidate => candidate.SortOrder)
            .Select(candidate => candidate.Id)
            .FirstOrDefaultAsync(cancellationToken);

        if (level.Id == firstNormalLevelId)
        {
            return AvailableStatus;
        }

        return LockedStatus;
    }

    private async Task<UserProfile> UpdateStreakAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var profile = await _context.UserProfiles
            .SingleAsync(candidate => candidate.UserId == userId, cancellationToken);
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var yesterday = today.AddDays(-1);

        if (profile.LastActivityDate is null)
        {
            profile.CurrentStreak = 1;
        }
        else if (profile.LastActivityDate == yesterday)
        {
            profile.CurrentStreak++;
        }
        else if (profile.LastActivityDate < yesterday)
        {
            profile.CurrentStreak = 1;
        }

        profile.LastActivityDate = today;
        profile.BestStreak = Math.Max(profile.BestStreak, profile.CurrentStreak);

        return profile;
    }

    private static List<string> ShuffleOptions(List<string> options)
    {
        for (var index = options.Count - 1; index > 0; index--)
        {
            var swapIndex = Random.Shared.Next(index + 1);
            (options[index], options[swapIndex]) = (options[swapIndex], options[index]);
        }

        return options;
    }

    private static bool UsesRussianAnswer(string type)
    {
        return type == "english_to_russian_choice"
            || type == "audio_to_russian_choice";
    }

    private static string NormalizeAnswer(string answer)
    {
        return Regex.Replace(answer.Trim().ToLowerInvariant(), @"\s+", " ");
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

    private static DateTime CreateTimestamp()
    {
        return DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
    }

    private class LevelAccess
    {
        public Level Level { get; set; } = null!;

        public UserLevelProgress? Progress { get; set; }
    }

    private class CheckedAnswer
    {
        public int ExerciseId { get; set; }

        public string UserAnswer { get; set; } = string.Empty;

        public bool IsCorrect { get; set; }

        public int? TimeSpentMs { get; set; }
    }

    private class OptionWord
    {
        public int Id { get; set; }

        public string English { get; set; } = string.Empty;

        public string Russian { get; set; } = string.Empty;
    }
}
