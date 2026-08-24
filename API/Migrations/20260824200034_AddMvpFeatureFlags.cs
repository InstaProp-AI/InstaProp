using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddMvpFeatureFlags : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "FeatureFlags",
                keyColumn: "FeatureFlagId",
                keyValue: new Guid("aa000001-0000-0000-0000-000000000002"),
                column: "IsEnabled",
                value: false);

            migrationBuilder.UpdateData(
                table: "FeatureFlags",
                keyColumn: "FeatureFlagId",
                keyValue: new Guid("aa000001-0000-0000-0000-000000000003"),
                column: "IsEnabled",
                value: false);

            migrationBuilder.UpdateData(
                table: "FeatureFlags",
                keyColumn: "FeatureFlagId",
                keyValue: new Guid("aa000001-0000-0000-0000-000000000004"),
                column: "IsEnabled",
                value: false);

            migrationBuilder.InsertData(
                table: "FeatureFlags",
                columns: new[] { "FeatureFlagId", "Description", "FeatureKey", "IsEnabled", "LastUpdatedAt", "UpdatedByAdminId" },
                values: new object[,]
                {
                    { new Guid("aa000001-0000-0000-0000-000000000011"), "Market tab in bottom navigation (MVP off)", "MarketTab", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000012"), "Portfolio analytics dashboard (MVP off)", "PortfolioAnalytics", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000013"), "Side-by-side property comparison (MVP off)", "PropertyComparison", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000014"), "Advanced property search (MVP off)", "PropertySearch", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000015"), "Developer profile pages (MVP off)", "DeveloperProfiles", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000016"), "User-developer chat (MVP off)", "Chat", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000017"), "Personal calendar and events (MVP off)", "CalendarEvents", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null },
                    { new Guid("aa000001-0000-0000-0000-000000000018"), "VIP-only auction access (MVP off)", "VIPAuctions", false, new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "FeatureFlags",
                keyColumn: "FeatureFlagId",
                keyValue: new Guid("aa000001-0000-0000-0000-000000000011"));

            migrationBuilder.DeleteData(
                table: "FeatureFlags",
                keyColumn: "FeatureFlagId",
                keyValue: new Guid("aa000001-0000-0000-0000-000000000012"));

            migrationBuilder.DeleteData(
                table: "FeatureFlags",
                keyColumn: "FeatureFlagId",
                keyValue: new Guid("aa000001-0000-0000-0000-000000000013"));

            migrationBuilder.DeleteData(
                table: "FeatureFlags",
                keyColumn: "FeatureFlagId",
                keyValue: new Guid("aa000001-0000-0000-0000-000000000014"));

            migrationBuilder.DeleteData(
                table: "FeatureFlags",
                keyColumn: "FeatureFlagId",
                keyValue: new Guid("aa000001-0000-0000-0000-000000000015"));

            migrationBuilder.DeleteData(
                table: "FeatureFlags",
                keyColumn: "FeatureFlagId",
                keyValue: new Guid("aa000001-0000-0000-0000-000000000016"));

            migrationBuilder.DeleteData(
                table: "FeatureFlags",
                keyColumn: "FeatureFlagId",
                keyValue: new Guid("aa000001-0000-0000-0000-000000000017"));

            migrationBuilder.DeleteData(
                table: "FeatureFlags",
                keyColumn: "FeatureFlagId",
                keyValue: new Guid("aa000001-0000-0000-0000-000000000018"));

            migrationBuilder.UpdateData(
                table: "FeatureFlags",
                keyColumn: "FeatureFlagId",
                keyValue: new Guid("aa000001-0000-0000-0000-000000000002"),
                column: "IsEnabled",
                value: true);

            migrationBuilder.UpdateData(
                table: "FeatureFlags",
                keyColumn: "FeatureFlagId",
                keyValue: new Guid("aa000001-0000-0000-0000-000000000003"),
                column: "IsEnabled",
                value: true);

            migrationBuilder.UpdateData(
                table: "FeatureFlags",
                keyColumn: "FeatureFlagId",
                keyValue: new Guid("aa000001-0000-0000-0000-000000000004"),
                column: "IsEnabled",
                value: true);
        }
    }
}
