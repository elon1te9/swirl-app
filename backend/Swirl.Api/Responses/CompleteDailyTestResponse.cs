namespace Swirl.Api.Responses;

public class CompleteDailyTestResponse
{
    public bool Completed { get; set; }

    public int CorrectAnswers { get; set; }

    public int TotalAnswers { get; set; }

    public int CurrentStreak { get; set; }

    public int BestStreak { get; set; }
}
