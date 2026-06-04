using System.ComponentModel.DataAnnotations;

namespace Swirl.Api.Requests;

public class UpdateProfileRequest
{
    [Required(ErrorMessage = "Name is required")]
    [MaxLength(255, ErrorMessage = "Name is too long")]
    public string Name { get; set; } = string.Empty;

    [Range(1, int.MaxValue, ErrorMessage = "Avatar is required")]
    public int AvatarId { get; set; }
}
