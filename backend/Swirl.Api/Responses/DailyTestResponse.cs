using System.Text.Json.Serialization;

namespace Swirl.Api.Responses;

public class DailyTestResponse
{
    public DateOnly Date { get; set; }

    public bool IsAvailable { get; set; }

    public bool IsCompleted { get; set; }

    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public int? ExercisesCount { get; set; }

    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public List<DailyTestExerciseResponse>? Exercises { get; set; }

    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Reason { get; set; }
}

public class DailyTestExerciseResponse
{
    public int Id { get; set; }

    public int WordId { get; set; }

    public string Type { get; set; } = string.Empty;

    public string? QuestionText { get; set; }

    public string? QuestionImageUrl { get; set; }

    public string? QuestionAudioUrl { get; set; }

    public string CorrectAnswer { get; set; } = string.Empty;

    public List<string> Options { get; set; } = [];
}
