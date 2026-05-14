using Microsoft.EntityFrameworkCore;
using Swirl.Api.Models;

namespace Swirl.Api.Data;

public static class DatabaseSeeder
{
    private const string DefaultCefrLevel = "A1";
    private const int NormalLevelsPerSection = 5;
    private const int FinalTestLevelNumber = NormalLevelsPerSection + 1;
    private const int SeededNormalLevelsPerSection = 2;

    private static readonly string[] ExerciseTypes =
    [
        "picture_to_english_input",
        "english_to_russian_choice",
        "russian_to_english_choice",
        "russian_to_english_input",
        "english_to_russian_input",
        "audio_to_russian_choice"
    ];

    private static readonly string[] ChoiceExerciseTypes =
    [
        "english_to_russian_choice",
        "russian_to_english_choice",
        "audio_to_russian_choice"
    ];

    public static async Task SeedAsync(AppDbContext dbContext, CancellationToken cancellationToken = default)
    {
        var now = CreateTimestamp();

        await SeedAvatarsAsync(dbContext, cancellationToken);
        await SeedSectionsAsync(dbContext, now, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        await SeedLevelsAsync(dbContext, now, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        await SeedWordsAsync(dbContext, now, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        await SeedExercisesAsync(dbContext, now, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        await SeedExerciseOptionsAsync(dbContext, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static async Task SeedAvatarsAsync(AppDbContext dbContext, CancellationToken cancellationToken)
    {
        var avatars = new[]
        {
            new AvatarSeed("Avatar 1", "/media/avatars/avatar_1.png"),
            new AvatarSeed("Avatar 2", "/media/avatars/avatar_2.png"),
            new AvatarSeed("Avatar 3", "/media/avatars/avatar_3.png"),
            new AvatarSeed("Avatar 4", "/media/avatars/avatar_4.png")
        };
        var avatarImageUrls = avatars.Select(avatar => avatar.ImageUrl).ToArray();

        var existingAvatars = await dbContext.Avatars
            .Where(avatar => avatarImageUrls.Contains(avatar.ImageUrl))
            .ToDictionaryAsync(avatar => avatar.ImageUrl, cancellationToken);

        foreach (var avatarSeed in avatars)
        {
            if (existingAvatars.TryGetValue(avatarSeed.ImageUrl, out var existingAvatar))
            {
                existingAvatar.Name = avatarSeed.Name;
                existingAvatar.IsActive = true;
                continue;
            }

            dbContext.Avatars.Add(new Avatar
            {
                Name = avatarSeed.Name,
                ImageUrl = avatarSeed.ImageUrl,
                IsActive = true
            });
        }
    }

    private static async Task SeedSectionsAsync(
        AppDbContext dbContext,
        DateTime now,
        CancellationToken cancellationToken)
    {
        var sections = GetSectionSeeds();
        var sectionTitles = sections.Select(section => section.Title).ToArray();

        var existingSections = await dbContext.Sections
            .Where(section => sectionTitles.Contains(section.Title))
            .ToDictionaryAsync(section => section.Title, cancellationToken);

        foreach (var sectionSeed in sections)
        {
            if (existingSections.TryGetValue(sectionSeed.Title, out var existingSection))
            {
                existingSection.Description = sectionSeed.Description;
                existingSection.ImageUrl = sectionSeed.ImageUrl;
                existingSection.SortOrder = sectionSeed.SortOrder;
                existingSection.IsActive = true;
                existingSection.UpdatedAt = now;
                continue;
            }

            dbContext.Sections.Add(new Section
            {
                Title = sectionSeed.Title,
                Description = sectionSeed.Description,
                ImageUrl = sectionSeed.ImageUrl,
                SortOrder = sectionSeed.SortOrder,
                IsActive = true,
                CreatedAt = now
            });
        }
    }

    private static async Task SeedLevelsAsync(
        AppDbContext dbContext,
        DateTime now,
        CancellationToken cancellationToken)
    {
        var sectionTitles = GetSectionSeeds()
            .Select(section => section.Title)
            .ToArray();

        var sections = await dbContext.Sections
            .Where(section => sectionTitles.Contains(section.Title))
            .ToListAsync(cancellationToken);

        foreach (var section in sections)
        {
            var existingLevels = await dbContext.Levels
                .Where(level => level.SectionId == section.Id)
                .ToDictionaryAsync(level => level.LevelNumber, cancellationToken);

            for (var levelNumber = 1; levelNumber <= FinalTestLevelNumber; levelNumber++)
            {
                var isFinalTest = levelNumber == FinalTestLevelNumber;
                var title = isFinalTest
                    ? $"{section.Title} Final Test"
                    : $"{section.Title} Level {levelNumber}";

                var description = isFinalTest
                    ? $"Final test for {section.Title} section"
                    : $"Level {levelNumber} for {section.Title} section";

                if (existingLevels.TryGetValue(levelNumber, out var existingLevel))
                {
                    existingLevel.Title = title;
                    existingLevel.Description = description;
                    existingLevel.CefrLevel = DefaultCefrLevel;
                    existingLevel.IsFinalTest = isFinalTest;
                    existingLevel.SortOrder = levelNumber;
                    existingLevel.IsActive = true;
                    existingLevel.UpdatedAt = now;
                    continue;
                }

                dbContext.Levels.Add(new Level
                {
                    SectionId = section.Id,
                    Title = title,
                    Description = description,
                    LevelNumber = levelNumber,
                    CefrLevel = DefaultCefrLevel,
                    IsFinalTest = isFinalTest,
                    SortOrder = levelNumber,
                    IsActive = true,
                    CreatedAt = now
                });
            }
        }
    }

    private static async Task SeedWordsAsync(
        AppDbContext dbContext,
        DateTime now,
        CancellationToken cancellationToken)
    {
        var wordSeeds = GetWordSeeds();
        var sectionTitles = wordSeeds
            .Select(word => word.SectionTitle)
            .Distinct()
            .ToArray();

        var levels = await dbContext.Levels
            .Include(level => level.Section)
            .Where(level =>
                sectionTitles.Contains(level.Section.Title) &&
                level.LevelNumber <= SeededNormalLevelsPerSection &&
                !level.IsFinalTest)
            .ToListAsync(cancellationToken);

        var existingWords = await dbContext.Words
            .Include(word => word.Level)
            .ThenInclude(level => level.Section)
            .Where(word =>
                sectionTitles.Contains(word.Level.Section.Title) &&
                word.Level.LevelNumber <= SeededNormalLevelsPerSection)
            .ToDictionaryAsync(word => CreateWordKey(
                word.Level.Section.Title,
                word.Level.LevelNumber,
                word.English), cancellationToken);

        foreach (var wordSeed in wordSeeds)
        {
            var level = levels.Single(level =>
                level.Section.Title == wordSeed.SectionTitle &&
                level.LevelNumber == wordSeed.LevelNumber);

            var wordKey = CreateWordKey(wordSeed.SectionTitle, wordSeed.LevelNumber, wordSeed.English);
            if (existingWords.TryGetValue(wordKey, out var existingWord))
            {
                existingWord.Russian = wordSeed.Russian;
                existingWord.Transcription = wordSeed.Transcription;
                existingWord.PartOfSpeech = wordSeed.PartOfSpeech;
                existingWord.ImageUrl = wordSeed.ImageUrl;
                existingWord.AudioUrl = wordSeed.AudioUrl;
                existingWord.CefrLevel = DefaultCefrLevel;
                existingWord.IsActive = true;
                existingWord.UpdatedAt = now;
                continue;
            }

            dbContext.Words.Add(new Word
            {
                LevelId = level.Id,
                English = wordSeed.English,
                Russian = wordSeed.Russian,
                Transcription = wordSeed.Transcription,
                PartOfSpeech = wordSeed.PartOfSpeech,
                ImageUrl = wordSeed.ImageUrl,
                AudioUrl = wordSeed.AudioUrl,
                CefrLevel = DefaultCefrLevel,
                IsActive = true,
                CreatedAt = now
            });
        }
    }

    private static async Task SeedExercisesAsync(
        AppDbContext dbContext,
        DateTime now,
        CancellationToken cancellationToken)
    {
        var exerciseSeeds = await CreateExerciseSeedsAsync(dbContext, cancellationToken);
        var seededLevelIds = exerciseSeeds
            .Select(exercise => exercise.LevelId)
            .Distinct()
            .ToArray();

        var existingExercises = await dbContext.Exercises
            .Where(exercise => seededLevelIds.Contains(exercise.LevelId))
            .ToDictionaryAsync(
                exercise => CreateExerciseKey(exercise.LevelId, exercise.SortOrder),
                cancellationToken);

        foreach (var exerciseSeed in exerciseSeeds)
        {
            var exerciseKey = CreateExerciseKey(exerciseSeed.LevelId, exerciseSeed.SortOrder);
            if (existingExercises.TryGetValue(exerciseKey, out var existingExercise))
            {
                existingExercise.WordId = exerciseSeed.WordId;
                existingExercise.Type = exerciseSeed.Type;
                existingExercise.QuestionText = exerciseSeed.QuestionText;
                existingExercise.CorrectAnswer = exerciseSeed.CorrectAnswer;
                existingExercise.IsActive = true;
                existingExercise.UpdatedAt = now;
                continue;
            }

            dbContext.Exercises.Add(new Exercise
            {
                LevelId = exerciseSeed.LevelId,
                WordId = exerciseSeed.WordId,
                Type = exerciseSeed.Type,
                QuestionText = exerciseSeed.QuestionText,
                CorrectAnswer = exerciseSeed.CorrectAnswer,
                SortOrder = exerciseSeed.SortOrder,
                IsActive = true,
                CreatedAt = now
            });
        }
    }

    private static async Task SeedExerciseOptionsAsync(
        AppDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var choiceExercises = await dbContext.Exercises
            .Include(exercise => exercise.Word)
            .ThenInclude(word => word.Level)
            .ThenInclude(level => level.Section)
            .Include(exercise => exercise.ExerciseOptions)
            .Where(exercise => ChoiceExerciseTypes.Contains(exercise.Type))
            .ToListAsync(cancellationToken);

        var sectionIds = choiceExercises
            .Select(exercise => exercise.Word.Level.SectionId)
            .Distinct()
            .ToArray();

        var sectionWords = await dbContext.Words
            .Include(word => word.Level)
            .Where(word => sectionIds.Contains(word.Level.SectionId) && !word.Level.IsFinalTest)
            .ToListAsync(cancellationToken);

        foreach (var exercise in choiceExercises)
        {
            var optionTexts = CreateOptionTexts(exercise, sectionWords);
            var existingOptions = exercise.ExerciseOptions
                .Where(option => option.SortOrder.HasValue)
                .GroupBy(option => option.SortOrder)
                .ToDictionary(group => group.Key!.Value, group => group.First());

            foreach (var extraOption in exercise.ExerciseOptions.Where(option =>
                option.SortOrder is null or < 1 or > 4))
            {
                dbContext.ExerciseOptions.Remove(extraOption);
            }

            for (var index = 0; index < optionTexts.Length; index++)
            {
                var sortOrder = index + 1;
                var optionText = optionTexts[index];
                var isCorrect = sortOrder == 1;

                if (existingOptions.TryGetValue(sortOrder, out var existingOption))
                {
                    existingOption.OptionText = optionText;
                    existingOption.IsCorrect = isCorrect;
                    continue;
                }

                dbContext.ExerciseOptions.Add(new ExerciseOption
                {
                    ExerciseId = exercise.Id,
                    OptionText = optionText,
                    IsCorrect = isCorrect,
                    SortOrder = sortOrder
                });
            }
        }
    }

    private static async Task<List<ExerciseSeed>> CreateExerciseSeedsAsync(
        AppDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var sectionTitles = GetSectionSeeds()
            .Select(section => section.Title)
            .ToArray();

        var levels = await dbContext.Levels
            .Include(level => level.Section)
            .Where(level => sectionTitles.Contains(level.Section.Title))
            .ToListAsync(cancellationToken);

        var words = await dbContext.Words
            .Include(word => word.Level)
            .ThenInclude(level => level.Section)
            .Where(word => sectionTitles.Contains(word.Level.Section.Title))
            .ToListAsync(cancellationToken);

        var exerciseSeeds = new List<ExerciseSeed>();

        foreach (var section in GetSectionSeeds())
        {
            var normalLevels = levels
                .Where(level =>
                    level.Section.Title == section.Title &&
                    level.LevelNumber <= SeededNormalLevelsPerSection &&
                    !level.IsFinalTest)
                .OrderBy(level => level.LevelNumber)
                .ToArray();

            foreach (var level in normalLevels)
            {
                var levelWords = words
                    .Where(word => word.LevelId == level.Id)
                    .OrderBy(word => word.Id)
                    .ToArray();

                exerciseSeeds.AddRange(CreateExercisesForLevel(level.Id, levelWords));
            }

            var finalTestLevel = levels.Single(level =>
                level.Section.Title == section.Title &&
                level.IsFinalTest);

            var sectionWords = words
                .Where(word =>
                    word.Level.Section.Title == section.Title &&
                    !word.Level.IsFinalTest)
                .OrderBy(word => word.Level.LevelNumber)
                .ThenBy(word => word.Id)
                .Take(ExerciseTypes.Length)
                .ToArray();

            exerciseSeeds.AddRange(CreateExercisesForLevel(finalTestLevel.Id, sectionWords));
        }

        return exerciseSeeds;
    }

    private static ExerciseSeed[] CreateExercisesForLevel(int levelId, Word[] words)
    {
        if (words.Length < ExerciseTypes.Length)
        {
            words = [.. words, words[0]];
        }

        return ExerciseTypes
            .Select((type, index) =>
            {
                var word = words[index % words.Length];
                return new ExerciseSeed(
                    levelId,
                    word.Id,
                    type,
                    CreateQuestionText(type, word),
                    CreateCorrectAnswer(type, word),
                    index + 1);
            })
            .ToArray();
    }

    private static string? CreateQuestionText(string type, Word word) =>
        type switch
        {
            "picture_to_english_input" => null,
            "english_to_russian_choice" => word.English,
            "russian_to_english_choice" => word.Russian,
            "russian_to_english_input" => word.Russian,
            "english_to_russian_input" => word.English,
            "audio_to_russian_choice" => null,
            _ => word.English
        };

    private static string CreateCorrectAnswer(string type, Word word) =>
        type switch
        {
            "english_to_russian_choice" => word.Russian,
            "english_to_russian_input" => word.Russian,
            "audio_to_russian_choice" => word.Russian,
            _ => word.English
        };

    private static string[] CreateOptionTexts(Exercise exercise, List<Word> sectionWords)
    {
        var usesRussianOptions = exercise.Type is "english_to_russian_choice" or "audio_to_russian_choice";
        var incorrectOptions = sectionWords
            .Where(word => word.Level.SectionId == exercise.Word.Level.SectionId && word.Id != exercise.WordId)
            .OrderBy(word => word.Id)
            .Select(word => usesRussianOptions ? word.Russian : word.English)
            .Distinct()
            .Take(3)
            .ToArray();

        return [exercise.CorrectAnswer, .. incorrectOptions];
    }

    private static SectionSeed[] GetSectionSeeds() =>
    [
        new("Food", "Words about food and drinks", "/media/images/sections/food.png", 1),
        new("Science", "Words about science and discovery", "/media/images/sections/science.png", 2),
        new("Health", "Words about health and wellbeing", "/media/images/sections/health.png", 3),
        new("Wardrobe", "Words about clothes and wardrobe", "/media/images/sections/wardrobe.png", 4)
    ];

    private static WordSeed[] GetWordSeeds() =>
    [
        new("Food", 1, "apple", "яблоко", "[ap-l]", "noun"),
        new("Food", 1, "bread", "хлеб", "[bred]", "noun"),
        new("Food", 1, "milk", "молоко", "[milk]", "noun"),
        new("Food", 1, "water", "вода", "[wo-ter]", "noun"),
        new("Food", 1, "cheese", "сыр", "[cheez]", "noun"),
        new("Food", 2, "egg", "яйцо", "[eg]", "noun"),
        new("Food", 2, "rice", "рис", "[rais]", "noun"),
        new("Food", 2, "soup", "суп", "[soop]", "noun"),
        new("Food", 2, "tea", "чай", "[tee]", "noun"),
        new("Food", 2, "meat", "мясо", "[meet]", "noun"),

        new("Science", 1, "sun", "солнце", "[sun]", "noun"),
        new("Science", 1, "moon", "луна", "[moon]", "noun"),
        new("Science", 1, "star", "звезда", "[star]", "noun"),
        new("Science", 1, "planet", "планета", "[plan-it]", "noun"),
        new("Science", 1, "light", "свет", "[lait]", "noun"),
        new("Science", 2, "atom", "атом", "[at-um]", "noun"),
        new("Science", 2, "cell", "клетка", "[sel]", "noun"),
        new("Science", 2, "energy", "энергия", "[en-er-jee]", "noun"),
        new("Science", 2, "force", "сила", "[fors]", "noun"),
        new("Science", 2, "metal", "металл", "[met-l]", "noun"),

        new("Health", 1, "doctor", "врач", "[dok-ter]", "noun"),
        new("Health", 1, "nurse", "медсестра", "[nurs]", "noun"),
        new("Health", 1, "hospital", "больница", "[hos-pi-tl]", "noun"),
        new("Health", 1, "medicine", "лекарство", "[med-i-sin]", "noun"),
        new("Health", 1, "pain", "боль", "[pain]", "noun"),
        new("Health", 2, "tooth", "зуб", "[tooth]", "noun"),
        new("Health", 2, "heart", "сердце", "[hart]", "noun"),
        new("Health", 2, "sleep", "сон", "[sleep]", "noun"),
        new("Health", 2, "fever", "температура", "[fee-ver]", "noun"),
        new("Health", 2, "cough", "кашель", "[kof]", "noun"),

        new("Wardrobe", 1, "shirt", "рубашка", "[shurt]", "noun"),
        new("Wardrobe", 1, "dress", "платье", "[dres]", "noun"),
        new("Wardrobe", 1, "shoes", "обувь", "[shooz]", "noun"),
        new("Wardrobe", 1, "coat", "пальто", "[koht]", "noun"),
        new("Wardrobe", 1, "hat", "шляпа", "[hat]", "noun"),
        new("Wardrobe", 2, "socks", "носки", "[soks]", "noun"),
        new("Wardrobe", 2, "skirt", "юбка", "[skurt]", "noun"),
        new("Wardrobe", 2, "jacket", "куртка", "[jak-it]", "noun"),
        new("Wardrobe", 2, "trousers", "брюки", "[trau-zers]", "noun"),
        new("Wardrobe", 2, "scarf", "шарф", "[skarf]", "noun")
    ];

    private static string CreateWordKey(string sectionTitle, int levelNumber, string english) =>
        $"{sectionTitle}|{levelNumber}|{english}".ToLowerInvariant();

    private static string CreateExerciseKey(int levelId, int? sortOrder) =>
        $"{levelId}|{sortOrder}";

    private static DateTime CreateTimestamp() =>
        DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);

    private sealed record AvatarSeed(string Name, string ImageUrl);

    private sealed record SectionSeed(string Title, string Description, string ImageUrl, int SortOrder);

    private sealed record WordSeed(
        string SectionTitle,
        int LevelNumber,
        string English,
        string Russian,
        string Transcription,
        string PartOfSpeech)
    {
        public string ImageUrl => $"/media/images/words/{English}.png";

        public string AudioUrl => $"/media/audio/words/{English}.mp3";
    }

    private sealed record ExerciseSeed(
        int LevelId,
        int WordId,
        string Type,
        string? QuestionText,
        string CorrectAnswer,
        int SortOrder);
}
