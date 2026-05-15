using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Swirl.Api.Data;
using Swirl.Api.Models;
using Swirl.Api.Requests;
using Swirl.Api.Services;

namespace Swirl.Api.Tests;

public class DailyTestServiceTests
{
    [Fact]
    public async Task GetDailyTestAsync_ReturnsUnavailableWhenUserHasFewerThanFiveLearnedWords()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithProfileAsync(dbContext, "user@example.com");
        await AddLearnedWordsAsync(dbContext, user.Id, count: 4);
        var service = CreateService(dbContext);

        var result = await service.GetDailyTestAsync(user.Id);

        Assert.False(result.IsAvailable);
        Assert.Equal("Not enough learned words", result.Reason);
        Assert.Null(result.ExercisesCount);
        Assert.Null(result.Exercises);
    }

    [Fact]
    public async Task GetDailyTestAsync_ReturnsExercisesFromCurrentUsersLearnedWords()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithProfileAsync(dbContext, "user@example.com");
        var otherUser = await CreateUserWithProfileAsync(dbContext, "other@example.com");
        var userWordIds = await AddLearnedWordsAsync(dbContext, user.Id, count: 6);
        await AddLearnedWordsAsync(dbContext, otherUser.Id, count: 6, skip: 6);
        var service = CreateService(dbContext);

        var result = await service.GetDailyTestAsync(user.Id);

        Assert.True(result.IsAvailable);
        Assert.Equal(6, result.ExercisesCount);
        Assert.NotNull(result.Exercises);
        Assert.All(result.Exercises, exercise =>
        {
            Assert.Contains(exercise.WordId, userWordIds);
            Assert.NotEmpty(exercise.Type);
            Assert.NotEmpty(exercise.CorrectAnswer);
            Assert.NotNull(exercise.Options);
        });
    }

    [Fact]
    public async Task GetDailyTestAsync_LimitsExercisesToThirtyLearnedWords()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithProfileAsync(dbContext, "user@example.com");
        await AddLearnedWordsAsync(dbContext, user.Id, count: 40);
        var service = CreateService(dbContext);

        var result = await service.GetDailyTestAsync(user.Id);

        Assert.True(result.IsAvailable);
        Assert.Equal(30, result.ExercisesCount);
        Assert.Equal(30, result.Exercises!.Count);
    }

    [Fact]
    public async Task GetDailyTestAsync_CreatesShuffledChoiceOptionsWithCorrectAnswer()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithProfileAsync(dbContext, "user@example.com");
        await AddLearnedWordsAsync(dbContext, user.Id, count: 10);
        var service = CreateService(dbContext);

        var result = await service.GetDailyTestAsync(user.Id);

        var choiceExercise = result.Exercises!
            .First(exercise => exercise.Type == "english_to_russian_choice");
        Assert.Equal(4, choiceExercise.Options.Count);
        Assert.Equal(4, choiceExercise.Options.Distinct().Count());
        Assert.Contains(choiceExercise.CorrectAnswer, choiceExercise.Options);
    }

    [Fact]
    public async Task CompleteDailyTestAsync_SavesResultAndAnswers()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithProfileAsync(dbContext, "user@example.com");
        var learnedWordIds = await AddLearnedWordsAsync(dbContext, user.Id, count: 5);
        var word = await dbContext.Words.SingleAsync(candidate => candidate.Id == learnedWordIds[0]);
        var service = CreateService(dbContext);

        var result = await service.CompleteDailyTestAsync(user.Id, new CompleteDailyTestRequest
        {
            Answers =
            [
                new()
                {
                    WordId = word.Id,
                    ExerciseType = "russian_to_english_input",
                    UserAnswer = word.English,
                    IsCorrect = false
                }
            ]
        });

        Assert.True(result.Completed);
        Assert.Equal(1, result.CorrectAnswers);
        Assert.Equal(1, result.TotalAnswers);
        Assert.Equal(1, result.CurrentStreak);
        Assert.Equal(1, result.BestStreak);

        var dailyTest = await dbContext.DailyTests.SingleAsync(candidate => candidate.UserId == user.Id);
        Assert.True(dailyTest.IsCompleted);
        Assert.Equal(1, dailyTest.TotalQuestions);
        Assert.Equal(1, dailyTest.CorrectAnswers);
        Assert.NotNull(dailyTest.CompletedAt);

        var answer = await dbContext.DailyTestAnswers.SingleAsync(candidate => candidate.DailyTestId == dailyTest.Id);
        Assert.Equal(word.Id, answer.WordId);
        Assert.True(answer.IsCorrect);
    }

    [Fact]
    public async Task CompleteDailyTestAsync_RecalculatesCorrectnessAndNormalizesAnswers()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithProfileAsync(dbContext, "user@example.com");
        var learnedWordIds = await AddLearnedWordsAsync(dbContext, user.Id, count: 5);
        var correctWord = await dbContext.Words.SingleAsync(candidate => candidate.Id == learnedWordIds[0]);
        var wrongWord = await dbContext.Words.SingleAsync(candidate => candidate.Id == learnedWordIds[1]);
        var service = CreateService(dbContext);

        var result = await service.CompleteDailyTestAsync(user.Id, new CompleteDailyTestRequest
        {
            Answers =
            [
                new()
                {
                    WordId = correctWord.Id,
                    ExerciseType = "russian_to_english_input",
                    UserAnswer = $"  {correctWord.English.ToUpperInvariant()}  ",
                    IsCorrect = false
                },
                new()
                {
                    WordId = wrongWord.Id,
                    ExerciseType = "russian_to_english_input",
                    UserAnswer = "not the answer",
                    IsCorrect = true
                }
            ]
        });

        Assert.Equal(1, result.CorrectAnswers);
        Assert.Equal(2, result.TotalAnswers);

        var savedAnswers = await dbContext.DailyTestAnswers
            .OrderBy(answer => answer.Id)
            .ToListAsync();
        Assert.True(savedAnswers[0].IsCorrect);
        Assert.False(savedAnswers[1].IsCorrect);
    }

    [Fact]
    public async Task CompleteDailyTestAsync_RejectsSecondCompletedTestForSameDate()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithProfileAsync(dbContext, "user@example.com");
        var learnedWordIds = await AddLearnedWordsAsync(dbContext, user.Id, count: 5);
        var word = await dbContext.Words.SingleAsync(candidate => candidate.Id == learnedWordIds[0]);
        var service = CreateService(dbContext);
        var request = new CompleteDailyTestRequest
        {
            Answers =
            [
                new()
                {
                    WordId = word.Id,
                    ExerciseType = "russian_to_english_input",
                    UserAnswer = word.English,
                    IsCorrect = true
                }
            ]
        };
        await service.CompleteDailyTestAsync(user.Id, request);

        var exception = await Assert.ThrowsAsync<ApiException>(() =>
            service.CompleteDailyTestAsync(user.Id, request));

        Assert.Equal(StatusCodes.Status409Conflict, exception.StatusCode);
        Assert.Equal("daily_test_already_completed", exception.Code);
    }

    [Fact]
    public async Task CompleteDailyTestAsync_RejectsWordsThatAreNotLearnedByCurrentUser()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var user = await CreateUserWithProfileAsync(dbContext, "user@example.com");
        var otherUser = await CreateUserWithProfileAsync(dbContext, "other@example.com");
        await AddLearnedWordsAsync(dbContext, user.Id, count: 5);
        var otherUserWordIds = await AddLearnedWordsAsync(dbContext, otherUser.Id, count: 5, skip: 5);
        var service = CreateService(dbContext);

        var exception = await Assert.ThrowsAsync<ApiException>(() =>
            service.CompleteDailyTestAsync(user.Id, new CompleteDailyTestRequest
            {
                Answers =
                [
                    new()
                    {
                        WordId = otherUserWordIds[0],
                        ExerciseType = "russian_to_english_input",
                        UserAnswer = "answer",
                        IsCorrect = true
                    }
                ]
            }));

        Assert.Equal(StatusCodes.Status400BadRequest, exception.StatusCode);
        Assert.Equal("validation_error", exception.Code);
        Assert.Equal(["Word ids must belong to learned words"], exception.Details!["answers"]);
    }

    private static DailyTestService CreateService(AppDbContext dbContext) =>
        new(dbContext, new StreakService(dbContext));

    private static async Task<List<int>> AddLearnedWordsAsync(
        AppDbContext dbContext,
        Guid userId,
        int count,
        int skip = 0)
    {
        var now = CreateTimestamp();
        var wordIds = await dbContext.Words
            .Where(word => word.IsActive && word.Level.IsActive && word.Level.Section.IsActive)
            .OrderBy(word => word.Id)
            .Skip(skip)
            .Take(count)
            .Select(word => word.Id)
            .ToListAsync();

        dbContext.UserWordProgresses.AddRange(wordIds.Select(wordId => new UserWordProgress
        {
            UserId = userId,
            WordId = wordId,
            LearnedAt = now
        }));
        await dbContext.SaveChangesAsync();

        return wordIds;
    }

    private static async Task<User> CreateUserWithProfileAsync(AppDbContext dbContext, string email)
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
        await dbContext.SaveChangesAsync();

        return user;
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
