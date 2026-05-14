using Microsoft.EntityFrameworkCore;
using Swirl.Api.Data;

namespace Swirl.Api.Tests;

public class DatabaseSeederTests
{
    private static readonly string[] ChoiceExerciseTypes =
    [
        "english_to_russian_choice",
        "russian_to_english_choice",
        "audio_to_russian_choice"
    ];

    [Fact]
    public async Task SeedAsync_CreatesStage5LearningContent()
    {
        await using var dbContext = await CreateSeededDbContextAsync();

        Assert.Equal(40, await dbContext.Words.CountAsync(word => word.IsActive));
        Assert.Equal(72, await dbContext.Exercises.CountAsync(exercise => exercise.IsActive));
        Assert.Equal(144, await dbContext.ExerciseOptions.CountAsync());

        var finalTestWordCounts = await dbContext.Levels
            .Where(level => level.IsFinalTest)
            .Select(level => level.Words.Count)
            .ToArrayAsync();

        Assert.Equal(4, finalTestWordCounts.Length);
        Assert.All(finalTestWordCounts, count => Assert.Equal(0, count));
    }

    [Fact]
    public async Task SeedAsync_IsIdempotentForStage5LearningContent()
    {
        await using var dbContext = await CreateSeededDbContextAsync();

        await DatabaseSeeder.SeedAsync(dbContext);

        Assert.Equal(40, await dbContext.Words.CountAsync(word => word.IsActive));
        Assert.Equal(72, await dbContext.Exercises.CountAsync(exercise => exercise.IsActive));
        Assert.Equal(144, await dbContext.ExerciseOptions.CountAsync());
    }

    [Fact]
    public async Task SeedAsync_CreatesValidChoiceOptions()
    {
        await using var dbContext = await CreateSeededDbContextAsync();

        var choiceExercises = await dbContext.Exercises
            .Include(exercise => exercise.ExerciseOptions)
            .Where(exercise => ChoiceExerciseTypes.Contains(exercise.Type))
            .ToListAsync();

        Assert.Equal(36, choiceExercises.Count);
        Assert.All(choiceExercises, exercise =>
        {
            Assert.Equal(4, exercise.ExerciseOptions.Count);
            Assert.Equal(1, exercise.ExerciseOptions.Count(option => option.IsCorrect));
        });
    }

    [Fact]
    public async Task SeedAsync_LinksFinalTestExercisesToSectionWords()
    {
        await using var dbContext = await CreateSeededDbContextAsync();
        var finalTests = await dbContext.Levels
            .Include(level => level.Section)
            .Where(level => level.IsFinalTest)
            .ToListAsync();

        foreach (var finalTest in finalTests)
        {
            var sectionNormalWordIds = await dbContext.Words
                .Where(word =>
                    word.Level.SectionId == finalTest.SectionId &&
                    !word.Level.IsFinalTest)
                .Select(word => word.Id)
                .ToArrayAsync();

            var finalTestExercises = await dbContext.Exercises
                .Where(exercise => exercise.LevelId == finalTest.Id)
                .ToListAsync();

            Assert.Equal(6, finalTestExercises.Count);
            Assert.All(finalTestExercises, exercise => Assert.Contains(exercise.WordId, sectionNormalWordIds));
        }
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
}
