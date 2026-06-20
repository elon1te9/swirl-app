using Microsoft.EntityFrameworkCore;
using Swirl.Api.Data;
using Swirl.Api.Interfaces;
using Swirl.Api.Models;
using Swirl.Api.Responses;

namespace Swirl.Api.Services;

public class ContentService : IContentService
{
    private const string LockedStatus = "locked";
    private const string AvailableStatus = "available";
    private const string CompletedStatus = "completed";

    private readonly AppDbContext _context;

    public ContentService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<List<SectionResponse>> GetSectionsAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var sections = await _context.Sections
            .Include(section => section.Levels)
            .Where(section => section.IsActive)
            .OrderBy(section => section.SortOrder)
            .ToListAsync(cancellationToken);

        var activeLevelIds = sections
            .SelectMany(section => section.Levels)
            .Where(level => level.IsActive)
            .Select(level => level.Id)
            .ToArray();

        var completedLevelIds = await _context.UserLevelProgresses
            .Where(progress =>
                progress.UserId == userId
                && progress.Status == CompletedStatus
                && activeLevelIds.Contains(progress.LevelId))
            .Select(progress => progress.LevelId)
            .ToListAsync(cancellationToken);

        var completedLevelIdsSet = completedLevelIds.ToHashSet();

        var result = new List<SectionResponse>();
        foreach (var section in sections)
        {
            result.Add(CreateSectionResponse(section, completedLevelIdsSet));
        }

