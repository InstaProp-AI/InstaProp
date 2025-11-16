using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddLiveStreamFeature : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "LiveStreams",
                columns: table => new
                {
                    StreamId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    DeveloperId = table.Column<long>(type: "INTEGER", nullable: false),
                    Title = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "TEXT", nullable: true),
                    StreamUrl = table.Column<string>(type: "TEXT", maxLength: 500, nullable: false),
                    ThumbnailUrl = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true),
                    Status = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    ViewerCount = table.Column<int>(type: "INTEGER", nullable: false),
                    StartTime = table.Column<DateTime>(type: "TEXT", nullable: false),
                    EndTime = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LiveStreams", x => x.StreamId);
                    table.ForeignKey(
                        name: "FK_LiveStreams_Accounts_DeveloperId",
                        column: x => x.DeveloperId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StreamViewers",
                columns: table => new
                {
                    ViewerId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    StreamId = table.Column<long>(type: "INTEGER", nullable: false),
                    UserId = table.Column<long>(type: "INTEGER", nullable: false),
                    JoinedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    LeftAt = table.Column<DateTime>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StreamViewers", x => x.ViewerId);
                    table.ForeignKey(
                        name: "FK_StreamViewers_Accounts_UserId",
                        column: x => x.UserId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_StreamViewers_LiveStreams_StreamId",
                        column: x => x.StreamId,
                        principalTable: "LiveStreams",
                        principalColumn: "StreamId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_LiveStreams_DeveloperId",
                table: "LiveStreams",
                column: "DeveloperId");

            migrationBuilder.CreateIndex(
                name: "IX_StreamViewers_StreamId_UserId",
                table: "StreamViewers",
                columns: new[] { "StreamId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_StreamViewers_UserId",
                table: "StreamViewers",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "StreamViewers");

            migrationBuilder.DropTable(
                name: "LiveStreams");
        }
    }
}
