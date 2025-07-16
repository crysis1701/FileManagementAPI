using Microsoft.EntityFrameworkCore;
using Minio;
using FileManagementAPI.Data;
using FileManagementAPI.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();

// Add Entity Framework
builder.Services.AddDbContext<FileManagementDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Add MinIO client
builder.Services.AddSingleton<IMinioClient>(provider =>
{
    var config = provider.GetRequiredService<IConfiguration>();
    return new MinioClient()
        .WithEndpoint(config["MinIO:Endpoint"])
        .WithCredentials(config["MinIO:AccessKey"], config["MinIO:SecretKey"])
        .WithSSL(config.GetValue<bool>("MinIO:UseSSL", false))
        .Build();
});

// Add custom services
builder.Services.AddScoped<IMinioService, MinioService>();
builder.Services.AddScoped<IFileValidationService, FileValidationService>();
builder.Services.AddScoped<IFileUploadService, FileUploadService>();

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
    {
        builder.AllowAnyOrigin()
               .AllowAnyMethod()
               .AllowAnyHeader();
    });
});

// Add Swagger/OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "File Management API",
        Version = "v1",
        Description = "API for file management system with MinIO integration"
    });
});

// Configure logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.UseAuthorization();
app.MapControllers();

// Add health check endpoint
app.MapGet("/health", () => new { status = "healthy", timestamp = DateTime.UtcNow });

// Add file upload size limit middleware
app.Use(async (context, next) =>
{
    if (context.Request.Path.StartsWithSegments("/api/files/upload"))
    {
        context.Request.EnableBuffering();
    }
    await next();
});

app.Run();
