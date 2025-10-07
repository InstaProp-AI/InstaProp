using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertyFlipperAPI.Migrations
{
    /// <inheritdoc />
    public partial class ConsolidatePropertyStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Step 1: Add Status column with default value
            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "Properties",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            // Step 2: Migrate existing data
            // Properties with both IsVerified=true AND IsApproved=true → Approved (Status = 2)
            migrationBuilder.Sql(@"
                UPDATE ""Properties"" 
                SET ""Status"" = 2 
                WHERE ""IsVerified"" = true AND ""IsApproved"" = true;
            ");

            // Properties with documents but not fully approved → Pending (Status = 1)
            migrationBuilder.Sql(@"
                UPDATE ""Properties"" 
                SET ""Status"" = 1 
                WHERE ""PropertyId"" IN (
                    SELECT DISTINCT ""PropertyId"" FROM ""PropertyDocs""
                ) AND ""Status"" = 0;
            ");

            // All others remain NotApproved (Status = 0) - already set by default

            // Step 3: Drop old columns
            migrationBuilder.DropColumn(
                name: "IsApproved",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "IsEditable",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "IsVerified",
                table: "Properties");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Status",
                table: "Properties");

            migrationBuilder.AddColumn<bool>(
                name: "IsApproved",
                table: "Properties",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsEditable",
                table: "Properties",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsVerified",
                table: "Properties",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }
    }
}
