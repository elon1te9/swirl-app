using System.ComponentModel.DataAnnotations;

namespace Swirl.Api.Requests;

public class CompleteDailyTestRequest
{
    [Required]
    [MinLength(1, ErrorMessage = "Answers are required")]
    public List<CompleteDailyTestAnswerRequest> Answers { get; set; } = [];
}

public class CompleteDailyTestAnswerRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Word id is required")]
    public int WordId { get; set; }

    [MinLength(1, ErrorMessage = "Exercise type is required")]
    public string ExerciseType { get; set; } = string.Empty;

    public string UserAnswer { get; set; } = string.Empty;

    public bool IsCorrect { get; set; }
}
