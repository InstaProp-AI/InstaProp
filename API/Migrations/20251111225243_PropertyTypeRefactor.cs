using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class PropertyTypeRefactor : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Category",
                table: "ChildProperties");

            migrationBuilder.DropColumn(
                name: "PropertyType",
                table: "ChildProperties");

            migrationBuilder.RenameColumn(
                name: "PropertyType",
                table: "ParentProperties",
                newName: "Type");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Type",
                table: "ParentProperties",
                newName: "PropertyType");

            migrationBuilder.AddColumn<string>(
                name: "Category",
                table: "ChildProperties",
                type: "TEXT",
                maxLength: 200,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "PropertyType",
                table: "ChildProperties",
                type: "TEXT",
                nullable: false,
                defaultValue: "");
        }
    }
}
