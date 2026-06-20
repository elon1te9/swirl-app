using Microsoft.EntityFrameworkCore;
using Swirl.Api.Data;
using Swirl.Api.Interfaces;
using Swirl.Api.Models;
using Swirl.Api.Requests;
using Swirl.Api.Responses;

namespace Swirl.Api.Services;

public class WordLearningService : IWordLearningService
{
    private const string LockedStatus = "locked";
    private const string AvailableStatus = "available";

    private readonly AppDbContext _context;

    public WordLearningService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<List<WordResponse>> GetLevelWordsAsync(
        Guid userId,
        int levelId,
        CancellationToken cancellationToken = default)
    {
        var access = await GetAccessibleLevelAsync(userId, levelId, cancellationToken);

        return await _context.Words
            .Where(word =>
                word.IsActive
                && (access.Level.IsFinalTest
                    ? word.Level.SectionId == access.Level.SectionId
                        && word.Level.IsActive
                        && !word.Level.IsFinalTest
                    : word.LevelId == levelId))
            .OrderBy(word => word.Level.LevelNumber)
            .ThenBy(word => word.Id)
            .Select(word => new WordResponse
            {
                Id = word.Id,
                English = word.English,
                Russian = word.Russian,
                Transcription = word.Transcription,
                PartOfSpeech = word.PartOfSpeech,
                ImageUrl = word.ImageUrl,
                AudioUrl = word.AudioUrl
            })
            .ToListAsync(cancellationToken);
    }

    public async Task<MarkLevelWordsLearnedResponse> MarkLevelWordsLearnedAsync(
        Guid userId,
        int levelId,
        MarkLevelWordsLearnedRequest request,
        CancellationToken cancellationToken = default)
    {
        var distinctWordIds = request.WordIds
            .Distinct()
            .ToArray();

        if (distinctWordIds.Length == 0)
        {
            throw CreateValidationException("wordIds", "Word ids are required");
        }

        var access = await GetAccessibleLevelAsync(userId, levelId, cancellationToken);

        if (access.Level.IsFinalTest)
        {
            throw CreateValidationException("levelId", "Final tests do not introduce new words");
        }

        var activeWordIds = await _context.Words
            .Where(word => word.LevelId == levelId && word.IsActive)
            .OrderBy(word => word.Id)
            .Select(word => word.Id)
            .ToArrayAsync(cancellationToken);

        var activeWordIdsSet = activeWordIds.ToHashSet();
        if (distinctWordIds.Any(wordId => !activeWordIdsSet.Contains(wordId)))
        {
            throw CreateValidationException("wordIds", "Word ids must belong to the level");
        }

        if (distinctWordIds.Length != activeWordIds.Length)
        {
            throw CreateValidationException("wordIds", "All active level words must be marked as learned");
        }

        var existingLearnedWordIds = await _context.UserWordProgresses
            .Where(progress =>
                progress.UserId == userId
                && activeWordIds.Contains(progress.WordId))
            .Select(progress => progress.WordId)
            .ToListAsync(cancellationToken);

        var existingLearnedWordIdsSet = existingLearnedWordIds.ToHashSet();
        var now = CreateTimestamp();

        foreach (var wordId in activeWordIds)
        {
            if (existingLearnedWordIdsSet.Contains(wordId))
            {
                continue;
            }

            _context.UserWordProgresses.Add(new UserWordProgress
            {
                UserId = userId,
                WordId = wordId,
                LearnedAt = now
            });
        }

        var levelProgress = access.Progress;
        if (levelProgress is null)
        {
            levelProgress = new UserLevelProgress
            {
                UserId = userId,
                LevelId = levelId,
                Status = AvailableStatus,
                WordsLearned = true,
                AttemptsCount = 0,
                UnlockedAt = now
            };
            _context.UserLevelProgresses.Add(levelProgress);
        }
        else
        {
            levelProgress.WordsLearned = true;
        }

        await _context.SaveChangesAsync(cancellationToken);

        return new MarkLevelWordsLearnedResponse
        {
            LevelId = levelId,
            WordsLearned = true,
            LearnedWordsCount = activeWordIds.Length
        };
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
}
