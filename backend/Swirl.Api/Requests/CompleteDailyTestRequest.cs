namespace Swirl.Api.Requests;

public class CompleteDailyTestRequest
{
    public List<CompleteDailyTestAnswerRequest> Answers { get; set; } = [];
}

public class CompleteDailyTestAnswerRequest
{
    public int WordId { get; set; }

    public string ExerciseType { get; set; } = string.Empty;

    public string UserAnswer { get; set; } = string.Empty;

    public bool IsCorrect { get; set; }
}
