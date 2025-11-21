using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddDeveloperPermissions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "DeveloperPermissions",
                columns: table => new
                {
                    DeveloperPermissionId = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    DeveloperId = table.Column<long>(type: "bigint", nullable: false),
                    FeatureName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    IsEnabled = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeveloperPermissions", x => x.DeveloperPermissionId);
                    table.ForeignKey(
                        name: "FK_DeveloperPermissions_Accounts_DeveloperId",
                        column: x => x.DeveloperId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DeveloperPermissions_DeveloperId_FeatureName",
                table: "DeveloperPermissions",
                columns: new[] { "DeveloperId", "FeatureName" },
                unique: true);

            // Seed default permissions for existing developers (all optional features disabled)
            migrationBuilder.Sql(@"
                INSERT INTO ""DeveloperPermissions"" (""DeveloperId"", ""FeatureName"", ""IsEnabled"", ""CreatedAt"")
                SELECT 
                    a.""AccountId"",
                    feature_name,
                    false,
                    NOW()
                FROM 
                    ""Accounts"" a
                CROSS JOIN UNNEST(ARRAY['Communities', 'News', 'Auctions', 'Leaderboard', 'Notifications', 'PriceHistory', 'FullAnalytics', 'Rewards', 'Valuation', 'Chats']) AS feature_name
                WHERE 
                    a.""RoleId"" = 7823647823647823
                ON CONFLICT DO NOTHING;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DeveloperPermissions");
        }
    }
}
