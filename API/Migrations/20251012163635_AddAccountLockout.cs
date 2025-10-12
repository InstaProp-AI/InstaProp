using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertyFlipperAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddAccountLockout : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "HashedPassword",
                table: "Accounts",
                type: "TEXT",
                maxLength: 255,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "TEXT",
                oldMaxLength: 255);

            migrationBuilder.AddColumn<string>(
                name: "AuthProvider",
                table: "Accounts",
                type: "TEXT",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "FailedLoginAttempts",
                table: "Accounts",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "GoogleId",
                table: "Accounts",
                type: "TEXT",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LockedUntil",
                table: "Accounts",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AuthProvider",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "FailedLoginAttempts",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "GoogleId",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "LockedUntil",
                table: "Accounts");

            migrationBuilder.AlterColumn<string>(
                name: "HashedPassword",
                table: "Accounts",
                type: "TEXT",
                maxLength: 255,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "TEXT",
                oldMaxLength: 255,
                oldNullable: true);
        }
    }
}
