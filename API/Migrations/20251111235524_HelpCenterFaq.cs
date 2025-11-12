using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace PropertyFlipperAPI.Migrations
{
    /// <inheritdoc />
    public partial class HelpCenterFaq : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Faqs",
                columns: table => new
                {
                    FaqId = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Question = table.Column<string>(type: "TEXT", maxLength: 250, nullable: false),
                    Answer = table.Column<string>(type: "TEXT", nullable: false),
                    DisplayOrder = table.Column<int>(type: "INTEGER", nullable: false, defaultValue: 0),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Faqs", x => x.FaqId);
                });

            migrationBuilder.InsertData(
                table: "Faqs",
                columns: new[] { "FaqId", "Answer", "CreatedAt", "DisplayOrder", "Question" },
                values: new object[,]
                {
                    { 1, "Go to the Add Property screen, fill out the mandatory fields, upload images, and submit for review.", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, "How do I list a new property?" },
                    { 2, "Yes, open the property from your dashboard and tap Edit. Changes trigger a short review cycle.", new DateTime(2025, 1, 1, 0, 1, 0, 0, DateTimeKind.Utc), 2, "Can I edit my property after submission?" },
                    { 3, "At minimum you need proof of ownership and unit floor plans. Optional docs speed up verification.", new DateTime(2025, 1, 1, 0, 2, 0, 0, DateTimeKind.Utc), 3, "What documents are required?" },
                    { 4, "Approved sellers can request an auction. Once approved, buyers place bids until the auction end date.", new DateTime(2025, 1, 1, 0, 3, 0, 0, DateTimeKind.Utc), 4, "How do auctions work?" },
                    { 5, "Pricing leverages market comps, developer data, and our AI valuation engine.", new DateTime(2025, 1, 1, 0, 4, 0, 0, DateTimeKind.Utc), 5, "How is property pricing estimated?" },
                    { 6, "Yes, tap the bookmark icon on any property to store it in your Saved list.", new DateTime(2025, 1, 1, 0, 5, 0, 0, DateTimeKind.Utc), 6, "Can I save favourite properties?" },
                    { 7, "Use the Contact Developer button on the project or property page to open a chat.", new DateTime(2025, 1, 1, 0, 6, 0, 0, DateTimeKind.Utc), 7, "How do I contact a developer?" },
                    { 8, "Our AI Broker suggests opportunities and answers investment questions in real time.", new DateTime(2025, 1, 1, 0, 7, 0, 0, DateTimeKind.Utc), 8, "What is the AI Broker?" },
                    { 9, "Follow projects to receive push notifications and see updates in your feed.", new DateTime(2025, 1, 1, 0, 8, 0, 0, DateTimeKind.Utc), 9, "How do I track project updates?" },
                    { 10, "Tap Forgot Password on the login screen and follow the emailed instructions.", new DateTime(2025, 1, 1, 0, 9, 0, 0, DateTimeKind.Utc), 10, "How can I reset my password?" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Faqs_DisplayOrder",
                table: "Faqs",
                column: "DisplayOrder");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Faqs");
        }
    }
}
