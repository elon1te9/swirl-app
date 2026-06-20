namespace Swirl.Api.Responses;

public class LevelResponse
{
    public int Id { get; set; }

    public int SectionId { get; set; }

    public string Title { get; set; } = string.Empty;

    public int LevelNumber { get; set; }

    public string CefrLevel { get; set; } = string.Empty;

    public string? Description { get; set; }

    public int WordsCount { get; set; }

    public int ExercisesCount { get; set; }

    public bool IsFinalTest { get; set; }

    public string Status { get; set; } = string.Empty;

    public DateTime? CompletedAt { get; set; }
}
