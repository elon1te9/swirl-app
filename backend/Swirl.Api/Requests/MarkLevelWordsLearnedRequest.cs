using System.ComponentModel.DataAnnotations;

namespace Swirl.Api.Requests;

public class MarkLevelWordsLearnedRequest
{
    [Required]
    [MinLength(1, ErrorMessage = "Word ids are required")]
    public List<int> WordIds { get; set; } = [];
}
