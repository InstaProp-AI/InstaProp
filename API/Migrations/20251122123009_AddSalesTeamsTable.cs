using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddSalesTeamsTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<long>(
                name: "SalesTeamId",
                table: "Accounts",
                type: "bigint",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "SalesTeams",
                columns: table => new
                {
                    TeamId = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    TeamName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    DeveloperId = table.Column<long>(type: "bigint", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SalesTeams", x => x.TeamId);
                    table.ForeignKey(
                        name: "FK_SalesTeams_Accounts_DeveloperId",
                        column: x => x.DeveloperId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Accounts_SalesTeamId",
                table: "Accounts",
                column: "SalesTeamId");

            migrationBuilder.CreateIndex(
                name: "IX_SalesTeams_DeveloperId",
                table: "SalesTeams",
                column: "DeveloperId");

            migrationBuilder.AddForeignKey(
                name: "FK_Accounts_SalesTeams_SalesTeamId",
                table: "Accounts",
                column: "SalesTeamId",
                principalTable: "SalesTeams",
                principalColumn: "TeamId",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Accounts_SalesTeams_SalesTeamId",
                table: "Accounts");

            migrationBuilder.DropTable(
                name: "SalesTeams");

            migrationBuilder.DropIndex(
                name: "IX_Accounts_SalesTeamId",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "SalesTeamId",
                table: "Accounts");
        }
    }
}
