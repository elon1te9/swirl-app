using Microsoft.EntityFrameworkCore;
using Swirl.Api.Models;

namespace Swirl.Api.Data;

public static class DatabaseSeeder
{
    private const int NormalLevelsPerSection = 5;
    private const int FinalTestLevelNumber = NormalLevelsPerSection + 1;
    private const int NormalLevelExerciseCount = 20;
    private const int FinalTestExerciseCount = 30;

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
            new AvatarSeed("Avatar 3", "/media/avatars/avatar_3.png")
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
                    ? $"Final test for {section.Title} words from levels 1-5"
                    : GetLevelDescription(section.Title, levelNumber);
                var cefrLevel = GetLevelCefrLevel(levelNumber);

                if (existingLevels.TryGetValue(levelNumber, out var existingLevel))
                {
                    existingLevel.Title = title;
                    existingLevel.Description = description;
                    existingLevel.CefrLevel = cefrLevel;
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
                    CefrLevel = cefrLevel,
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
                sectionTitles.Contains(level.Section.Title)
                && level.LevelNumber <= NormalLevelsPerSection
                && !level.IsFinalTest)
            .ToListAsync(cancellationToken);

        var existingWords = await dbContext.Words
            .Include(word => word.Level)
            .ThenInclude(level => level.Section)
            .Where(word =>
                sectionTitles.Contains(word.Level.Section.Title)
                && word.Level.LevelNumber <= NormalLevelsPerSection)
            .ToDictionaryAsync(word => CreateWordKey(
                word.Level.Section.Title,
                word.Level.LevelNumber,
                word.English), cancellationToken);
        var seededWordKeys = wordSeeds
            .Select(word => CreateWordKey(word.SectionTitle, word.LevelNumber, word.English))
            .ToHashSet();

        foreach (var existingWord in existingWords)
        {
            if (seededWordKeys.Contains(existingWord.Key))
            {
                continue;
            }

            dbContext.Words.Remove(existingWord.Value);
        }

        foreach (var wordSeed in wordSeeds)
        {
            var level = levels.Single(level =>
                level.Section.Title == wordSeed.SectionTitle
                && level.LevelNumber == wordSeed.LevelNumber);
            var wordKey = CreateWordKey(wordSeed.SectionTitle, wordSeed.LevelNumber, wordSeed.English);

            if (existingWords.TryGetValue(wordKey, out var existingWord))
            {
                existingWord.Russian = wordSeed.Russian;
                existingWord.Transcription = wordSeed.Transcription;
                existingWord.PartOfSpeech = wordSeed.PartOfSpeech;
                existingWord.ImageUrl = wordSeed.ImageUrl;
                existingWord.AudioUrl = wordSeed.AudioUrl;
                existingWord.CefrLevel = wordSeed.CefrLevel;
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
                CefrLevel = wordSeed.CefrLevel,
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
            .Where(exercise => seededLevelIds.Contains(exercise.LevelId) && exercise.SortOrder.HasValue)
            .ToDictionaryAsync(
                exercise => CreateExerciseKey(exercise.LevelId, exercise.SortOrder!.Value),
                cancellationToken);
        var seededExerciseKeys = exerciseSeeds
            .Select(exercise => CreateExerciseKey(exercise.LevelId, exercise.SortOrder))
            .ToHashSet();

        foreach (var existingExercise in existingExercises)
        {
            if (seededExerciseKeys.Contains(existingExercise.Key))
            {
                continue;
            }

            dbContext.Exercises.Remove(existingExercise.Value);
        }

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
            var optionsToRemove = exercise.ExerciseOptions
                .Where(option =>
                    option.SortOrder is null or < 1 or > 4
                    || option.SortOrder > optionTexts.Length)
                .ToList();

            dbContext.ExerciseOptions.RemoveRange(optionsToRemove);

            var existingOptions = exercise.ExerciseOptions
                .Except(optionsToRemove)
                .Where(option => option.SortOrder.HasValue)
                .GroupBy(option => option.SortOrder!.Value)
                .ToDictionary(group => group.Key, group => group.First());

            foreach (var duplicateOption in exercise.ExerciseOptions
                .Except(optionsToRemove)
                .Where(option => option.SortOrder.HasValue)
                .GroupBy(option => option.SortOrder!.Value)
                .SelectMany(group => group.Skip(1)))
            {
                dbContext.ExerciseOptions.Remove(duplicateOption);
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
                    level.Section.Title == section.Title
                    && level.LevelNumber <= NormalLevelsPerSection
                    && !level.IsFinalTest)
                .OrderBy(level => level.LevelNumber)
                .ToArray();

            foreach (var level in normalLevels)
            {
                var levelWords = words
                    .Where(word => word.LevelId == level.Id)
                    .OrderBy(word => word.Id)
                    .ToArray();

                exerciseSeeds.AddRange(CreateExercisesForLevel(
                    level.Id,
                    levelWords,
                    NormalLevelExerciseCount));
            }

            var finalTestLevel = levels.Single(level =>
                level.Section.Title == section.Title
                && level.IsFinalTest);
            var sectionWords = words
                .Where(word =>
                    word.Level.Section.Title == section.Title
                    && !word.Level.IsFinalTest)
                .OrderBy(word => word.Level.LevelNumber)
                .ThenBy(word => word.Id)
                .ToArray();

            exerciseSeeds.AddRange(CreateExercisesForLevel(
                finalTestLevel.Id,
                SelectFinalTestWords(sectionWords),
                FinalTestExerciseCount));
        }

        return exerciseSeeds;
    }

