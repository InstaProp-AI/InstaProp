using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddLastActivityAtToCommunity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "LastActivityAt",
                table: "Communities",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LastActivityAt",
                table: "Communities");
        }
    }
}
