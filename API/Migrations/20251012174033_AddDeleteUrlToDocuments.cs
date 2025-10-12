using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertyFlipperAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddDeleteUrlToDocuments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DeleteUrl",
                table: "UserDocs",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DeleteUrl",
                table: "PropertyImages",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DeleteUrl",
                table: "PropertyDocs",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeleteUrl",
                table: "UserDocs");

            migrationBuilder.DropColumn(
                name: "DeleteUrl",
                table: "PropertyImages");

            migrationBuilder.DropColumn(
                name: "DeleteUrl",
                table: "PropertyDocs");
        }
    }
}
