using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddWinPreservingPriceAndFeatureFlags : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "WinPreservingPrice",
                table: "Auctions",
                type: "numeric(18,2)",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "FeatureFlags",
                columns: table => new
                {
                    FeatureFlagId = table.Column<Guid>(type: "uuid", nullable: false),
                    FeatureKey = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    IsEnabled = table.Column<bool>(type: "boolean", nullable: false),
                    Description = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    LastUpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedByAdminId = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FeatureFlags", x => x.FeatureFlagId);
                });

            migrationBuilder.InsertData(
                table: "FeatureFlags",
                columns: new[] { "FeatureFlagId", "Description", "FeatureKey", "IsEnabled", "LastUpdatedAt", "UpdatedByAdminId" },
                values: new object[,]
                {
                    { new Guid("aa000001-0000-0000-0000-000000000001"), "Explore/Feed tab in bottom navigation", "FeedExplore", true, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000002"), "AI-powered payment schedule image scanner", "PaymentScheduleScanner", true, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000003"), "Points redemption for promo codes and rewards", "Redemptions", true, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000004"), "Property valuation tool", "Valuation", true, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000005"), "News articles section (Phase 2)", "News", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000006"), "Developer live streaming (Phase 2)", "LiveStreaming", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000007"), "Floating AI Broker chat button (Phase 2)", "AIBroker", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000008"), "Weekly leaderboard and cashback prizes (Phase 2)", "Leaderboard", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000009"), "Gold price vs property value comparison (Phase 2)", "GoldPriceComparison", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000010"), "Sales team management for developers (Phase 2)", "SalesTeams", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_CreatedAt",
                table: "Notifications",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_Auctions_Status",
                table: "Auctions",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_FeatureFlags_FeatureKey",
                table: "FeatureFlags",
                column: "FeatureKey",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "FeatureFlags");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_CreatedAt",
                table: "Notifications");

            migrationBuilder.DropIndex(
                name: "IX_Auctions_Status",
                table: "Auctions");

            migrationBuilder.DropColumn(
                name: "WinPreservingPrice",
                table: "Auctions");
        }
    }
}
