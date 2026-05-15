using Swirl.Api.Requests;
using Swirl.Api.Responses;

namespace Swirl.Api.Interfaces;

public interface IDailyTestService
{
    Task<DailyTestResponse> GetDailyTestAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<CompleteDailyTestResponse> CompleteDailyTestAsync(
        Guid userId,
        CompleteDailyTestRequest request,
        CancellationToken cancellationToken = default);
}
