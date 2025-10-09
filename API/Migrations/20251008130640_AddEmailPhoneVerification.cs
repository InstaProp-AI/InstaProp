using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertyFlipperAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddEmailPhoneVerification : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "EmailVerificationPin",
                table: "Accounts",
                type: "TEXT",
                maxLength: 6,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "EmailVerificationPinExpiry",
                table: "Accounts",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "EmailVerified",
                table: "Accounts",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "PhoneVerificationPin",
                table: "Accounts",
                type: "TEXT",
                maxLength: 6,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "PhoneVerificationPinExpiry",
                table: "Accounts",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "PhoneVerified",
                table: "Accounts",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "PreviousEmail",
                table: "Accounts",
                type: "TEXT",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PreviousPhoneNumber",
                table: "Accounts",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "EmailVerificationPin",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "EmailVerificationPinExpiry",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "EmailVerified",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "PhoneVerificationPin",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "PhoneVerificationPinExpiry",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "PhoneVerified",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "PreviousEmail",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "PreviousPhoneNumber",
                table: "Accounts");
        }
    }
}
