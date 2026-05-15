using Microsoft.EntityFrameworkCore;
using Swirl.Api.Data;
using Swirl.Api.Models;
using Swirl.Api.Services;

namespace Swirl.Api.Tests;

public class StreakServiceTests
{
    [Fact]
    public async Task UpdateLearningActivityAsync_StartsStreakWhenLastActivityIsMissing()
    {
        await using var dbContext = await CreateDbContextAsync();
        var user = await CreateUserWithProfileAsync(dbContext);
        var today = DateOnly.FromDateTime(DateTime.Now);
        var service = new StreakService(dbContext);

        var result = await service.UpdateLearningActivityAsync(user.Id);

        Assert.Equal(1, result.CurrentStreak);
        Assert.Equal(1, result.BestStreak);

        var profile = await dbContext.UserProfiles.SingleAsync(profile => profile.UserId == user.Id);
        Assert.Equal(today, profile.LastActivityDate);
    }

    [Fact]
    public async Task UpdateLearningActivityAsync_IncrementsStreakAfterYesterday()
    {
        await using var dbContext = await CreateDbContextAsync();
        var user = await CreateUserWithProfileAsync(dbContext);
        var profile = await dbContext.UserProfiles.SingleAsync(profile => profile.UserId == user.Id);
        profile.CurrentStreak = 4;
        profile.BestStreak = 6;
        profile.LastActivityDate = DateOnly.FromDateTime(DateTime.Now).AddDays(-1);
        await dbContext.SaveChangesAsync();
        var service = new StreakService(dbContext);

        var result = await service.UpdateLearningActivityAsync(user.Id);

        Assert.Equal(5, result.CurrentStreak);
        Assert.Equal(6, result.BestStreak);
    }

    [Fact]
    public async Task UpdateLearningActivityAsync_DoesNotIncreaseTwiceOnSameDate()
    {
        await using var dbContext = await CreateDbContextAsync();
        var user = await CreateUserWithProfileAsync(dbContext);
        var profile = await dbContext.UserProfiles.SingleAsync(profile => profile.UserId == user.Id);
        profile.CurrentStreak = 3;
        profile.BestStreak = 3;
        profile.LastActivityDate = DateOnly.FromDateTime(DateTime.Now);
        await dbContext.SaveChangesAsync();
        var service = new StreakService(dbContext);

        var result = await service.UpdateLearningActivityAsync(user.Id);

        Assert.Equal(3, result.CurrentStreak);
        Assert.Equal(3, result.BestStreak);
    }

    [Fact]
    public async Task UpdateLearningActivityAsync_ResetsStreakAfterGap()
    {
        await using var dbContext = await CreateDbContextAsync();
        var user = await CreateUserWithProfileAsync(dbContext);
        var profile = await dbContext.UserProfiles.SingleAsync(profile => profile.UserId == user.Id);
        profile.CurrentStreak = 5;
        profile.BestStreak = 8;
        profile.LastActivityDate = DateOnly.FromDateTime(DateTime.Now).AddDays(-3);
        await dbContext.SaveChangesAsync();
        var service = new StreakService(dbContext);

        var result = await service.UpdateLearningActivityAsync(user.Id);

        Assert.Equal(1, result.CurrentStreak);
        Assert.Equal(8, result.BestStreak);
    }

    private static async Task<User> CreateUserWithProfileAsync(AppDbContext dbContext)
    {
        var now = CreateTimestamp();
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "user@example.com",
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

    private static async Task<AppDbContext> CreateDbContextAsync()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        var dbContext = new AppDbContext(options);
        dbContext.Avatars.Add(new Avatar
        {
            Id = 1,
            Name = "Avatar 1",
            ImageUrl = "/media/avatars/avatar_1.png",
            IsActive = true
        });
        await dbContext.SaveChangesAsync();

        return dbContext;
    }

    private static DateTime CreateTimestamp() =>
        DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Unspecified);
}
