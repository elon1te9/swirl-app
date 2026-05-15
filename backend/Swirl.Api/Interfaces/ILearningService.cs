using Swirl.Api.Requests;
using Swirl.Api.Responses;

namespace Swirl.Api.Interfaces;

public interface ILearningService
{
    Task<LevelSessionResponse> GetLevelSessionAsync(
        Guid userId,
        int levelId,
        CancellationToken cancellationToken = default);

    Task<CompleteLevelResponse> CompleteLevelAsync(
        Guid userId,
        int levelId,
        CompleteLevelRequest request,
        CancellationToken cancellationToken = default);
}
