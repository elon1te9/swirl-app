using System.ComponentModel.DataAnnotations;

namespace Swirl.Api.Requests;

public class ChangeAvatarRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Avatar is required")]
    public int AvatarId { get; set; }
}
