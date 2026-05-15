namespace Swirl.Api.Requests;

public class CompleteLevelRequest
{
    public List<CompleteLevelAnswerRequest> Answers { get; set; } = [];
}

public class CompleteLevelAnswerRequest
{
    public int ExerciseId { get; set; }

    public string UserAnswer { get; set; } = string.Empty;

    public bool? IsCorrect { get; set; }

    public int? TimeSpentMs { get; set; }
}
