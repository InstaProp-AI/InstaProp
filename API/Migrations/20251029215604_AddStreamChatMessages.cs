using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddStreamChatMessages : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "StreamChatMessages",
                columns: table => new
                {
                    MessageId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    StreamId = table.Column<long>(type: "INTEGER", nullable: false),
                    UserId = table.Column<long>(type: "INTEGER", nullable: false),
                    Message = table.Column<string>(type: "TEXT", maxLength: 500, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StreamChatMessages", x => x.MessageId);
                    table.ForeignKey(
                        name: "FK_StreamChatMessages_Accounts_UserId",
                        column: x => x.UserId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_StreamChatMessages_LiveStreams_StreamId",
                        column: x => x.StreamId,
                        principalTable: "LiveStreams",
                        principalColumn: "StreamId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_StreamChatMessages_CreatedAt",
                table: "StreamChatMessages",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_StreamChatMessages_StreamId",
                table: "StreamChatMessages",
                column: "StreamId");

            migrationBuilder.CreateIndex(
                name: "IX_StreamChatMessages_UserId",
                table: "StreamChatMessages",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "StreamChatMessages");
        }
    }
}
