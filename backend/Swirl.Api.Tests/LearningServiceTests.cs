using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Swirl.Api.Data;
using Swirl.Api.Models;
using Swirl.Api.Requests;
using Swirl.Api.Services;

namespace Swirl.Api.Tests;

public class LearningServiceTests
{
    [Fact]
    public async Task GetLevelSessionAsync_ReturnsAvailableLevelExercisesWithOptionsAndMedia()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithLevelProgressAsync(dbContext, "user@example.com");
        var level = await GetSectionLevelAsync(dbContext, "Food", 1);
        var service = new LearningService(dbContext);

        var result = await service.GetLevelSessionAsync(user.Id, level.Id);

        Assert.Equal(level.Id, result.LevelId);
        Assert.Equal("Food Level 1", result.Title);
        Assert.Equal("Food", result.SectionTitle);
        Assert.False(result.IsFinalTest);
        Assert.Equal(6, result.Exercises.Count);

        var choice = Assert.Single(result.Exercises, exercise => exercise.Type == "english_to_russian_choice");
        Assert.Equal(4, choice.Options.Count);
        Assert.Contains(choice.CorrectAnswer, choice.Options);

        var picture = Assert.Single(result.Exercises, exercise => exercise.Type == "picture_to_english_input");
        Assert.StartsWith("/media/images/words/", picture.QuestionImageUrl);
        Assert.Null(picture.QuestionAudioUrl);

