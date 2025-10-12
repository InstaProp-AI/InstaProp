using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertyFlipperAPI.Migrations
{
    /// <inheritdoc />
    public partial class EfficientBulkNotifications : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsPublic",
                table: "Notifications");

            migrationBuilder.AlterColumn<long>(
                name: "UserId",
                table: "Notifications",
                type: "INTEGER",
                nullable: true,
                oldClrType: typeof(long),
                oldType: "INTEGER");

            migrationBuilder.AddColumn<string>(
                name: "ReadByUsers",
                table: "Notifications",
                type: "TEXT",
                maxLength: 5000,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Recipients",
                table: "Notifications",
                type: "TEXT",
                maxLength: 500,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ReadByUsers",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "Recipients",
                table: "Notifications");

            migrationBuilder.AlterColumn<long>(
                name: "UserId",
                table: "Notifications",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0L,
                oldClrType: typeof(long),
                oldType: "INTEGER",
                oldNullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsPublic",
                table: "Notifications",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);
        }
    }
}
