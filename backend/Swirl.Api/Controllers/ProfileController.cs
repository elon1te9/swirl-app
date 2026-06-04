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
public class ProfileController : ControllerBase
{
    private readonly IProfileService _profileService;

    public ProfileController(IProfileService profileService)
    {
        _profileService = profileService;
    }

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

        var profile = await _profileService.GetProfileAsync(userId.Value, cancellationToken);
        if (profile is null)
        {
            return NotFound(new ErrorResponse(new ErrorDetails(
                "not_found",
                "Resource not found")));
        }

        return Ok(profile);
    }

    [HttpPut]
    public async Task<ActionResult<ProfileResponse>> UpdateProfile(
        UpdateProfileRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized(new ErrorResponse(new ErrorDetails(
                "unauthorized",
                "Authentication is required")));
        }

        var result = await _profileService.UpdateProfileAsync(
            userId.Value,
            request,
            cancellationToken);

        return Ok(result);
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

        var result = await _profileService.ChangeAvatarAsync(userId.Value, request, cancellationToken);
        return Ok(result);
    }

    private Guid? GetCurrentUserId()
    {
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        if (!Guid.TryParse(userIdValue, out var userId))
        {
            return null;
        }

        return userId;
    }
}
