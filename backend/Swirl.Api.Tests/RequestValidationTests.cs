using System.ComponentModel.DataAnnotations;
using Swirl.Api.Requests;

namespace Swirl.Api.Tests;

public class RequestValidationTests
{
    [Fact]
    public void ChangeAvatarRequest_RejectsMissingAvatarId()
    {
        var errors = Validate(new ChangeAvatarRequest());

        Assert.Contains(errors, error => HasMember(error, nameof(ChangeAvatarRequest.AvatarId)));
    }

    [Fact]
    public void MarkLevelWordsLearnedRequest_RejectsEmptyWordIds()
    {
        var errors = Validate(new MarkLevelWordsLearnedRequest());

        Assert.Contains(errors, error => HasMember(error, nameof(MarkLevelWordsLearnedRequest.WordIds)));
    }

    [Fact]
    public void CompleteLevelRequest_RejectsEmptyAnswers()
    {
        var errors = Validate(new CompleteLevelRequest());

        Assert.Contains(errors, error => HasMember(error, nameof(CompleteLevelRequest.Answers)));
    }

    [Fact]
    public void CompleteLevelAnswerRequest_RejectsMissingExerciseId()
    {
        var errors = Validate(new CompleteLevelAnswerRequest
        {
            UserAnswer = "apple"
        });

        Assert.Contains(errors, error => HasMember(error, nameof(CompleteLevelAnswerRequest.ExerciseId)));
    }

    [Fact]
    public void CompleteDailyTestRequest_RejectsEmptyAnswers()
    {
        var errors = Validate(new CompleteDailyTestRequest());

        Assert.Contains(errors, error => HasMember(error, nameof(CompleteDailyTestRequest.Answers)));
    }

    [Fact]
    public void CompleteDailyTestAnswerRequest_RejectsMissingWordIdAndExerciseType()
    {
        var errors = Validate(new CompleteDailyTestAnswerRequest
        {
            UserAnswer = "apple"
        });

        Assert.Contains(errors, error => HasMember(error, nameof(CompleteDailyTestAnswerRequest.WordId)));
        Assert.Contains(errors, error => HasMember(error, nameof(CompleteDailyTestAnswerRequest.ExerciseType)));
    }

    private static List<ValidationResult> Validate(object request)
    {
        var context = new ValidationContext(request);
        var results = new List<ValidationResult>();

        Validator.TryValidateObject(request, context, results, validateAllProperties: true);

        return results;
    }

    private static bool HasMember(ValidationResult result, string memberName) =>
        result.MemberNames.Contains(memberName);
}
