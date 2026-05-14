using Microsoft.EntityFrameworkCore;
using Swirl.Api.Models;

namespace Swirl.Api.Data;

public static class DatabaseSeeder
{
    private const string DefaultCefrLevel = "A1";
    private const int NormalLevelsPerSection = 5;
    private const int FinalTestLevelNumber = NormalLevelsPerSection + 1;

    public static async Task SeedAsync(AppDbContext dbContext, CancellationToken cancellationToken = default)
    {
        var now = CreateTimestamp();

        await SeedAvatarsAsync(dbContext, cancellationToken);
        await SeedSectionsAsync(dbContext, now, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        await SeedLevelsAsync(dbContext, now, cancellationToken);
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

    private static SectionSeed[] GetSectionSeeds() =>
    [
        new("Food", "Words about food and drinks", "/media/images/sections/food.png", 1),
        new("Science", "Words about science and discovery", "/media/images/sections/science.png", 2),
        new("Health", "Words about health and wellbeing", "/media/images/sections/health.png", 3),
        new("Wardrobe", "Words about clothes and wardrobe", "/media/images/sections/wardrobe.png", 4)
    ];

    private static DateTime CreateTimestamp() =>
        DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);

    private sealed record AvatarSeed(string Name, string ImageUrl);

    private sealed record SectionSeed(string Title, string Description, string ImageUrl, int SortOrder);
}
