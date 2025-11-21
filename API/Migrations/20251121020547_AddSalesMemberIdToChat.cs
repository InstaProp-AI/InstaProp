using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddSalesMemberIdToChat : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<long>(
                name: "SalesMemberId",
                table: "Chats",
                type: "bigint",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Chats_SalesMemberId",
                table: "Chats",
                column: "SalesMemberId");

            migrationBuilder.AddForeignKey(
                name: "FK_Chats_Accounts_SalesMemberId",
                table: "Chats",
                column: "SalesMemberId",
                principalTable: "Accounts",
                principalColumn: "AccountId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Chats_Accounts_SalesMemberId",
                table: "Chats");

            migrationBuilder.DropIndex(
                name: "IX_Chats_SalesMemberId",
                table: "Chats");

            migrationBuilder.DropColumn(
                name: "SalesMemberId",
                table: "Chats");
        }
    }
}
