using Microsoft.Extensions.FileProviders;
using Microsoft.EntityFrameworkCore;
using Swirl.Api.Data;

var builder = WebApplication.CreateBuilder(args);

const string FlutterDevelopmentCorsPolicy = "FlutterDevelopment";

var corsOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
var mediaRootPathSetting = builder.Configuration["Media:RootPath"] ?? "wwwroot/media";
var mediaRequestPath = builder.Configuration["Media:RequestPath"] ?? "/media";
var mediaRootPath = Path.Combine(builder.Environment.ContentRootPath, mediaRootPathSetting);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddCors(options =>
{
    options.AddPolicy(FlutterDevelopmentCorsPolicy, policy =>
    {
        if (corsOrigins.Length == 0)
        {
            return;
        }

        policy
            .WithOrigins(corsOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(mediaRootPath),
    RequestPath = mediaRequestPath
});
app.UseCors(FlutterDevelopmentCorsPolicy);
app.UseAuthorization();
app.MapControllers();

app.Run();
