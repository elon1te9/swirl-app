using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swirl.Api.Interfaces;
using Swirl.Api.Requests;
using Swirl.Api.Responses;

namespace Swirl.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/profile")]
public class ProfileController(IProfileService profileService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ProfileResponse>> GetProfile(CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized(new ErrorResponse(new ErrorDetails(
                "unauthorized",
                "Authentication is required")));
        }

        var profile = await profileService.GetProfileAsync(userId.Value, cancellationToken);
        if (profile is null)
        {
            return NotFound(new ErrorResponse(new ErrorDetails(
                "not_found",
                "Resource not found")));
        }

        return Ok(profile);
    }

    [HttpPut("avatar")]
    public async Task<ActionResult<ChangeAvatarResponse>> ChangeAvatar(
        ChangeAvatarRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized(new ErrorResponse(new ErrorDetails(
                "unauthorized",
                "Authentication is required")));
        }

        return Ok(await profileService.ChangeAvatarAsync(userId.Value, request, cancellationToken));
    }

    private Guid? GetCurrentUserId()
    {
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        return Guid.TryParse(userIdValue, out var userId)
            ? userId
            : null;
    }
}
