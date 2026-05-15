using System.ComponentModel.DataAnnotations;

namespace Swirl.Api.Requests;

public class CompleteLevelRequest
{
    [Required]
    [MinLength(1, ErrorMessage = "Answers are required")]
    public List<CompleteLevelAnswerRequest> Answers { get; set; } = [];
}

public class CompleteLevelAnswerRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Exercise id is required")]
    public int ExerciseId { get; set; }

    public string UserAnswer { get; set; } = string.Empty;

    public bool? IsCorrect { get; set; }

    public int? TimeSpentMs { get; set; }
}
