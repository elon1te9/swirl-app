namespace Swirl.Api.Responses;

public class CompleteLevelResponse
{
    public bool IsLevelCompleted { get; set; }

    public int MistakesCount { get; set; }

    public int? OpenedNextLevelId { get; set; }

    public int CurrentStreak { get; set; }

    public int BestStreak { get; set; }
}