    private static ExerciseSeed[] CreateExercisesForLevel(
        int levelId,
        Word[] words,
        int exerciseCount)
    {
        if (words.Length == 0)
        {
            return Array.Empty<ExerciseSeed>();
        }

        return Enumerable.Range(1, exerciseCount)
            .Select(sortOrder =>
            {
                var word = words[(sortOrder - 1) % words.Length];
                var type = ExerciseTypes[(sortOrder - 1) % ExerciseTypes.Length];

                return new ExerciseSeed(
                    levelId,
                    word.Id,
                    type,
                    CreateQuestionText(type, word),
                    CreateCorrectAnswer(type, word),
                    sortOrder);
            })
            .ToArray();
    }

    private static Word[] SelectFinalTestWords(Word[] sectionWords)
    {
        return Enumerable.Range(0, FinalTestExerciseCount)
            .Select(index => sectionWords[(index * 7) % sectionWords.Length])
            .ToArray();
    }

    private static string? CreateQuestionText(string type, Word word)
    {
        if (type == "picture_to_english_input")
        {
            return null;
        }

        if (type == "english_to_russian_choice")
        {
            return word.English;
        }

        if (type == "russian_to_english_choice" || type == "russian_to_english_input")
        {
            return word.Russian;
        }

        if (type == "english_to_russian_input")
        {
            return word.English;
        }

        if (type == "audio_to_russian_choice")
        {
            return null;
        }

        return word.English;
    }

    private static string CreateCorrectAnswer(string type, Word word)
    {
        if (type == "english_to_russian_choice"
            || type == "english_to_russian_input"
            || type == "audio_to_russian_choice")
        {
            return word.Russian;
        }

        return word.English;
    }

    private static string[] CreateOptionTexts(Exercise exercise, List<Word> sectionWords)
    {
        var usesRussianOptions = exercise.Type is "english_to_russian_choice" or "audio_to_russian_choice";
        var correctAnswer = exercise.CorrectAnswer;
        var incorrectOptions = sectionWords
            .Where(word => word.Level.SectionId == exercise.Word.Level.SectionId && word.Id != exercise.WordId)
            .OrderBy(word => Math.Abs(word.Level.LevelNumber - exercise.Word.Level.LevelNumber))
            .ThenBy(word => word.Level.LevelNumber)
            .ThenBy(word => word.Id)
            .Select(word => usesRussianOptions ? word.Russian : word.English)
            .Where(option => !string.Equals(option, correctAnswer, StringComparison.OrdinalIgnoreCase))
            .Distinct()
            .Take(3)
            .ToArray();

        var options = new List<string>();
        options.Add(correctAnswer);
        options.AddRange(incorrectOptions);

        return options.ToArray();
    }

