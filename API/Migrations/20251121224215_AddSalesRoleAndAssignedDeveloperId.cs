using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddSalesRoleAndAssignedDeveloperId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Add Sales role
            migrationBuilder.InsertData(
                table: "Roles",
                columns: new[] { "RoleId", "RoleName", "Description", "CreatedAt" },
                values: new object[] { 6723546723546723L, "Sales", "Sales team member assigned to a developer", DateTime.UtcNow });

            migrationBuilder.AddColumn<long>(
                name: "AssignedDeveloperId",
                table: "Accounts",
                type: "bigint",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Accounts_AssignedDeveloperId",
                table: "Accounts",
                column: "AssignedDeveloperId");

            migrationBuilder.AddForeignKey(
                name: "FK_Accounts_Accounts_AssignedDeveloperId",
                table: "Accounts",
                column: "AssignedDeveloperId",
                principalTable: "Accounts",
                principalColumn: "AccountId",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Accounts_Accounts_AssignedDeveloperId",
                table: "Accounts");

            migrationBuilder.DropIndex(
                name: "IX_Accounts_AssignedDeveloperId",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "AssignedDeveloperId",
                table: "Accounts");

            // Remove Sales role
            migrationBuilder.DeleteData(
                table: "Roles",
                keyColumn: "RoleId",
                keyValue: 6723546723546723L);
        }
    }
}
