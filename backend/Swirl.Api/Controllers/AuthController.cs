using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swirl.Api.Interfaces;
using Swirl.Api.Requests;
using Swirl.Api.Responses;

namespace Swirl.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(IAuthService authService) : ControllerBase
{
    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Register(
        RegisterRequest request,
        CancellationToken cancellationToken)
        => Ok(await authService.RegisterAsync(request, cancellationToken));

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Login(
        LoginRequest request,
        CancellationToken cancellationToken)
        => Ok(await authService.LoginAsync(request, cancellationToken));

    [HttpGet("me")]
    [Authorize]
    public async Task<ActionResult<CurrentUserResponse>> Me(CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized(new ErrorResponse(new ErrorDetails(
                "unauthorized",
                "Authentication is required")));
        }

        var user = await authService.GetCurrentUserAsync(userId.Value, cancellationToken);
        if (user is null)
        {
            return NotFound(new ErrorResponse(new ErrorDetails(
                "not_found",
                "Resource not found")));
        }

        return Ok(user);
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
