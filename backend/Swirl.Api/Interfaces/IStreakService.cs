using Swirl.Api.Responses;

namespace Swirl.Api.Interfaces;

public interface IStreakService
{
    Task<StreakResponse> UpdateLearningActivityAsync(
        Guid userId,
        CancellationToken cancellationToken = default);
}
