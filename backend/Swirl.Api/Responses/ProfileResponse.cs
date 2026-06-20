namespace Swirl.Api.Responses;

public class ProfileResponse
{
    public string Name { get; set; } = string.Empty;

    public string AvatarUrl { get; set; } = string.Empty;

    public int CurrentStreak { get; set; }

    public int BestStreak { get; set; }

    public DateOnly? LastActivityDate { get; set; }

    public int LearnedWordsCount { get; set; }

    public int CompletedLevelsCount { get; set; }

    public List<SectionProgressResponse> SectionsProgress { get; set; } = [];
}

public class SectionProgressResponse
{
    public int SectionId { get; set; }

    public string Title { get; set; } = string.Empty;

    public int ProgressPercent { get; set; }
}