        var audio = Assert.Single(result.Exercises, exercise => exercise.Type == "audio_to_russian_choice");
        Assert.StartsWith("/media/audio/words/", audio.QuestionAudioUrl);
        Assert.Null(audio.QuestionImageUrl);
    }

    [Fact]
    public async Task GetLevelSessionAsync_RejectsLockedLevel()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithLevelProgressAsync(dbContext, "user@example.com");
        var level = await GetSectionLevelAsync(dbContext, "Food", 2);
        var service = new LearningService(dbContext);

        var exception = await Assert.ThrowsAsync<ApiException>(() =>
            service.GetLevelSessionAsync(user.Id, level.Id));

        Assert.Equal(StatusCodes.Status409Conflict, exception.StatusCode);
        Assert.Equal("level_locked", exception.Code);
    }

    [Fact]
    public async Task CompleteLevelAsync_IgnoresClientIsCorrectAndSavesFailedAttempt()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithLevelProgressAsync(dbContext, "user@example.com");
        var level = await GetSectionLevelAsync(dbContext, "Food", 1);
        var exercises = await GetActiveExercisesAsync(dbContext, level.Id);
        var request = new CompleteLevelRequest
        {
            Answers = exercises
                .Select((exercise, index) => new CompleteLevelAnswerRequest
                {
                    ExerciseId = exercise.Id,
                    UserAnswer = index == 0 ? "definitely wrong" : exercise.CorrectAnswer,
                    IsCorrect = true,
                    TimeSpentMs = 1000 + index
                })
                .ToList()
        };
        var service = new LearningService(dbContext);

        var result = await service.CompleteLevelAsync(user.Id, level.Id, request);

        Assert.False(result.IsLevelCompleted);
        Assert.Equal(1, result.MistakesCount);
        Assert.Null(result.OpenedNextLevelId);
        Assert.Equal(1, result.CurrentStreak);
        Assert.Equal(1, result.BestStreak);

        var attempt = await dbContext.LevelAttempts.SingleAsync(candidate =>
            candidate.UserId == user.Id && candidate.LevelId == level.Id);
        Assert.False(attempt.IsSuccessful);
        Assert.Equal(1, attempt.MistakesCount);

        var firstAnswer = await dbContext.UserAnswers.SingleAsync(answer =>
            answer.AttemptId == attempt.Id && answer.ExerciseId == exercises[0].Id);
        Assert.False(firstAnswer.IsCorrect);
        Assert.Equal("definitely wrong", firstAnswer.UserAnswerText);
        Assert.Equal(1000, firstAnswer.TimeSpentMs);

        var progress = await GetProgressAsync(dbContext, user.Id, level.Id);
        Assert.Equal("available", progress.Status);
        Assert.Equal(1, progress.AttemptsCount);
    }

    [Fact]
    public async Task CompleteLevelAsync_NormalizesAnswersCompletesLevelAndUnlocksNextLevel()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithLevelProgressAsync(dbContext, "user@example.com");
        var level = await GetSectionLevelAsync(dbContext, "Food", 1);
        var nextLevel = await GetSectionLevelAsync(dbContext, "Food", 2);
        var exercises = await GetActiveExercisesAsync(dbContext, level.Id);
        exercises[0].CorrectAnswer = "green apple";
        await dbContext.SaveChangesAsync();
        var request = new CompleteLevelRequest
        {
            Answers = exercises
                .Select((exercise, index) => new CompleteLevelAnswerRequest
                {
                    ExerciseId = exercise.Id,
                    UserAnswer = index == 0 ? "  GREEN   APPLE  " : $"  {exercise.CorrectAnswer.ToUpperInvariant()}  ",
                    IsCorrect = false
                })
                .ToList()
        };
        var service = new LearningService(dbContext);

        var result = await service.CompleteLevelAsync(user.Id, level.Id, request);

        Assert.True(result.IsLevelCompleted);
        Assert.Equal(0, result.MistakesCount);
        Assert.Equal(nextLevel.Id, result.OpenedNextLevelId);

        var progress = await GetProgressAsync(dbContext, user.Id, level.Id);
        Assert.Equal("completed", progress.Status);
        Assert.NotNull(progress.CompletedAt);
        Assert.Equal(1, progress.AttemptsCount);

        var nextProgress = await GetProgressAsync(dbContext, user.Id, nextLevel.Id);
        Assert.Equal("available", nextProgress.Status);
        Assert.NotNull(nextProgress.UnlockedAt);
    }

    [Fact]
    public async Task CompleteLevelAsync_UnlocksFinalTestAfterAllNormalLevelsAreCompleted()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithLevelProgressAsync(dbContext, "user@example.com");
        var normalLevels = await GetSectionNormalLevelsAsync(dbContext, "Food");
        var fifthLevel = normalLevels.Single(level => level.LevelNumber == 5);
        var finalTest = await GetSectionLevelAsync(dbContext, "Food", 6);
        await CompleteExistingNormalLevelsBeforeAsync(dbContext, user.Id, normalLevels, fifthLevel.LevelNumber);
        await SetLevelStatusAsync(dbContext, user.Id, fifthLevel.Id, "available");
        var exercise = await AddWordAndExerciseAsync(dbContext, fifthLevel.Id, "final-normal-answer");
        var service = new LearningService(dbContext);

        var result = await service.CompleteLevelAsync(
            user.Id,
            fifthLevel.Id,
            new CompleteLevelRequest
            {
                Answers =
                [
                    new CompleteLevelAnswerRequest
                    {
                        ExerciseId = exercise.Id,
                        UserAnswer = "final-normal-answer"
                    }
                ]
            });

        Assert.True(result.IsLevelCompleted);
        Assert.Equal(finalTest.Id, result.OpenedNextLevelId);

        var finalProgress = await GetProgressAsync(dbContext, user.Id, finalTest.Id);
        Assert.Equal("available", finalProgress.Status);
        Assert.NotNull(finalProgress.UnlockedAt);
    }

    [Fact]
    public async Task CompleteLevelAsync_DoesNotIncreaseStreakMoreThanOncePerServerDate()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithLevelProgressAsync(dbContext, "user@example.com");
        var profile = await dbContext.UserProfiles.SingleAsync(candidate => candidate.UserId == user.Id);
        profile.CurrentStreak = 4;
        profile.BestStreak = 7;
        profile.LastActivityDate = DateOnly.FromDateTime(DateTime.UtcNow);
        await dbContext.SaveChangesAsync();
        var level = await GetSectionLevelAsync(dbContext, "Food", 1);
        var exercises = await GetActiveExercisesAsync(dbContext, level.Id);
        var service = new LearningService(dbContext);

        var result = await service.CompleteLevelAsync(
            user.Id,
            level.Id,
            new CompleteLevelRequest
            {
                Answers = exercises
                    .Select((exercise, index) => new CompleteLevelAnswerRequest
                    {
                        ExerciseId = exercise.Id,
                        UserAnswer = index == 0 ? "wrong" : exercise.CorrectAnswer
                    })
                    .ToList()
            });

        Assert.Equal(4, result.CurrentStreak);
        Assert.Equal(7, result.BestStreak);
    }

    [Fact]
    public async Task CompleteLevelAsync_RejectsAnswersForAnotherLevel()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithLevelProgressAsync(dbContext, "user@example.com");
        var level = await GetSectionLevelAsync(dbContext, "Food", 1);
        var otherLevel = await GetSectionLevelAsync(dbContext, "Food", 2);
        var otherExercise = (await GetActiveExercisesAsync(dbContext, otherLevel.Id))[0];
        var service = new LearningService(dbContext);

        var exception = await Assert.ThrowsAsync<ApiException>(() =>
            service.CompleteLevelAsync(
                user.Id,
                level.Id,
                new CompleteLevelRequest
                {
                    Answers =
                    [
                        new CompleteLevelAnswerRequest
                        {
                            ExerciseId = otherExercise.Id,
                            UserAnswer = otherExercise.CorrectAnswer
                        }
                    ]
                }));

        Assert.Equal(StatusCodes.Status400BadRequest, exception.StatusCode);
        Assert.Equal("validation_error", exception.Code);
        Assert.Equal(["Exercise ids must belong to the level"], exception.Details!["answers"]);
    }

    private static async Task<User> CreateUserWithLevelProgressAsync(AppDbContext dbContext, string email)
    {
        var now = CreateTimestamp();
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = email,
            PasswordHash = "hash",
            CreatedAt = now
        };

        dbContext.Users.Add(user);
        dbContext.UserProfiles.Add(new UserProfile
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Name = "Vladimir",
            AvatarId = 1,
            CreatedAt = now
        });

        var levels = await dbContext.Levels
            .Include(level => level.Section)
            .Where(level => level.IsActive && level.Section.IsActive)
            .ToListAsync();

        dbContext.UserLevelProgresses.AddRange(levels.Select(level =>
        {
            var isFirstNormalLevel = !level.IsFinalTest
                && level.LevelNumber == levels
                    .Where(candidate => candidate.SectionId == level.SectionId && !candidate.IsFinalTest)
                    .Min(candidate => candidate.LevelNumber);

            return new UserLevelProgress
            {
                UserId = user.Id,
                LevelId = level.Id,
                Status = isFirstNormalLevel ? "available" : "locked",
                WordsLearned = false,
                AttemptsCount = 0,
                UnlockedAt = isFirstNormalLevel ? now : null
            };
        }));

        await dbContext.SaveChangesAsync();

        return user;
    }

    private static async Task<List<Exercise>> GetActiveExercisesAsync(AppDbContext dbContext, int levelId) =>
        await dbContext.Exercises
            .Where(exercise => exercise.LevelId == levelId && exercise.IsActive)
            .OrderBy(exercise => exercise.SortOrder)
            .ThenBy(exercise => exercise.Id)
            .ToListAsync();

    private static async Task<UserLevelProgress> GetProgressAsync(
        AppDbContext dbContext,
        Guid userId,
        int levelId) =>
        await dbContext.UserLevelProgresses.SingleAsync(progress =>
            progress.UserId == userId && progress.LevelId == levelId);

    private static async Task<Level> GetSectionLevelAsync(
        AppDbContext dbContext,
        string sectionTitle,
        int levelNumber) =>
        await dbContext.Levels
            .Include(level => level.Section)
            .SingleAsync(level => level.Section.Title == sectionTitle && level.LevelNumber == levelNumber);

    private static async Task<List<Level>> GetSectionNormalLevelsAsync(
        AppDbContext dbContext,
        string sectionTitle) =>
        await dbContext.Levels
            .Include(level => level.Section)
            .Where(level => level.Section.Title == sectionTitle && !level.IsFinalTest)
            .OrderBy(level => level.SortOrder)
            .ToListAsync();

    private static async Task SetLevelStatusAsync(
        AppDbContext dbContext,
        Guid userId,
        int levelId,
        string status)
    {
        var progress = await GetProgressAsync(dbContext, userId, levelId);
        progress.Status = status;
        progress.UnlockedAt ??= CreateTimestamp();
        await dbContext.SaveChangesAsync();
    }

    private static async Task CompleteExistingNormalLevelsBeforeAsync(
        AppDbContext dbContext,
        Guid userId,
        List<Level> normalLevels,
        int levelNumber)
    {
        foreach (var level in normalLevels.Where(level => level.LevelNumber < levelNumber))
        {
            var progress = await GetProgressAsync(dbContext, userId, level.Id);
            progress.Status = "completed";
            progress.CompletedAt = CreateTimestamp();
        }

        await dbContext.SaveChangesAsync();
    }

    private static async Task<Exercise> AddWordAndExerciseAsync(
        AppDbContext dbContext,
        int levelId,
        string correctAnswer)
    {
        var now = CreateTimestamp();
        var word = new Word
        {
            LevelId = levelId,
            English = correctAnswer,
            Russian = correctAnswer,
            CefrLevel = "A1",
            IsActive = true,
            CreatedAt = now
        };

        dbContext.Words.Add(word);
        await dbContext.SaveChangesAsync();

        var exercise = new Exercise
        {
            LevelId = levelId,
            WordId = word.Id,
            Type = "russian_to_english_input",
            QuestionText = correctAnswer,
            CorrectAnswer = correctAnswer,
            IsActive = true,
            CreatedAt = now
        };

        dbContext.Exercises.Add(exercise);
        await dbContext.SaveChangesAsync();

        return exercise;
    }

    private static async Task<AppDbContext> CreateSeededDbContextAsync()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        var dbContext = new AppDbContext(options);
        await DatabaseSeeder.SeedAsync(dbContext);

        return dbContext;
    }

    private static DateTime CreateTimestamp() =>
        DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
}
