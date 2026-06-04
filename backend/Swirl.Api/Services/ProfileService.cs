using Microsoft.EntityFrameworkCore;
using Swirl.Api.Data;
using Swirl.Api.Interfaces;
using Swirl.Api.Requests;
using Swirl.Api.Responses;

namespace Swirl.Api.Services;

public class ProfileService : IProfileService
{
    private readonly AppDbContext _context;

    public ProfileService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<List<AvatarResponse>> GetAvatarsAsync(CancellationToken cancellationToken = default)
    {
        return await _context.Avatars
            .Where(avatar => avatar.IsActive)
            .OrderBy(avatar => avatar.Id)
            .Select(avatar => new AvatarResponse
            {
                Id = avatar.Id,
                Name = avatar.Name,
                ImageUrl = avatar.ImageUrl
            })
            .ToListAsync(cancellationToken);
    }

    public async Task<ProfileResponse?> GetProfileAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var profile = await _context.UserProfiles
            .Include(candidate => candidate.Avatar)
            .FirstOrDefaultAsync(candidate => candidate.UserId == userId, cancellationToken);

        if (profile is null)
        {
            return null;
        }

        var learnedWordsCount = await _context.UserWordProgresses
            .CountAsync(progress => progress.UserId == userId, cancellationToken);

        var completedLevelsCount = await _context.UserLevelProgresses
            .CountAsync(
                progress => progress.UserId == userId && progress.Status == "completed",
                cancellationToken);

        var completedLevelIds = await _context.UserLevelProgresses
            .Where(progress => progress.UserId == userId && progress.Status == "completed")
            .Select(progress => progress.LevelId)
            .ToListAsync(cancellationToken);

        var completedLevelIdsSet = completedLevelIds.ToHashSet();
        var sections = await _context.Sections
            .Include(section => section.Levels)
            .Where(section => section.IsActive)
            .OrderBy(section => section.SortOrder)
            .ToListAsync(cancellationToken);

        var sectionProgress = new List<SectionProgressResponse>();
        foreach (var section in sections)
        {
            var activeLevels = section.Levels
                .Where(level => level.IsActive)
                .ToList();
            var totalLevels = activeLevels.Count;
            var completedLevels = activeLevels.Count(level => completedLevelIdsSet.Contains(level.Id));
            var progressPercent = totalLevels == 0
                ? 0
                : (int)Math.Round(completedLevels * 100.0 / totalLevels);

            sectionProgress.Add(new SectionProgressResponse
            {
                SectionId = section.Id,
                Title = section.Title,
                ProgressPercent = progressPercent
            });
        }

        return new ProfileResponse
        {
            Name = profile.Name,
            AvatarUrl = profile.Avatar.ImageUrl,
            CurrentStreak = profile.CurrentStreak,
            BestStreak = profile.BestStreak,
            LearnedWordsCount = learnedWordsCount,
            CompletedLevelsCount = completedLevelsCount,
            SectionsProgress = sectionProgress
        };
    }

    public async Task<ChangeAvatarResponse> ChangeAvatarAsync(
        Guid userId,
        ChangeAvatarRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.AvatarId <= 0)
        {
            throw CreateInvalidAvatarException("Avatar is required");
        }

        var avatar = await _context.Avatars
            .FirstOrDefaultAsync(
                candidate => candidate.Id == request.AvatarId && candidate.IsActive,
                cancellationToken);

        if (avatar is null)
        {
            throw CreateInvalidAvatarException("Avatar must exist and be active");
        }

        var profile = await _context.UserProfiles
            .FirstOrDefaultAsync(candidate => candidate.UserId == userId, cancellationToken);

        if (profile is null)
        {
            throw new ApiException(
                StatusCodes.Status404NotFound,
                "not_found",
                "Resource not found");
        }

        profile.AvatarId = avatar.Id;
        profile.UpdatedAt = CreateTimestamp();

        await _context.SaveChangesAsync(cancellationToken);

        return new ChangeAvatarResponse
        {
            AvatarUrl = avatar.ImageUrl
        };
    }

    public async Task<ProfileResponse> UpdateProfileAsync(
        Guid userId,
        UpdateProfileRequest request,
        CancellationToken cancellationToken = default)
    {
        var name = request.Name.Trim();
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new ApiException(
                StatusCodes.Status400BadRequest,
                "validation_error",
                "Validation failed",
                new Dictionary<string, string[]>
                {
                    ["name"] = new[] { "Name is required" }
                });
        }

        if (request.AvatarId <= 0)
        {
            throw CreateInvalidAvatarException("Avatar is required");
        }

        var avatar = await _context.Avatars
            .FirstOrDefaultAsync(
                candidate => candidate.Id == request.AvatarId && candidate.IsActive,
                cancellationToken);

        if (avatar is null)
        {
            throw CreateInvalidAvatarException("Avatar must exist and be active");
        }

        var profile = await _context.UserProfiles
            .FirstOrDefaultAsync(candidate => candidate.UserId == userId, cancellationToken);

        if (profile is null)
        {
            throw new ApiException(
                StatusCodes.Status404NotFound,
                "not_found",
                "Resource not found");
        }

        profile.Name = name;
        profile.AvatarId = avatar.Id;
        profile.UpdatedAt = CreateTimestamp();

        await _context.SaveChangesAsync(cancellationToken);

        var updatedProfile = await GetProfileAsync(userId, cancellationToken);
        return updatedProfile!;
    }

    private static ApiException CreateInvalidAvatarException(string message)
    {
        return new ApiException(
            StatusCodes.Status400BadRequest,
            "validation_error",
            "Validation failed",
            new Dictionary<string, string[]>
            {
                ["avatarId"] = new[] { message }
            });
    }

    private static DateTime CreateTimestamp()
    {
        return DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
    }
}
