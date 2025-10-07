using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertyFlipperAPI.Migrations
{
    /// <inheritdoc />
    public partial class RestructureAuctionStartAtAndPrice : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Step 1: Drop EndAt column
            migrationBuilder.DropColumn(
                name: "EndAt",
                table: "Auctions");

            // Step 2: Add new StartPrice column and copy old StartAt values to it
            migrationBuilder.AddColumn<decimal>(
                name: "StartPrice",
                table: "Auctions",
                type: "numeric(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.Sql("UPDATE \"Auctions\" SET \"StartPrice\" = \"StartAt\"");

            // Step 3: Drop old StartAt column
            migrationBuilder.DropColumn(
                name: "StartAt",
                table: "Auctions");

            // Step 4: Add new StartAt as DateTime
            migrationBuilder.AddColumn<DateTime>(
                name: "StartAt",
                table: "Auctions",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "NOW()");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "StartPrice",
                table: "Auctions");

            migrationBuilder.AlterColumn<decimal>(
                name: "StartAt",
                table: "Auctions",
                type: "numeric(18,2)",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone");

            migrationBuilder.AddColumn<DateTime>(
                name: "EndAt",
                table: "Auctions",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));
        }
    }
}
