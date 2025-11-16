using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddLeaderboardTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "WeeklyLeaderboardSnapshots",
                columns: table => new
                {
                    SnapshotId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    WeekStart = table.Column<DateTime>(type: "TEXT", nullable: false),
                    WeekEnd = table.Column<DateTime>(type: "TEXT", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    PayoutProcessed = table.Column<bool>(type: "INTEGER", nullable: false, defaultValue: false),
                    WinnerAccountId = table.Column<long>(type: "INTEGER", nullable: true),
                    WinnerPoints = table.Column<int>(type: "INTEGER", nullable: true),
                    SecondPlaceAccountId = table.Column<long>(type: "INTEGER", nullable: true),
                    SecondPlacePoints = table.Column<int>(type: "INTEGER", nullable: true),
                    ThirdPlaceAccountId = table.Column<long>(type: "INTEGER", nullable: true),
                    ThirdPlacePoints = table.Column<int>(type: "INTEGER", nullable: true),
                    HighlightHeadline = table.Column<string>(type: "TEXT", maxLength: 250, nullable: true),
                    HighlightSummary = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WeeklyLeaderboardSnapshots", x => x.SnapshotId);
                    table.ForeignKey(
                        name: "FK_WeeklyLeaderboardSnapshots_Accounts_SecondPlaceAccountId",
                        column: x => x.SecondPlaceAccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_WeeklyLeaderboardSnapshots_Accounts_ThirdPlaceAccountId",
                        column: x => x.ThirdPlaceAccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_WeeklyLeaderboardSnapshots_Accounts_WinnerAccountId",
                        column: x => x.WinnerAccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "LeaderboardStandings",
                columns: table => new
                {
                    StandingId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    SnapshotId = table.Column<long>(type: "INTEGER", nullable: true),
                    AccountId = table.Column<long>(type: "INTEGER", nullable: false),
                    Period = table.Column<int>(type: "INTEGER", nullable: false),
                    Rank = table.Column<int>(type: "INTEGER", nullable: false),
                    Points = table.Column<int>(type: "INTEGER", nullable: false),
                    CashbackAwarded = table.Column<decimal>(type: "decimal(18,2)", nullable: false, defaultValue: 0m),
                    EngagementScore = table.Column<double>(type: "REAL", nullable: true),
                    StreakWeeks = table.Column<int>(type: "INTEGER", nullable: false, defaultValue: 0),
                    RewardSummary = table.Column<string>(type: "TEXT", maxLength: 250, nullable: true),
                    ComputedAt = table.Column<DateTime>(type: "TEXT", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LeaderboardStandings", x => x.StandingId);
                    table.ForeignKey(
                        name: "FK_LeaderboardStandings_Accounts_AccountId",
                        column: x => x.AccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_LeaderboardStandings_WeeklyLeaderboardSnapshots_SnapshotId",
                        column: x => x.SnapshotId,
                        principalTable: "WeeklyLeaderboardSnapshots",
                        principalColumn: "SnapshotId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_LeaderboardStandings_AccountId_Period",
                table: "LeaderboardStandings",
                columns: new[] { "AccountId", "Period" });

            migrationBuilder.CreateIndex(
                name: "IX_LeaderboardStandings_Period_Rank",
                table: "LeaderboardStandings",
                columns: new[] { "Period", "Rank" });

            migrationBuilder.CreateIndex(
                name: "IX_LeaderboardStandings_SnapshotId",
                table: "LeaderboardStandings",
                column: "SnapshotId");

            migrationBuilder.CreateIndex(
                name: "IX_WeeklyLeaderboardSnapshots_PayoutProcessed",
                table: "WeeklyLeaderboardSnapshots",
                column: "PayoutProcessed");

            migrationBuilder.CreateIndex(
                name: "IX_WeeklyLeaderboardSnapshots_SecondPlaceAccountId",
                table: "WeeklyLeaderboardSnapshots",
                column: "SecondPlaceAccountId");

            migrationBuilder.CreateIndex(
                name: "IX_WeeklyLeaderboardSnapshots_ThirdPlaceAccountId",
                table: "WeeklyLeaderboardSnapshots",
                column: "ThirdPlaceAccountId");

            migrationBuilder.CreateIndex(
                name: "IX_WeeklyLeaderboardSnapshots_WeekStart_WeekEnd",
                table: "WeeklyLeaderboardSnapshots",
                columns: new[] { "WeekStart", "WeekEnd" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WeeklyLeaderboardSnapshots_WinnerAccountId",
                table: "WeeklyLeaderboardSnapshots",
                column: "WinnerAccountId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LeaderboardStandings");

            migrationBuilder.DropTable(
                name: "WeeklyLeaderboardSnapshots");
        }
    }
}


