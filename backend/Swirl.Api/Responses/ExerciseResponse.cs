namespace Swirl.Api.Responses;

public class ExerciseResponse
{
    public int Id { get; set; }

    public string Type { get; set; } = string.Empty;

    public string? QuestionText { get; set; }

    public string? QuestionImageUrl { get; set; }

    public string? QuestionAudioUrl { get; set; }

    public string CorrectAnswer { get; set; } = string.Empty;

    public List<string> Options { get; set; } = [];
}
