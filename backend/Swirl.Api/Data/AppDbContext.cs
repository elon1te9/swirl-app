using Microsoft.EntityFrameworkCore;

namespace Swirl.Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
}