    private static SectionSeed[] GetSectionSeeds()
    {
        return new SectionSeed[]
        {
        new("Food", "Words about food, drinks, cooking, taste, and nutrition", "/media/images/sections/food.png", 1),
        new("Science", "Words about science, nature, laboratory work, and research", "/media/images/sections/science.png", 2),
        new("Health", "Words about the body, symptoms, medicine, and healthy habits", "/media/images/sections/health.png", 3),
        new("Wardrobe", "Words about clothes, shoes, accessories, materials, and style", "/media/images/sections/wardrobe.png", 4)
        };
    }

    private static WordSeed[] GetWordSeeds()
    {
        return new WordSeed[]
        {
        new("Food", 1, "apple", "яблоко", "/ˈæpəl/", "noun"),
        new("Food", 1, "bread", "хлеб", "/bred/", "noun"),
        new("Food", 1, "milk", "молоко", "/mɪlk/", "noun"),
        new("Food", 1, "water", "вода", "/ˈwɔːtər/", "noun"),
        new("Food", 1, "cheese", "сыр", "/tʃiːz/", "noun"),
        new("Food", 1, "egg", "яйцо", "/eɡ/", "noun"),
        new("Food", 1, "meat", "мясо", "/miːt/", "noun"),
        new("Food", 1, "fish", "рыба", "/fɪʃ/", "noun"),
        new("Food", 1, "tea", "чай", "/tiː/", "noun"),
        new("Food", 1, "juice", "сок", "/dʒuːs/", "noun"),
        new("Food", 2, "banana", "банан", "/bəˈnænə/", "noun"),
        new("Food", 2, "orange", "апельсин", "/ˈɔːrɪndʒ/", "noun"),
        new("Food", 2, "potato", "картофель", "/pəˈteɪtoʊ/", "noun"),
        new("Food", 2, "tomato", "помидор", "/təˈmeɪtoʊ/", "noun"),
        new("Food", 2, "carrot", "морковь", "/ˈkærət/", "noun"),
        new("Food", 2, "onion", "лук", "/ˈʌnjən/", "noun"),
        new("Food", 2, "rice", "рис", "/raɪs/", "noun"),
        new("Food", 2, "butter", "масло", "/ˈbʌtər/", "noun"),
        new("Food", 2, "sugar", "сахар", "/ˈʃʊɡər/", "noun"),
        new("Food", 2, "salt", "соль", "/sɔːlt/", "noun"),
        new("Food", 3, "soup", "суп", "/suːp/", "noun"),
        new("Food", 3, "salad", "салат", "/ˈsæləd/", "noun"),
        new("Food", 3, "breakfast", "завтрак", "/ˈbrekfəst/", "noun"),
        new("Food", 3, "dinner", "ужин", "/ˈdɪnər/", "noun"),
        new("Food", 3, "recipe", "рецепт", "/ˈresəpi/", "noun"),
        new("Food", 3, "cook", "готовить", "/kʊk/", "verb"),
        new("Food", 3, "boil", "кипятить", "/bɔɪl/", "verb"),
        new("Food", 3, "bake", "печь", "/beɪk/", "verb"),
        new("Food", 3, "fry", "жарить", "/fraɪ/", "verb"),
        new("Food", 3, "slice", "нарезать", "/slaɪs/", "verb"),
        new("Food", 4, "sweet", "сладкий", "/swiːt/", "adjective"),
        new("Food", 4, "sour", "кислый", "/ˈsaʊər/", "adjective"),
        new("Food", 4, "spicy", "острый", "/ˈspaɪsi/", "adjective"),
        new("Food", 4, "fresh", "свежий", "/freʃ/", "adjective"),
        new("Food", 4, "tasty", "вкусный", "/ˈteɪsti/", "adjective"),
        new("Food", 4, "kitchen", "кухня", "/ˈkɪtʃən/", "noun"),
        new("Food", 4, "meal", "трапеза", "/miːl/", "noun"),
        new("Food", 4, "diet", "рацион", "/ˈdaɪət/", "noun"),
        new("Food", 4, "healthy", "полезный", "/ˈhelθi/", "adjective"),
        new("Food", 4, "flavor", "вкус", "/ˈfleɪvər/", "noun"),
        new("Food", 5, "appetite", "аппетит", "/ˈæpɪtaɪt/", "noun"),
        new("Food", 5, "ingredient", "ингредиент", "/ɪnˈɡriːdiənt/", "noun"),
        new("Food", 5, "nutrition", "питание", "/nuːˈtrɪʃən/", "noun"),
        new("Food", 5, "beverage", "напиток", "/ˈbevərɪdʒ/", "noun"),
        new("Food", 5, "dessert", "десерт", "/dɪˈzɜːrt/", "noun"),
        new("Food", 5, "cuisine", "кулинария", "/kwɪˈziːn/", "noun"),
        new("Food", 5, "portion", "порция", "/ˈpɔːrʃən/", "noun"),
        new("Food", 5, "roast", "запекать", "/roʊst/", "verb"),
        new("Food", 5, "seasoning", "приправа", "/ˈsiːzənɪŋ/", "noun"),
        new("Food", 5, "leftover", "остаток", "/ˈleftoʊvər/", "noun"),

        new("Science", 1, "sun", "солнце", "/sʌn/", "noun"),
        new("Science", 1, "moon", "луна", "/muːn/", "noun"),
        new("Science", 1, "star", "звезда", "/stɑːr/", "noun"),
        new("Science", 1, "planet", "планета", "/ˈplænɪt/", "noun"),
        new("Science", 1, "light", "свет", "/laɪt/", "noun"),
        new("Science", 1, "air", "воздух", "/er/", "noun"),
        new("Science", 1, "earth", "земля", "/ɜːrθ/", "noun"),
        new("Science", 1, "water", "вода", "/ˈwɔːtər/", "noun"),
        new("Science", 1, "plant", "растение", "/plænt/", "noun"),
        new("Science", 1, "animal", "животное", "/ˈænɪməl/", "noun"),
        new("Science", 2, "nature", "природа", "/ˈneɪtʃər/", "noun"),
        new("Science", 2, "weather", "погода", "/ˈweðər/", "noun"),
        new("Science", 2, "temperature", "температура", "/ˈtemprətʃər/", "noun"),
        new("Science", 2, "measure", "измерять", "/ˈmeʒər/", "verb"),
        new("Science", 2, "weight", "вес", "/weɪt/", "noun"),
        new("Science", 2, "length", "длина", "/leŋθ/", "noun"),
        new("Science", 2, "speed", "скорость", "/spiːd/", "noun"),
        new("Science", 2, "energy", "энергия", "/ˈenərdʒi/", "noun"),
        new("Science", 2, "force", "сила", "/fɔːrs/", "noun"),
        new("Science", 2, "heat", "тепло", "/hiːt/", "noun"),
        new("Science", 3, "laboratory", "лаборатория", "/ˈlæbrətɔːri/", "noun"),
        new("Science", 3, "experiment", "эксперимент", "/ɪkˈsperɪmənt/", "noun"),
        new("Science", 3, "sample", "образец", "/ˈsæmpəl/", "noun"),
        new("Science", 3, "material", "материал", "/məˈtɪriəl/", "noun"),
        new("Science", 3, "metal", "металл", "/ˈmetəl/", "noun"),
        new("Science", 3, "glass", "стекло", "/ɡlæs/", "noun"),
        new("Science", 3, "liquid", "жидкость", "/ˈlɪkwɪd/", "noun"),
        new("Science", 3, "crystal", "кристалл", "/ˈkrɪstəl/", "noun"),
        new("Science", 3, "chemical", "химикат", "/ˈkemɪkəl/", "noun"),
        new("Science", 3, "observe", "наблюдать", "/əbˈzɜːrv/", "verb"),
        new("Science", 4, "atom", "атом", "/ˈætəm/", "noun"),
        new("Science", 4, "cell", "клетка", "/sel/", "noun"),
        new("Science", 4, "gene", "ген", "/dʒiːn/", "noun"),
        new("Science", 4, "gravity", "гравитация", "/ˈɡrævəti/", "noun"),
        new("Science", 4, "molecule", "молекула", "/ˈmɑːlɪkjuːl/", "noun"),
        new("Science", 4, "reaction", "реакция", "/riˈækʃən/", "noun"),
        new("Science", 4, "oxygen", "кислород", "/ˈɑːksɪdʒən/", "noun"),
        new("Science", 4, "carbon", "углерод", "/ˈkɑːrbən/", "noun"),
        new("Science", 4, "species", "вид", "/ˈspiːʃiːz/", "noun"),
        new("Science", 4, "evolve", "эволюционировать", "/ɪˈvɑːlv/", "verb"),
        new("Science", 5, "hypothesis", "гипотеза", "/haɪˈpɑːθəsɪs/", "noun"),
        new("Science", 5, "evidence", "доказательство", "/ˈevɪdəns/", "noun"),
        new("Science", 5, "research", "исследование", "/rɪˈsɜːrtʃ/", "noun"),
        new("Science", 5, "analysis", "анализ", "/əˈnæləsɪs/", "noun"),
        new("Science", 5, "microscope", "микроскоп", "/ˈmaɪkrəskoʊp/", "noun"),
        new("Science", 5, "radiation", "излучение", "/ˌreɪdiˈeɪʃən/", "noun"),
        new("Science", 5, "ecosystem", "экосистема", "/ˈiːkoʊsɪstəm/", "noun"),
        new("Science", 5, "biodiversity", "биоразнообразие", "/ˌbaɪoʊdaɪˈvɜːrsəti/", "noun"),
        new("Science", 5, "compound", "соединение", "/ˈkɑːmpaʊnd/", "noun"),
        new("Science", 5, "particle", "частица", "/ˈpɑːrtɪkəl/", "noun"),

        new("Health", 1, "head", "голова", "/hed/", "noun"),
        new("Health", 1, "hand", "рука", "/hænd/", "noun"),
        new("Health", 1, "leg", "нога", "/leɡ/", "noun"),
        new("Health", 1, "eye", "глаз", "/aɪ/", "noun"),
        new("Health", 1, "ear", "ухо", "/ɪr/", "noun"),
        new("Health", 1, "heart", "сердце", "/hɑːrt/", "noun"),
        new("Health", 1, "doctor", "врач", "/ˈdɑːktər/", "noun"),
        new("Health", 1, "nurse", "медсестра", "/nɜːrs/", "noun"),
        new("Health", 1, "healthy", "здоровый", "/ˈhelθi/", "adjective"),
        new("Health", 1, "sick", "больной", "/sɪk/", "adjective"),
        new("Health", 2, "pain", "боль", "/peɪn/", "noun"),
        new("Health", 2, "cough", "кашель", "/kɔːf/", "noun"),
        new("Health", 2, "fever", "температура", "/ˈfiːvər/", "noun"),
        new("Health", 2, "cold", "простуда", "/koʊld/", "noun"),
        new("Health", 2, "tired", "уставший", "/ˈtaɪərd/", "adjective"),
        new("Health", 2, "sleep", "спать", "/sliːp/", "verb"),
        new("Health", 2, "rest", "отдыхать", "/rest/", "verb"),
        new("Health", 2, "hurt", "болеть", "/hɜːrt/", "verb"),
        new("Health", 2, "wash", "мыть", "/wɑːʃ/", "verb"),
        new("Health", 2, "breathe", "дышать", "/briːð/", "verb"),
        new("Health", 3, "hospital", "больница", "/ˈhɑːspɪtəl/", "noun"),
        new("Health", 3, "medicine", "лекарство", "/ˈmedɪsən/", "noun"),
        new("Health", 3, "patient", "пациент", "/ˈpeɪʃənt/", "noun"),
        new("Health", 3, "clinic", "клиника", "/ˈklɪnɪk/", "noun"),
        new("Health", 3, "dentist", "стоматолог", "/ˈdentɪst/", "noun"),
        new("Health", 3, "checkup", "осмотр", "/ˈtʃekʌp/", "noun"),
        new("Health", 3, "bandage", "бинт", "/ˈbændɪdʒ/", "noun"),
        new("Health", 3, "injection", "укол", "/ɪnˈdʒekʃən/", "noun"),
        new("Health", 3, "prescription", "рецепт", "/prɪˈskrɪpʃən/", "noun"),
        new("Health", 3, "examine", "осматривать", "/ɪɡˈzæmɪn/", "verb"),
        new("Health", 4, "treatment", "лечение", "/ˈtriːtmənt/", "noun"),
        new("Health", 4, "prevent", "предотвращать", "/prɪˈvent/", "verb"),
        new("Health", 4, "recover", "выздоравливать", "/rɪˈkʌvər/", "verb"),
        new("Health", 4, "vaccine", "вакцина", "/vækˈsiːn/", "noun"),
        new("Health", 4, "vitamin", "витамин", "/ˈvaɪtəmɪn/", "noun"),
        new("Health", 4, "exercise", "упражнение", "/ˈeksərsaɪz/", "noun"),
        new("Health", 4, "hygiene", "гигиена", "/ˈhaɪdʒiːn/", "noun"),
        new("Health", 4, "allergy", "аллергия", "/ˈælərdʒi/", "noun"),
        new("Health", 4, "therapy", "терапия", "/ˈθerəpi/", "noun"),
        new("Health", 4, "heal", "исцелять", "/hiːl/", "verb"),
        new("Health", 5, "diagnosis", "диагноз", "/ˌdaɪəɡˈnoʊsɪs/", "noun"),
        new("Health", 5, "symptom", "симптом", "/ˈsɪmptəm/", "noun"),
        new("Health", 5, "infection", "инфекция", "/ɪnˈfekʃən/", "noun"),
        new("Health", 5, "immune", "иммунный", "/ɪˈmjuːn/", "adjective"),
        new("Health", 5, "pressure", "давление", "/ˈpreʃər/", "noun"),
        new("Health", 5, "nutrition", "питание", "/nuːˈtrɪʃən/", "noun"),
        new("Health", 5, "mental", "психический", "/ˈmentəl/", "adjective"),
        new("Health", 5, "chronic", "хронический", "/ˈkrɑːnɪk/", "adjective"),
        new("Health", 5, "trauma", "травма", "/ˈtraʊmə/", "noun"),
        new("Health", 5, "rehabilitation", "реабилитация", "/ˌriːhəˌbɪlɪˈteɪʃən/", "noun"),

        new("Wardrobe", 1, "shirt", "рубашка", "/ʃɜːrt/", "noun"),
        new("Wardrobe", 1, "dress", "платье", "/dres/", "noun"),
        new("Wardrobe", 1, "coat", "пальто", "/koʊt/", "noun"),
        new("Wardrobe", 1, "hat", "шляпа", "/hæt/", "noun"),
        new("Wardrobe", 1, "pants", "брюки", "/pænts/", "noun"),
        new("Wardrobe", 1, "skirt", "юбка", "/skɜːrt/", "noun"),
        new("Wardrobe", 1, "socks", "носки", "/sɑːks/", "noun"),
        new("Wardrobe", 1, "jacket", "куртка", "/ˈdʒækɪt/", "noun"),
        new("Wardrobe", 1, "sweater", "свитер", "/ˈswetər/", "noun"),
        new("Wardrobe", 1, "jeans", "джинсы", "/dʒiːnz/", "noun"),
        new("Wardrobe", 2, "shoes", "туфли", "/ʃuːz/", "noun"),
        new("Wardrobe", 2, "boots", "ботинки", "/buːts/", "noun"),
        new("Wardrobe", 2, "sneakers", "кроссовки", "/ˈsniːkərz/", "noun"),
        new("Wardrobe", 2, "belt", "ремень", "/belt/", "noun"),
        new("Wardrobe", 2, "bag", "сумка", "/bæɡ/", "noun"),
        new("Wardrobe", 2, "watch", "часы", "/wɑːtʃ/", "noun"),
        new("Wardrobe", 2, "gloves", "перчатки", "/ɡlʌvz/", "noun"),
        new("Wardrobe", 2, "scarf", "шарф", "/skɑːrf/", "noun"),
        new("Wardrobe", 2, "cap", "кепка", "/kæp/", "noun"),
        new("Wardrobe", 2, "ring", "кольцо", "/rɪŋ/", "noun"),
        new("Wardrobe", 3, "cotton", "хлопок", "/ˈkɑːtən/", "noun"),
        new("Wardrobe", 3, "wool", "шерсть", "/wʊl/", "noun"),
        new("Wardrobe", 3, "leather", "кожа", "/ˈleðər/", "noun"),
        new("Wardrobe", 3, "silk", "шелк", "/sɪlk/", "noun"),
        new("Wardrobe", 3, "denim", "деним", "/ˈdenɪm/", "noun"),
        new("Wardrobe", 3, "loose", "свободный", "/luːs/", "adjective"),
        new("Wardrobe", 3, "tight", "тесный", "/taɪt/", "adjective"),
        new("Wardrobe", 3, "casual", "повседневный", "/ˈkæʒuəl/", "adjective"),
        new("Wardrobe", 3, "formal", "официальный", "/ˈfɔːrməl/", "adjective"),
        new("Wardrobe", 3, "pattern", "узор", "/ˈpætərn/", "noun"),
        new("Wardrobe", 4, "uniform", "форма", "/ˈjuːnɪfɔːrm/", "noun"),
        new("Wardrobe", 4, "suit", "костюм", "/suːt/", "noun"),
        new("Wardrobe", 4, "tie", "галстук", "/taɪ/", "noun"),
        new("Wardrobe", 4, "raincoat", "плащ", "/ˈreɪnkoʊt/", "noun"),
        new("Wardrobe", 4, "swimsuit", "купальник", "/ˈswɪmsuːt/", "noun"),
        new("Wardrobe", 4, "pajamas", "пижама", "/pəˈdʒɑːməz/", "noun"),
        new("Wardrobe", 4, "outfit", "наряд", "/ˈaʊtfɪt/", "noun"),
        new("Wardrobe", 4, "change", "переодеваться", "/tʃeɪndʒ/", "verb"),
        new("Wardrobe", 4, "match", "сочетаться", "/mætʃ/", "verb"),
        new("Wardrobe", 4, "elegant", "элегантный", "/ˈelɪɡənt/", "adjective"),
        new("Wardrobe", 5, "wardrobe", "гардероб", "/ˈwɔːrdroʊb/", "noun"),
        new("Wardrobe", 5, "fashion", "мода", "/ˈfæʃən/", "noun"),
        new("Wardrobe", 5, "style", "стиль", "/staɪl/", "noun"),
        new("Wardrobe", 5, "accessory", "аксессуар", "/əkˈsesəri/", "noun"),
        new("Wardrobe", 5, "fabric", "ткань", "/ˈfæbrɪk/", "noun"),
        new("Wardrobe", 5, "seam", "шов", "/siːm/", "noun"),
        new("Wardrobe", 5, "sleeve", "рукав", "/sliːv/", "noun"),
        new("Wardrobe", 5, "collar", "воротник", "/ˈkɑːlər/", "noun"),
        new("Wardrobe", 5, "tailor", "портной", "/ˈteɪlər/", "noun"),
        new("Wardrobe", 5, "alter", "перешивать", "/ˈɔːltər/", "verb")
        };
    }

