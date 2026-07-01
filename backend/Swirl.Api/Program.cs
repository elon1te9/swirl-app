using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.FileProviders;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Swirl.Api.Data;
using Swirl.Api.Interfaces;
using Swirl.Api.Responses;
using Swirl.Api.Services;

var builder = WebApplication.CreateBuilder(args);

const string FlutterDevelopmentCorsPolicy = "FlutterDevelopment";

var corsOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
var mediaRootPathSetting = builder.Configuration["Media:RootPath"] ?? "wwwroot/media";
var mediaRequestPath = builder.Configuration["Media:RequestPath"] ?? "/media";
var mediaRootPath = Path.Combine(builder.Environment.ContentRootPath, mediaRootPathSetting);

builder.Services.AddControllers();
builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var details = context.ModelState
            .Where(entry => entry.Value?.Errors.Count > 0)
            .ToDictionary(
                entry => ToCamelCaseModelStateKey(entry.Key),
                entry => entry.Value!.Errors
                    .Select(error => string.IsNullOrWhiteSpace(error.ErrorMessage)
                        ? "Invalid value"
                        : error.ErrorMessage)
                    .ToArray());

        return new BadRequestObjectResult(new ErrorResponse(new ErrorDetails(
            "validation_error",
            "Validation failed",
            details)));
    };
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter a JWT Bearer token."
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

var jwtSecret = builder.Configuration["Jwt:Secret"];
if (string.IsNullOrWhiteSpace(jwtSecret))
{
    throw new InvalidOperationException("JWT secret is not configured.");
}

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "Swirl.Api",
            ValidateAudience = true,
            ValidAudience = builder.Configuration["Jwt:Audience"] ?? "Swirl.Android",
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1)
        };

        options.Events = new JwtBearerEvents
        {
            OnChallenge = async context =>
            {
                context.HandleResponse();
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                context.Response.ContentType = "application/json";

                await context.Response.WriteAsJsonAsync(new ErrorResponse(new ErrorDetails(
                    "unauthorized",
                    "Authentication is required")));
            },
            OnForbidden = async context =>
            {
                context.Response.StatusCode = StatusCodes.Status403Forbidden;
                context.Response.ContentType = "application/json";

                await context.Response.WriteAsJsonAsync(new ErrorResponse(new ErrorDetails(
                    "forbidden",
                    "You do not have access to this resource")));
            }
        };
    });

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IProfileService, ProfileService>();
builder.Services.AddScoped<IContentService, ContentService>();
builder.Services.AddScoped<IWordLearningService, WordLearningService>();
builder.Services.AddScoped<IStreakService, StreakService>();
builder.Services.AddScoped<IDailyTestService, DailyTestService>();
builder.Services.AddScoped<ILearningService, LearningService>();
builder.Services.AddSingleton<IJwtTokenService, JwtTokenService>();
builder.Services.AddSingleton<IPasswordHashService, PasswordHashService>();

builder.Services.AddCors(options =>
{
    options.AddPolicy(FlutterDevelopmentCorsPolicy, policy =>
    {
        if (builder.Environment.IsDevelopment())
        {
            policy
                .SetIsOriginAllowed(IsFlutterDevelopmentOrigin)
                .AllowAnyHeader()
                .AllowAnyMethod();
            return;
        }

        if (corsOrigins.Length > 0)
        {
            policy
                .WithOrigins(corsOrigins)
                .AllowAnyHeader()
                .AllowAnyMethod();
        }
    });
});

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await dbContext.Database.MigrateAsync();
    await DatabaseSeeder.SeedAsync(dbContext);
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        var exception = context.Features.Get<IExceptionHandlerFeature>()?.Error;
        var logger = context.RequestServices
            .GetRequiredService<ILoggerFactory>()
            .CreateLogger("ApiExceptionHandler");

        int statusCode;
        ErrorDetails error;

        if (exception is ApiException apiException)
        {
            statusCode = apiException.StatusCode;
            error = new ErrorDetails(apiException.Code, apiException.Message, apiException.Details);
        }
        else
        {
            statusCode = StatusCodes.Status500InternalServerError;
            error = new ErrorDetails("internal_error", "Something went wrong");
        }

        if (exception is not null and not ApiException)
        {
            logger.LogError(exception, "Unhandled API exception.");
        }

        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/json";

        await context.Response.WriteAsJsonAsync(new ErrorResponse(error));
    });
});

Directory.CreateDirectory(mediaRootPath);
app.UseHttpsRedirection();
app.UseCors(FlutterDevelopmentCorsPolicy);
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(mediaRootPath),
    RequestPath = mediaRequestPath
});
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

static string ToCamelCaseModelStateKey(string value)
{
    return string.Join('.', value
        .Split('.', StringSplitOptions.RemoveEmptyEntries)
        .Select(ToCamelCaseModelStateSegment));
}

static string ToCamelCaseModelStateSegment(string value)
{
    var bracketIndex = value.IndexOf('[');
    if (bracketIndex < 0)
    {
        return ToCamelCase(value);
    }

    return ToCamelCase(value[..bracketIndex]) + value[bracketIndex..];
}

static string ToCamelCase(string value)
{
    if (string.IsNullOrWhiteSpace(value))
    {
        return value;
    }

    return char.ToLowerInvariant(value[0]) + value[1..];
}

static bool IsFlutterDevelopmentOrigin(string origin)
{
    if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri))
    {
        return false;
    }

    if (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps)
    {
        return false;
    }

    return uri.IsLoopback || uri.Host == "10.0.2.2";
}
