using Microsoft.EntityFrameworkCore;
using FileManagementAPI.Models;

namespace FileManagementAPI.Data
{
    public class FileManagementDbContext : DbContext
    {
        public FileManagementDbContext(DbContextOptions<FileManagementDbContext> options) : base(options)
        {
        }

        public DbSet<FileEntity> Files { get; set; }
        public DbSet<TabEntity> Tabs { get; set; }
        public DbSet<CategoryEntity> Categories { get; set; }
        public DbSet<EmployeeEntity> Employees { get; set; }
        public DbSet<DepartmentEntity> Departments { get; set; }
        public DbSet<FileActionEntity> FileActions { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure FileEntity
            modelBuilder.Entity<FileEntity>(entity =>
            {
                entity.HasKey(e => e.FileId);
                entity.Property(e => e.FileId).HasDefaultValueSql("NEWID()");
                entity.Property(e => e.UploadDate).HasDefaultValueSql("GETDATE()");
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()");
                entity.Property(e => e.UpdatedAt).HasDefaultValueSql("GETDATE()");

                // Configure relationships
                entity.HasOne(e => e.Tab)
                      .WithMany(t => t.Files)
                      .HasForeignKey(e => e.TabId)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(e => e.Category)
                      .WithMany(c => c.Files)
                      .HasForeignKey(e => e.CategoryId)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(e => e.Employee)
                      .WithMany(emp => emp.Files)
                      .HasForeignKey(e => e.UploadedBy)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(e => e.Department)
                      .WithMany(d => d.Files)
                      .HasForeignKey(e => e.DepartmentId)
                      .OnDelete(DeleteBehavior.Restrict);
            });

            // Configure TabEntity
            modelBuilder.Entity<TabEntity>(entity =>
            {
                entity.HasKey(e => e.TabId);
                entity.HasIndex(e => e.TabCode).IsUnique();
                entity.HasIndex(e => e.IsActive);
            });

            // Configure CategoryEntity
            modelBuilder.Entity<CategoryEntity>(entity =>
            {
                entity.HasKey(e => e.CategoryId);
                entity.HasIndex(e => new { e.TabId, e.CategoryCode }).IsUnique();
                entity.HasIndex(e => e.IsActive);
            });

            // Configure EmployeeEntity
            modelBuilder.Entity<EmployeeEntity>(entity =>
            {
                entity.HasKey(e => e.EmployeeId);
                entity.HasIndex(e => e.EmployeeCode).IsUnique();
                entity.HasIndex(e => e.Email).IsUnique();
                entity.HasIndex(e => e.IsActive);

                entity.HasOne(e => e.Department)
                      .WithMany(d => d.Employees)
                      .HasForeignKey(e => e.DepartmentId)
                      .OnDelete(DeleteBehavior.Restrict);
            });

            // Configure DepartmentEntity
            modelBuilder.Entity<DepartmentEntity>(entity =>
            {
                entity.HasKey(e => e.DepartmentId);
                entity.HasIndex(e => e.DepartmentCode).IsUnique();
                entity.HasIndex(e => e.IsActive);
            });

            // Configure FileActionEntity
            modelBuilder.Entity<FileActionEntity>(entity =>
            {
                entity.HasKey(e => e.ActionId);
                entity.Property(e => e.ActionId).HasDefaultValueSql("NEWID()");
                entity.Property(e => e.ActionDate).HasDefaultValueSql("GETDATE()");

                entity.HasOne(e => e.File)
                      .WithMany()
                      .HasForeignKey(e => e.FileId)
                      .OnDelete(DeleteBehavior.Restrict);

                entity.HasOne(e => e.Employee)
                      .WithMany()
                      .HasForeignKey(e => e.PerformedBy)
                      .OnDelete(DeleteBehavior.Restrict);

                // Check constraint for action_type
                entity.HasCheckConstraint("CK_file_actions_action_type", 
                    "[action_type] IN ('UPLOAD', 'DOWNLOAD', 'DELETE', 'UPDATE', 'VIEW', 'ACTIVATE', 'DEACTIVATE')");
            });

            // Configure indexes for performance
            modelBuilder.Entity<FileEntity>()
                .HasIndex(e => e.TabId)
                .HasDatabaseName("IX_files_tab_id");

            modelBuilder.Entity<FileEntity>()
                .HasIndex(e => e.CategoryId)
                .HasDatabaseName("IX_files_category_id");

            modelBuilder.Entity<FileEntity>()
                .HasIndex(e => e.UploadedBy)
                .HasDatabaseName("IX_files_uploaded_by");

            modelBuilder.Entity<FileEntity>()
                .HasIndex(e => e.DepartmentId)
                .HasDatabaseName("IX_files_department_id");

            modelBuilder.Entity<FileEntity>()
                .HasIndex(e => e.UploadDate)
                .HasDatabaseName("IX_files_upload_date");

            modelBuilder.Entity<FileEntity>()
                .HasIndex(e => e.FileName)
                .HasDatabaseName("IX_files_file_name");

            modelBuilder.Entity<FileEntity>()
                .HasIndex(e => e.IsActive)
                .HasDatabaseName("IX_files_is_active");

            modelBuilder.Entity<FileEntity>()
                .HasIndex(e => e.IsDeleted)
                .HasDatabaseName("IX_files_is_deleted");

            modelBuilder.Entity<FileActionEntity>()
                .HasIndex(e => e.FileId)
                .HasDatabaseName("IX_file_actions_file_id");

            modelBuilder.Entity<FileActionEntity>()
                .HasIndex(e => e.PerformedBy)
                .HasDatabaseName("IX_file_actions_performed_by");

            modelBuilder.Entity<FileActionEntity>()
                .HasIndex(e => e.ActionDate)
                .HasDatabaseName("IX_file_actions_action_date");

            modelBuilder.Entity<FileActionEntity>()
                .HasIndex(e => e.ActionType)
                .HasDatabaseName("IX_file_actions_action_type");
        }
    }
}
