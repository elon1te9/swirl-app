using Swirl.Api.Requests;
using Swirl.Api.Responses;

namespace Swirl.Api.Interfaces;

public interface IProfileService
{
    Task<List<AvatarResponse>> GetAvatarsAsync(CancellationToken cancellationToken = default);

    Task<ProfileResponse?> GetProfileAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<ProfileResponse> UpdateProfileAsync(
        Guid userId,
        UpdateProfileRequest request,
        CancellationToken cancellationToken = default);

    Task<ChangeAvatarResponse> ChangeAvatarAsync(
        Guid userId,
        ChangeAvatarRequest request,
        CancellationToken cancellationToken = default);
}
