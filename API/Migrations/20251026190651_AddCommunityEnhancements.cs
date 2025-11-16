using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddCommunityEnhancements : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LastActivityAt",
                table: "Communities");

            migrationBuilder.AddColumn<DateTime>(
                name: "LastActivityAt",
                table: "CommunityPosts",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<double>(
                name: "TrendingScore",
                table: "CommunityPosts",
                type: "REAL",
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<int>(
                name: "ViewCount",
                table: "CommunityPosts",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "CommentCount",
                table: "Accounts",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastActiveAt",
                table: "Accounts",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "LikesReceived",
                table: "Accounts",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "PostCount",
                table: "Accounts",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "ReputationPoints",
                table: "Accounts",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "ShowInDirectory",
                table: "Accounts",
                type: "INTEGER",
                nullable: false,
                defaultValue: true);

            migrationBuilder.CreateTable(
                name: "CommentReactions",
                columns: table => new
                {
                    ReactionId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    CommentId = table.Column<long>(type: "INTEGER", nullable: false),
                    AccountId = table.Column<long>(type: "INTEGER", nullable: false),
                    ReactionType = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CommentReactions", x => x.ReactionId);
                    table.ForeignKey(
                        name: "FK_CommentReactions_Accounts_AccountId",
                        column: x => x.AccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CommentReactions_PostComments_CommentId",
                        column: x => x.CommentId,
                        principalTable: "PostComments",
                        principalColumn: "CommentId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PostBookmarks",
                columns: table => new
                {
                    BookmarkId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    PostId = table.Column<long>(type: "INTEGER", nullable: false),
                    AccountId = table.Column<long>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PostBookmarks", x => x.BookmarkId);
                    table.ForeignKey(
                        name: "FK_PostBookmarks_Accounts_AccountId",
                        column: x => x.AccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PostBookmarks_CommunityPosts_PostId",
                        column: x => x.PostId,
                        principalTable: "CommunityPosts",
                        principalColumn: "PostId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PostReactions",
                columns: table => new
                {
                    ReactionId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    PostId = table.Column<long>(type: "INTEGER", nullable: false),
                    AccountId = table.Column<long>(type: "INTEGER", nullable: false),
                    ReactionType = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PostReactions", x => x.ReactionId);
                    table.ForeignKey(
                        name: "FK_PostReactions_Accounts_AccountId",
                        column: x => x.AccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PostReactions_CommunityPosts_PostId",
                        column: x => x.PostId,
                        principalTable: "CommunityPosts",
                        principalColumn: "PostId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserAchievements",
                columns: table => new
                {
                    AchievementId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    AccountId = table.Column<long>(type: "INTEGER", nullable: false),
                    AchievementType = table.Column<int>(type: "INTEGER", nullable: false),
                    Title = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true),
                    EarnedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    PointsAwarded = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserAchievements", x => x.AchievementId);
                    table.ForeignKey(
                        name: "FK_UserAchievements_Accounts_AccountId",
                        column: x => x.AccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CommentReactions_AccountId",
                table: "CommentReactions",
                column: "AccountId");

            migrationBuilder.CreateIndex(
                name: "IX_CommentReactions_CommentId_AccountId_ReactionType",
                table: "CommentReactions",
                columns: new[] { "CommentId", "AccountId", "ReactionType" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PostBookmarks_AccountId",
                table: "PostBookmarks",
                column: "AccountId");

            migrationBuilder.CreateIndex(
                name: "IX_PostBookmarks_PostId_AccountId",
                table: "PostBookmarks",
                columns: new[] { "PostId", "AccountId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PostReactions_AccountId",
                table: "PostReactions",
                column: "AccountId");

            migrationBuilder.CreateIndex(
                name: "IX_PostReactions_PostId_AccountId_ReactionType",
                table: "PostReactions",
                columns: new[] { "PostId", "AccountId", "ReactionType" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserAchievements_AccountId",
                table: "UserAchievements",
                column: "AccountId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CommentReactions");

            migrationBuilder.DropTable(
                name: "PostBookmarks");

            migrationBuilder.DropTable(
                name: "PostReactions");

            migrationBuilder.DropTable(
                name: "UserAchievements");

            migrationBuilder.DropColumn(
                name: "LastActivityAt",
                table: "CommunityPosts");

            migrationBuilder.DropColumn(
                name: "TrendingScore",
                table: "CommunityPosts");

            migrationBuilder.DropColumn(
                name: "ViewCount",
                table: "CommunityPosts");

            migrationBuilder.DropColumn(
                name: "CommentCount",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "LastActiveAt",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "LikesReceived",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "PostCount",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "ReputationPoints",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "ShowInDirectory",
                table: "Accounts");

            migrationBuilder.AddColumn<DateTime>(
                name: "LastActivityAt",
                table: "Communities",
                type: "TEXT",
                nullable: true);
        }
    }
}
