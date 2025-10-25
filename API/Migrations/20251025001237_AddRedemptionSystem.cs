using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertyFlipperAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddRedemptionSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CurrentPoints",
                table: "Accounts",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "TotalEarnedPoints",
                table: "Accounts",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "Redemptions",
                columns: table => new
                {
                    RedemptionId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    AccountId = table.Column<long>(type: "INTEGER", nullable: false),
                    RewardType = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    PointsSpent = table.Column<int>(type: "INTEGER", nullable: false),
                    PromoCode = table.Column<string>(type: "TEXT", maxLength: 5, nullable: false),
                    IsUsed = table.Column<bool>(type: "INTEGER", nullable: false),
                    UsedAt = table.Column<DateTime>(type: "TEXT", nullable: true),
                    RedeemedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Redemptions", x => x.RedemptionId);
                    table.ForeignKey(
                        name: "FK_Redemptions_Accounts_AccountId",
                        column: x => x.AccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Redemptions_AccountId",
                table: "Redemptions",
                column: "AccountId");

            // Migrate existing points from UserRewards to new fields
            migrationBuilder.Sql(@"
                UPDATE Accounts 
                SET TotalEarnedPoints = (
                    SELECT COALESCE(SUM(Points), 0) 
                    FROM UserRewards 
                    WHERE UserRewards.AccountId = Accounts.AccountId
                ),
                CurrentPoints = (
                    SELECT COALESCE(SUM(Points), 0) 
                    FROM UserRewards 
                    WHERE UserRewards.AccountId = Accounts.AccountId
                )
                WHERE EXISTS (
                    SELECT 1 FROM UserRewards 
                    WHERE UserRewards.AccountId = Accounts.AccountId
                )");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Redemptions");

            migrationBuilder.DropColumn(
                name: "CurrentPoints",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "TotalEarnedPoints",
                table: "Accounts");
        }
    }
}