    private static string GetLevelCefrLevel(int levelNumber)
    {
        if (levelNumber == 1 || levelNumber == 2)
        {
            return "A1";
        }

        if (levelNumber == 3)
        {
            return "A2";
        }

        if (levelNumber == 4)
        {
            return "A2/B1";
        }

        if (levelNumber == 5)
        {
            return "B1/B2";
        }

        return "mixed";
    }

    private static string GetLevelDescription(string sectionTitle, int levelNumber)
    {
        if (sectionTitle == "Food" && levelNumber == 1) return "Simple food and drink words";
        if (sectionTitle == "Food" && levelNumber == 2) return "Fruit, vegetables, and basic products";
        if (sectionTitle == "Food" && levelNumber == 3) return "Dishes and cooking actions";
        if (sectionTitle == "Food" && levelNumber == 4) return "Taste, kitchen, and nutrition words";
        if (sectionTitle == "Food" && levelNumber == 5) return "More advanced food vocabulary";

        if (sectionTitle == "Science" && levelNumber == 1) return "Simple science words";
        if (sectionTitle == "Science" && levelNumber == 2) return "Nature, weather, and measurements";
        if (sectionTitle == "Science" && levelNumber == 3) return "Laboratory and material words";
        if (sectionTitle == "Science" && levelNumber == 4) return "Physics, chemistry, and biology words";
        if (sectionTitle == "Science" && levelNumber == 5) return "More advanced science terms";

        if (sectionTitle == "Health" && levelNumber == 1) return "Body and basic health words";
        if (sectionTitle == "Health" && levelNumber == 2) return "Symptoms and simple health actions";
        if (sectionTitle == "Health" && levelNumber == 3) return "Medicine, doctors, and clinics";
        if (sectionTitle == "Health" && levelNumber == 4) return "Treatment and prevention words";
        if (sectionTitle == "Health" && levelNumber == 5) return "More advanced health vocabulary";

        if (sectionTitle == "Wardrobe" && levelNumber == 1) return "Basic clothing words";
        if (sectionTitle == "Wardrobe" && levelNumber == 2) return "Shoes and accessories";
        if (sectionTitle == "Wardrobe" && levelNumber == 3) return "Materials and styles";
        if (sectionTitle == "Wardrobe" && levelNumber == 4) return "Clothes for different situations";
        if (sectionTitle == "Wardrobe" && levelNumber == 5) return "More advanced fashion and clothing vocabulary";

        return $"Level {levelNumber} for {sectionTitle} section";
    }

