namespace Swirl.Api.Responses;

public class LevelSessionResponse
{
    public int LevelId { get; set; }

    public string Title { get; set; } = string.Empty;

    public string SectionTitle { get; set; } = string.Empty;

    public bool IsFinalTest { get; set; }

    public List<ExerciseResponse> Exercises { get; set; } = [];
}
