using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddPropertyValuationTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "PropertyValuations",
                columns: table => new
                {
                    ValuationId = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    PropertyId = table.Column<int>(type: "INTEGER", nullable: false),
                    EstimatedValue = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Confidence = table.Column<decimal>(type: "decimal(5,2)", nullable: true),
                    CalculatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    ValuationSource = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    AIReasoning = table.Column<string>(type: "TEXT", maxLength: 2000, nullable: true),
                    ComparablesCount = table.Column<int>(type: "INTEGER", nullable: true),
                    PriceRangeLow = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    PriceRangeHigh = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    MarketTrends = table.Column<string>(type: "TEXT", maxLength: 1000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyValuations", x => x.ValuationId);
                    table.ForeignKey(
                        name: "FK_PropertyValuations_ChildProperties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "ChildProperties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PropertyValuations_PropertyId",
                table: "PropertyValuations",
                column: "PropertyId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PropertyValuations");
        }
    }
}