        return result;
    }

    public async Task<SectionResponse?> GetSectionAsync(
        Guid userId,
        int sectionId,
        CancellationToken cancellationToken = default)
    {
        var section = await _context.Sections
            .Include(candidate => candidate.Levels)
            .FirstOrDefaultAsync(
                candidate => candidate.Id == sectionId && candidate.IsActive,
                cancellationToken);

        if (section is null)
        {
            return null;
        }

        var activeLevelIds = section.Levels
            .Where(level => level.IsActive)
            .Select(level => level.Id)
            .ToArray();

        var completedLevelIds = await _context.UserLevelProgresses
            .Where(progress =>
                progress.UserId == userId
                && progress.Status == CompletedStatus
                && activeLevelIds.Contains(progress.LevelId))
            .Select(progress => progress.LevelId)
            .ToListAsync(cancellationToken);

        return CreateSectionResponse(section, completedLevelIds.ToHashSet());
    }

    public async Task<List<LevelResponse>?> GetSectionLevelsAsync(
        Guid userId,
        int sectionId,
        CancellationToken cancellationToken = default)
    {
        var sectionExists = await _context.Sections
            .AnyAsync(section => section.Id == sectionId && section.IsActive, cancellationToken);

        if (!sectionExists)
        {
            return null;
        }

        var levels = await _context.Levels
            .Include(level => level.Words)
            .Include(level => level.Exercises)
            .Where(level => level.SectionId == sectionId && level.IsActive)
            .OrderBy(level => level.SortOrder)
            .ToListAsync(cancellationToken);

        var progressByLevelId = await GetProgressByLevelIdAsync(userId, levels, cancellationToken);

        var result = new List<LevelResponse>();
        foreach (var level in levels)
        {
            result.Add(CreateLevelResponse(level, progressByLevelId, levels));
        }

        return result;
    }

    public async Task<LevelDetailsResponse?> GetLevelAsync(
        Guid userId,
        int levelId,
        CancellationToken cancellationToken = default)
    {
        var level = await _context.Levels
            .Include(candidate => candidate.Section)
            .Include(candidate => candidate.Words)
            .Include(candidate => candidate.Exercises)
            .FirstOrDefaultAsync(
                candidate =>
                    candidate.Id == levelId
                    && candidate.IsActive
                    && candidate.Section.IsActive,
                cancellationToken);

        if (level is null)
        {
            return null;
        }

        var sectionLevels = await _context.Levels
            .Include(candidate => candidate.Words)
            .Where(candidate => candidate.SectionId == level.SectionId && candidate.IsActive)
            .OrderBy(candidate => candidate.SortOrder)
            .ToListAsync(cancellationToken);

        var progressByLevelId = await GetProgressByLevelIdAsync(userId, sectionLevels, cancellationToken);
        progressByLevelId.TryGetValue(level.Id, out var progress);

        return new LevelDetailsResponse
        {
            Id = level.Id,
            SectionId = level.SectionId,
            SectionTitle = level.Section.Title,
            Title = level.Title,
            LevelNumber = level.LevelNumber,
            CefrLevel = level.CefrLevel,
            Description = level.Description,
            WordsCount = CountWordsForDisplay(level, sectionLevels),
            ExercisesCount = level.Exercises.Count(exercise => exercise.IsActive),
            IsFinalTest = level.IsFinalTest,
            Status = GetLevelStatus(level, progress, sectionLevels),
            WordsLearned = progress?.WordsLearned ?? false
        };
    }

    private static SectionResponse CreateSectionResponse(
        Section section,
        HashSet<int> completedLevelIds)
    {
        var activeLevels = section.Levels
            .Where(level => level.IsActive)
            .ToList();

        var totalLevels = activeLevels.Count;
        var completedLevels = activeLevels.Count(level => completedLevelIds.Contains(level.Id));

        return new SectionResponse
        {
            Id = section.Id,
            Title = section.Title,
            Description = section.Description,
            ImageUrl = section.ImageUrl,
            ProgressPercent = totalLevels == 0
                ? 0
                : (int)Math.Round(completedLevels * 100.0 / totalLevels),
            CompletedLevels = completedLevels,
            TotalLevels = totalLevels
        };
    }

    private static LevelResponse CreateLevelResponse(
        Level level,
        Dictionary<int, UserLevelProgress> progressByLevelId,
        List<Level> sectionLevels)
    {
        progressByLevelId.TryGetValue(level.Id, out var progress);

        return new LevelResponse
        {
            Id = level.Id,
            SectionId = level.SectionId,
            Title = level.Title,
            LevelNumber = level.LevelNumber,
            CefrLevel = level.CefrLevel,
            Description = level.Description,
            WordsCount = CountWordsForDisplay(level, sectionLevels),
            ExercisesCount = level.Exercises.Count(exercise => exercise.IsActive),
            IsFinalTest = level.IsFinalTest,
            Status = GetLevelStatus(level, progress, sectionLevels),
            CompletedAt = progress?.CompletedAt
        };
    }

    private async Task<Dictionary<int, UserLevelProgress>> GetProgressByLevelIdAsync(
        Guid userId,
        List<Level> levels,
        CancellationToken cancellationToken)
    {
        var levelIds = levels.Select(level => level.Id).ToArray();

        return await _context.UserLevelProgresses
            .Where(progress => progress.UserId == userId && levelIds.Contains(progress.LevelId))
            .ToDictionaryAsync(progress => progress.LevelId, cancellationToken);
    }

    private static int CountWordsForDisplay(Level level, List<Level> sectionLevels)
    {
        if (!level.IsFinalTest)
        {
            return level.Words.Count(word => word.IsActive);
        }

        return sectionLevels
            .Where(candidate => !candidate.IsFinalTest)
            .SelectMany(candidate => candidate.Words)
            .Count(word => word.IsActive);
    }

    private static string GetLevelStatus(
        Level level,
        UserLevelProgress? progress,
        List<Level>? sectionLevels)
    {
        if (progress is not null)
        {
            return progress.Status;
        }

        var firstNormalLevelId = sectionLevels?
            .Where(candidate => !candidate.IsFinalTest)
            .OrderBy(candidate => candidate.SortOrder)
            .Select(candidate => candidate.Id)
            .FirstOrDefault();

        if (!level.IsFinalTest && level.Id == firstNormalLevelId)
        {
            return AvailableStatus;
        }

        return LockedStatus;
    }
}
