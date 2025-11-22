using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddDeveloperIdToNewsArticle : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<long>(
                name: "DeveloperId",
                table: "NewsArticles",
                type: "bigint",
                nullable: true);

            // Set existing news articles to null (admin posts)
            migrationBuilder.Sql("UPDATE \"NewsArticles\" SET \"DeveloperId\" = NULL WHERE \"DeveloperId\" IS NULL");

            migrationBuilder.CreateIndex(
                name: "IX_NewsArticles_DeveloperId",
                table: "NewsArticles",
                column: "DeveloperId");

            migrationBuilder.AddForeignKey(
                name: "FK_NewsArticles_Accounts_DeveloperId",
                table: "NewsArticles",
                column: "DeveloperId",
                principalTable: "Accounts",
                principalColumn: "AccountId",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_NewsArticles_Accounts_DeveloperId",
                table: "NewsArticles");

            migrationBuilder.DropIndex(
                name: "IX_NewsArticles_DeveloperId",
                table: "NewsArticles");

            migrationBuilder.DropColumn(
                name: "DeveloperId",
                table: "NewsArticles");
        }
    }
}
