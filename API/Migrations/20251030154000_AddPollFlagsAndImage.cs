using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace InstapropAPI.Migrations
{
    public partial class AddPollFlagsAndImage : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsMultipleChoice",
                table: "Polls",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "AllowChangeVote",
                table: "Polls",
                type: "INTEGER",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<bool>(
                name: "ShowResultsBeforeVote",
                table: "Polls",
                type: "INTEGER",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<string>(
                name: "ImageUrl",
                table: "Polls",
                type: "TEXT",
                maxLength: 500,
                nullable: true);

            // Drop old unique index and add new one including OptionIndex
            migrationBuilder.DropIndex(
                name: "IX_PollVotes_PollId_AccountId",
                table: "PollVotes");

            migrationBuilder.CreateIndex(
                name: "IX_PollVotes_PollId_AccountId_OptionIndex",
                table: "PollVotes",
                columns: new[] { "PollId", "AccountId", "OptionIndex" },
                unique: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_PollVotes_PollId_AccountId_OptionIndex",
                table: "PollVotes");

            migrationBuilder.CreateIndex(
                name: "IX_PollVotes_PollId_AccountId",
                table: "PollVotes",
                columns: new[] { "PollId", "AccountId" },
                unique: true);

            migrationBuilder.DropColumn(
                name: "IsMultipleChoice",
                table: "Polls");

            migrationBuilder.DropColumn(
                name: "AllowChangeVote",
                table: "Polls");

            migrationBuilder.DropColumn(
                name: "ShowResultsBeforeVote",
                table: "Polls");

            migrationBuilder.DropColumn(
                name: "ImageUrl",
                table: "Polls");
        }
    }
}
