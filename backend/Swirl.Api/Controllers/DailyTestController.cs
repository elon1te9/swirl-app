using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swirl.Api.Interfaces;
using Swirl.Api.Requests;
using Swirl.Api.Responses;
using Swirl.Api.Services;

namespace Swirl.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/daily-test")]
public class DailyTestController(IDailyTestService dailyTestService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<DailyTestResponse>> GetDailyTest(CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return CreateUnauthorizedResult();
        }

        return Ok(await dailyTestService.GetDailyTestAsync(userId.Value, cancellationToken));
    }

    [HttpPost("complete")]
    public async Task<ActionResult<CompleteDailyTestResponse>> CompleteDailyTest(
        CompleteDailyTestRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return CreateUnauthorizedResult();
        }

        try
        {
            return Ok(await dailyTestService.CompleteDailyTestAsync(
                userId.Value,
                request,
                cancellationToken));
        }
        catch (ApiException exception)
        {
            return ToErrorResult(exception);
        }
    }

    private Guid? GetCurrentUserId()
    {
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        return Guid.TryParse(userIdValue, out var userId)
            ? userId
            : null;
    }

    private static UnauthorizedObjectResult CreateUnauthorizedResult() =>
        new(new ErrorResponse(new ErrorDetails(
            "unauthorized",
            "Authentication is required")));

    private ObjectResult ToErrorResult(ApiException exception) =>
        StatusCode(
            exception.StatusCode,
            new ErrorResponse(new ErrorDetails(
                exception.Code,
                exception.Message,
                exception.Details)));
}
