using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swirl.Api.Interfaces;
using Swirl.Api.Requests;
using Swirl.Api.Responses;

namespace Swirl.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/levels")]
public class LevelsController(
    IContentService contentService,
    IWordLearningService wordLearningService,
    ILearningService learningService) : ControllerBase
{
    [HttpGet("{levelId:int}")]
    public async Task<ActionResult<LevelDetailsResponse>> GetLevel(
        int levelId,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized(new ErrorResponse(new ErrorDetails(
                "unauthorized",
                "Authentication is required")));
        }

        var level = await contentService.GetLevelAsync(userId.Value, levelId, cancellationToken);

        return level is null
            ? NotFound(new ErrorResponse(new ErrorDetails(
                "not_found",
                "Resource not found")))
            : Ok(level);
    }

    [HttpGet("{levelId:int}/words")]
    public async Task<ActionResult<List<WordResponse>>> GetLevelWords(
        int levelId,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return CreateUnauthorizedResult();
        }

        return Ok(await wordLearningService.GetLevelWordsAsync(
            userId.Value,
            levelId,
            cancellationToken));
    }

    [HttpPost("{levelId:int}/words/mark-learned")]
    public async Task<ActionResult<MarkLevelWordsLearnedResponse>> MarkLevelWordsLearned(
        int levelId,
        MarkLevelWordsLearnedRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return CreateUnauthorizedResult();
        }

        return Ok(await wordLearningService.MarkLevelWordsLearnedAsync(
            userId.Value,
            levelId,
            request,
            cancellationToken));
    }

    [HttpGet("{levelId:int}/session")]
    public async Task<ActionResult<LevelSessionResponse>> GetLevelSession(
        int levelId,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return CreateUnauthorizedResult();
        }

        return Ok(await learningService.GetLevelSessionAsync(
            userId.Value,
            levelId,
            cancellationToken));
    }

    [HttpPost("{levelId:int}/complete")]
    public async Task<ActionResult<CompleteLevelResponse>> CompleteLevel(
        int levelId,
        CompleteLevelRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return CreateUnauthorizedResult();
        }

        return Ok(await learningService.CompleteLevelAsync(
            userId.Value,
            levelId,
            request,
            cancellationToken));
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
}