    private static string CreateWordKey(string sectionTitle, int levelNumber, string english)
    {
        return $"{sectionTitle}|{levelNumber}|{english}".ToLowerInvariant();
    }

    private static string CreateExerciseKey(int levelId, int sortOrder)
    {
        return $"{levelId}|{sortOrder}";
    }

    private static DateTime CreateTimestamp()
    {
        return DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
    }

    private class AvatarSeed
    {
        public AvatarSeed(string name, string imageUrl)
        {
            Name = name;
            ImageUrl = imageUrl;
        }

        public string Name { get; }

        public string ImageUrl { get; }
    }

    private class SectionSeed
    {
        public SectionSeed(string title, string description, string imageUrl, int sortOrder)
        {
            Title = title;
            Description = description;
            ImageUrl = imageUrl;
            SortOrder = sortOrder;
        }

        public string Title { get; }

        public string Description { get; }

        public string ImageUrl { get; }

        public int SortOrder { get; }
    }

    private class WordSeed
    {
        public WordSeed(
            string sectionTitle,
            int levelNumber,
            string english,
            string russian,
            string transcription,
            string partOfSpeech)
        {
            SectionTitle = sectionTitle;
            LevelNumber = levelNumber;
            English = english;
            Russian = russian;
            Transcription = transcription;
            PartOfSpeech = partOfSpeech;
        }

        public string SectionTitle { get; }

        public int LevelNumber { get; }

        public string English { get; }

        public string Russian { get; }

        public string Transcription { get; }

        public string PartOfSpeech { get; }

        public string CefrLevel
        {
            get { return GetLevelCefrLevel(LevelNumber); }
        }

        public string ImageUrl
        {
            get { return $"/media/images/words/{CreateSlug(English)}.png"; }
        }

        public string AudioUrl
        {
            get { return $"/media/audio/words/{CreateSlug(English)}.mp3"; }
        }

        private static string CreateSlug(string value)
        {
            return value.ToLowerInvariant().Replace(' ', '-');
        }
    }

    private class ExerciseSeed
    {
        public ExerciseSeed(
            int levelId,
            int wordId,
            string type,
            string? questionText,
            string correctAnswer,
            int sortOrder)
        {
            LevelId = levelId;
            WordId = wordId;
            Type = type;
            QuestionText = questionText;
            CorrectAnswer = correctAnswer;
            SortOrder = sortOrder;
        }

        public int LevelId { get; }

        public int WordId { get; }

        public string Type { get; }

        public string? QuestionText { get; }

        public string CorrectAnswer { get; }

        public int SortOrder { get; }
    }
}
