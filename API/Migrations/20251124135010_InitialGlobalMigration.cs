using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace InstapropAPI.Migrations
{
    /// <inheritdoc />
    public partial class InitialGlobalMigration : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Faqs",
                columns: table => new
                {
                    FaqId = table.Column<Guid>(type: "uuid", nullable: false),
                    Question = table.Column<string>(type: "character varying(250)", maxLength: 250, nullable: false),
                    Answer = table.Column<string>(type: "text", nullable: false),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Faqs", x => x.FaqId);
                });

            migrationBuilder.CreateTable(
                name: "GoldPrices",
                columns: table => new
                {
                    GoldPriceId = table.Column<Guid>(type: "uuid", nullable: false),
                    PricePerGram = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    Month = table.Column<int>(type: "integer", nullable: false),
                    Year = table.Column<int>(type: "integer", nullable: false),
                    Date = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Source = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GoldPrices", x => x.GoldPriceId);
                });

            migrationBuilder.CreateTable(
                name: "Roles",
                columns: table => new
                {
                    RoleId = table.Column<Guid>(type: "uuid", nullable: false),
                    RoleName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Roles", x => x.RoleId);
                });

            migrationBuilder.CreateTable(
                name: "Accounts",
                columns: table => new
                {
                    AccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    FirstName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    LastName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    PhoneNumber = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    RoleId = table.Column<Guid>(type: "uuid", nullable: false),
                    HashedPassword = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    EmailVerified = table.Column<bool>(type: "boolean", nullable: false),
                    PhoneVerified = table.Column<bool>(type: "boolean", nullable: false),
                    EmailVerificationPin = table.Column<string>(type: "character varying(6)", maxLength: 6, nullable: true),
                    PhoneVerificationPin = table.Column<string>(type: "character varying(6)", maxLength: 6, nullable: true),
                    EmailVerificationPinExpiry = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PhoneVerificationPinExpiry = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    RequiresPasswordChange = table.Column<bool>(type: "boolean", nullable: false),
                    PasswordResetRequestedEmail = table.Column<string>(type: "text", nullable: true),
                    PasswordResetTokenExpiry = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PreviousEmail = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    PreviousPhoneNumber = table.Column<string>(type: "text", nullable: true),
                    IsSuspended = table.Column<bool>(type: "boolean", nullable: false),
                    SuspendedUntil = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    SuspensionReason = table.Column<string>(type: "text", nullable: true),
                    FailedLoginAttempts = table.Column<int>(type: "integer", nullable: false),
                    LockedUntil = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    TimeZone = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    TotalEarnedPoints = table.Column<int>(type: "integer", nullable: false),
                    CurrentPoints = table.Column<int>(type: "integer", nullable: false),
                    AccountType = table.Column<string>(type: "character varying(13)", maxLength: 13, nullable: false),
                    RoleId1 = table.Column<Guid>(type: "uuid", nullable: true),
                    AssignedDeveloperId = table.Column<Guid>(type: "uuid", nullable: true),
                    SalesTeamId = table.Column<Guid>(type: "uuid", nullable: true),
                    GoogleId = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    AuthProvider = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Accounts", x => x.AccountId);
                    table.ForeignKey(
                        name: "FK_Accounts_Accounts_AssignedDeveloperId",
                        column: x => x.AssignedDeveloperId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Accounts_Roles_RoleId",
                        column: x => x.RoleId,
                        principalTable: "Roles",
                        principalColumn: "RoleId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Accounts_Roles_RoleId1",
                        column: x => x.RoleId1,
                        principalTable: "Roles",
                        principalColumn: "RoleId");
                });

            migrationBuilder.CreateTable(
                name: "AIChats",
                columns: table => new
                {
                    AIChatId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    StartedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    UserPreferences = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AIChats", x => x.AIChatId);
                    table.ForeignKey(
                        name: "FK_AIChats_Accounts_UserId",
                        column: x => x.UserId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "DeveloperPermissions",
                columns: table => new
                {
                    DeveloperPermissionId = table.Column<Guid>(type: "uuid", nullable: false),
                    DeveloperId = table.Column<Guid>(type: "uuid", nullable: false),
                    FeatureName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    IsEnabled = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeveloperPermissions", x => x.DeveloperPermissionId);
                    table.ForeignKey(
                        name: "FK_DeveloperPermissions_Accounts_DeveloperId",
                        column: x => x.DeveloperId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "DeveloperProfiles",
                columns: table => new
                {
                    ProfileId = table.Column<Guid>(type: "uuid", nullable: false),
                    AccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    Bio = table.Column<string>(type: "text", nullable: true),
                    CompanyName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    ProfileImageUrl = table.Column<string>(type: "text", nullable: true),
                    Rating = table.Column<decimal>(type: "numeric(3,2)", nullable: false),
                    TotalRatings = table.Column<int>(type: "integer", nullable: false),
                    PortfolioDescription = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeveloperProfiles", x => x.ProfileId);
                    table.ForeignKey(
                        name: "FK_DeveloperProfiles_Accounts_AccountId",
                        column: x => x.AccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "DeveloperRatings",
                columns: table => new
                {
                    RatingId = table.Column<Guid>(type: "uuid", nullable: false),
                    DeveloperId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Rating = table.Column<int>(type: "integer", nullable: false),
                    Comment = table.Column<string>(type: "text", nullable: true),
                    RatingType = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeveloperRatings", x => x.RatingId);
                    table.ForeignKey(
                        name: "FK_DeveloperRatings_Accounts_DeveloperId",
                        column: x => x.DeveloperId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_DeveloperRatings_Accounts_UserId",
                        column: x => x.UserId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Events",
                columns: table => new
                {
                    EventId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    EventDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    Location = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    IsAllDay = table.Column<bool>(type: "boolean", nullable: false),
                    StartTime = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    EndTime = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsCompleted = table.Column<bool>(type: "boolean", nullable: false),
                    IsReminderSet = table.Column<bool>(type: "boolean", nullable: false),
                    ReminderMinutes = table.Column<int>(type: "integer", nullable: true),
                    IsPublic = table.Column<bool>(type: "boolean", nullable: false),
                    IsRecurring = table.Column<bool>(type: "boolean", nullable: false),
                    RecurrencePattern = table.Column<int>(type: "integer", nullable: true),
                    RecurrenceInterval = table.Column<int>(type: "integer", nullable: true),
                    RecurrenceEndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    RecurrenceCount = table.Column<int>(type: "integer", nullable: true),
                    ParentEventId = table.Column<Guid>(type: "uuid", nullable: true),
                    Amount = table.Column<decimal>(type: "numeric", nullable: true),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: true),
                    AuctionId = table.Column<Guid>(type: "uuid", nullable: true),
                    BidId = table.Column<Guid>(type: "uuid", nullable: true),
                    ScheduleImageUrl = table.Column<string>(type: "text", nullable: true),
                    ScheduleGroupId = table.Column<string>(type: "text", nullable: true),
                    ScheduleBuyingPrice = table.Column<decimal>(type: "numeric", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Events", x => x.EventId);
                    table.ForeignKey(
                        name: "FK_Events_Accounts_UserId",
                        column: x => x.UserId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LiveStreams",
                columns: table => new
                {
                    StreamId = table.Column<Guid>(type: "uuid", nullable: false),
                    DeveloperId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    StreamUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    ThumbnailUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    ViewerCount = table.Column<int>(type: "integer", nullable: false),
                    StartTime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndTime = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
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
                name: "NewsArticles",
                columns: table => new
                {
                    NewsArticleId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Content = table.Column<string>(type: "text", nullable: false),
                    Category = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    PublishedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsPublished = table.Column<bool>(type: "boolean", nullable: false),
                    DeveloperId = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NewsArticles", x => x.NewsArticleId);
                    table.ForeignKey(
                        name: "FK_NewsArticles_Accounts_DeveloperId",
                        column: x => x.DeveloperId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "Notifications",
                columns: table => new
                {
                    NotificationId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    Title = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Message = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    IsRead = table.Column<bool>(type: "boolean", nullable: false),
                    Recipients = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    ReadByUsers = table.Column<string>(type: "character varying(5000)", maxLength: 5000, nullable: true),
                    AuctionId = table.Column<Guid>(type: "uuid", nullable: true),
                    BidId = table.Column<Guid>(type: "uuid", nullable: true),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: true),
                    EventId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ReadAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Notifications", x => x.NotificationId);
                    table.ForeignKey(
                        name: "FK_Notifications_Accounts_UserId",
                        column: x => x.UserId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Projects",
                columns: table => new
                {
                    ProjectId = table.Column<Guid>(type: "uuid", nullable: false),
                    DeveloperId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    Location = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    Country = table.Column<string>(type: "character varying(2)", maxLength: 2, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    AdminAccountAccountId = table.Column<Guid>(type: "uuid", nullable: true),
                    SalesAccountAccountId = table.Column<Guid>(type: "uuid", nullable: true),
                    UserAccountAccountId = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Projects", x => x.ProjectId);
                    table.ForeignKey(
                        name: "FK_Projects_Accounts_AdminAccountAccountId",
                        column: x => x.AdminAccountAccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId");
                    table.ForeignKey(
                        name: "FK_Projects_Accounts_DeveloperId",
                        column: x => x.DeveloperId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Projects_Accounts_SalesAccountAccountId",
                        column: x => x.SalesAccountAccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId");
                    table.ForeignKey(
                        name: "FK_Projects_Accounts_UserAccountAccountId",
                        column: x => x.UserAccountAccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId");
                });

            migrationBuilder.CreateTable(
                name: "Redemptions",
                columns: table => new
                {
                    RedemptionId = table.Column<Guid>(type: "uuid", nullable: false),
                    AccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    RewardType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    PointsSpent = table.Column<int>(type: "integer", nullable: false),
                    PromoCode = table.Column<string>(type: "character varying(5)", maxLength: 5, nullable: false),
                    IsUsed = table.Column<bool>(type: "boolean", nullable: false),
                    UsedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    RedeemedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
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

            migrationBuilder.CreateTable(
                name: "Referrals",
                columns: table => new
                {
                    ReferralId = table.Column<Guid>(type: "uuid", nullable: false),
                    ReferrerId = table.Column<Guid>(type: "uuid", nullable: false),
                    ReferredUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    ReferralCode = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    IsConverted = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ConvertedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Referrals", x => x.ReferralId);
                    table.ForeignKey(
                        name: "FK_Referrals_Accounts_ReferredUserId",
                        column: x => x.ReferredUserId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_Referrals_Accounts_ReferrerId",
                        column: x => x.ReferrerId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SalesTeams",
                columns: table => new
                {
                    TeamId = table.Column<Guid>(type: "uuid", nullable: false),
                    TeamName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    DeveloperId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SalesTeams", x => x.TeamId);
                    table.ForeignKey(
                        name: "FK_SalesTeams_Accounts_DeveloperId",
                        column: x => x.DeveloperId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserAchievements",
                columns: table => new
                {
                    AchievementId = table.Column<Guid>(type: "uuid", nullable: false),
                    AccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    AchievementType = table.Column<int>(type: "integer", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    EarnedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    PointsAwarded = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserAchievements", x => x.AchievementId);
                    table.ForeignKey(
                        name: "FK_UserAchievements_Accounts_AccountId",
                        column: x => x.AccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserBadges",
                columns: table => new
                {
                    BadgeId = table.Column<Guid>(type: "uuid", nullable: false),
                    AccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    BadgeName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    BadgeIcon = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    AwardedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserBadges", x => x.BadgeId);
                    table.ForeignKey(
                        name: "FK_UserBadges_Accounts_AccountId",
                        column: x => x.AccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserDocs",
                columns: table => new
                {
                    DocId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    DocType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ImgUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    DeleteUrl = table.Column<string>(type: "text", nullable: true),
                    UploadedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserDocs", x => x.DocId);
                    table.ForeignKey(
                        name: "FK_UserDocs_Accounts_UserId",
                        column: x => x.UserId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserRewards",
                columns: table => new
                {
                    RewardId = table.Column<Guid>(type: "uuid", nullable: false),
                    AccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    Points = table.Column<int>(type: "integer", nullable: false),
                    RewardType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    RelatedPropertyId = table.Column<Guid>(type: "uuid", nullable: true),
                    EarnedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserRewards", x => x.RewardId);
                    table.ForeignKey(
                        name: "FK_UserRewards_Accounts_AccountId",
                        column: x => x.AccountId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "WeeklyLeaderboardSnapshots",
                columns: table => new
                {
                    SnapshotId = table.Column<Guid>(type: "uuid", nullable: false),
                    WeekStart = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    WeekEnd = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    PayoutProcessed = table.Column<bool>(type: "boolean", nullable: false),
                    WinnerAccountId = table.Column<Guid>(type: "uuid", nullable: true),
                    WinnerPoints = table.Column<int>(type: "integer", nullable: true),
                    SecondPlaceAccountId = table.Column<Guid>(type: "uuid", nullable: true),
                    SecondPlacePoints = table.Column<int>(type: "integer", nullable: true),
                    ThirdPlaceAccountId = table.Column<Guid>(type: "uuid", nullable: true),
                    ThirdPlacePoints = table.Column<int>(type: "integer", nullable: true),
                    HighlightHeadline = table.Column<string>(type: "character varying(250)", maxLength: 250, nullable: true),
                    HighlightSummary = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true)
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
                name: "AIChatMessages",
                columns: table => new
                {
                    MessageId = table.Column<Guid>(type: "uuid", nullable: false),
                    AIChatId = table.Column<Guid>(type: "uuid", nullable: false),
                    Role = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Content = table.Column<string>(type: "text", nullable: false),
                    MessageType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: true),
                    ProjectId = table.Column<Guid>(type: "uuid", nullable: true),
                    DeveloperId = table.Column<Guid>(type: "uuid", nullable: true),
                    Options = table.Column<string>(type: "text", nullable: true),
                    QuestionType = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AIChatMessages", x => x.MessageId);
                    table.ForeignKey(
                        name: "FK_AIChatMessages_AIChats_AIChatId",
                        column: x => x.AIChatId,
                        principalTable: "AIChats",
                        principalColumn: "AIChatId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StreamChatMessages",
                columns: table => new
                {
                    MessageId = table.Column<Guid>(type: "uuid", nullable: false),
                    StreamId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Message = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
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

            migrationBuilder.CreateTable(
                name: "StreamViewers",
                columns: table => new
                {
                    ViewerId = table.Column<Guid>(type: "uuid", nullable: false),
                    StreamId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    JoinedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    LeftAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
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

            migrationBuilder.CreateTable(
                name: "NewsImages",
                columns: table => new
                {
                    NewsImageId = table.Column<Guid>(type: "uuid", nullable: false),
                    NewsArticleId = table.Column<Guid>(type: "uuid", nullable: false),
                    ImageUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NewsImages", x => x.NewsImageId);
                    table.ForeignKey(
                        name: "FK_NewsImages_NewsArticles_NewsArticleId",
                        column: x => x.NewsArticleId,
                        principalTable: "NewsArticles",
                        principalColumn: "NewsArticleId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Chats",
                columns: table => new
                {
                    ChatId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    DeveloperId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    LastMessageAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsSupportChat = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    SalesMemberId = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Chats", x => x.ChatId);
                    table.ForeignKey(
                        name: "FK_Chats_Accounts_DeveloperId",
                        column: x => x.DeveloperId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Chats_Accounts_SalesMemberId",
                        column: x => x.SalesMemberId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId");
                    table.ForeignKey(
                        name: "FK_Chats_Accounts_UserId",
                        column: x => x.UserId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Chats_Projects_ProjectId",
                        column: x => x.ProjectId,
                        principalTable: "Projects",
                        principalColumn: "ProjectId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "ParentProperties",
                columns: table => new
                {
                    ParentPropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProjectName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Bedrooms = table.Column<int>(type: "integer", nullable: false),
                    Bathrooms = table.Column<int>(type: "integer", nullable: false),
                    AreaSqm = table.Column<int>(type: "integer", nullable: false),
                    Type = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    FinishingType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    HasPool = table.Column<bool>(type: "boolean", nullable: false),
                    HasGym = table.Column<bool>(type: "boolean", nullable: false),
                    HasSecurity = table.Column<bool>(type: "boolean", nullable: false),
                    HasParking = table.Column<bool>(type: "boolean", nullable: false),
                    HasGarden = table.Column<bool>(type: "boolean", nullable: false),
                    HasPlayground = table.Column<bool>(type: "boolean", nullable: false),
                    HasClubhouse = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ParentProperties", x => x.ParentPropertyId);
                    table.ForeignKey(
                        name: "FK_ParentProperties_Projects_ProjectId",
                        column: x => x.ProjectId,
                        principalTable: "Projects",
                        principalColumn: "ProjectId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "ProjectMilestones",
                columns: table => new
                {
                    MilestoneId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    TargetDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CompletedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CompletionPercentage = table.Column<int>(type: "integer", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProjectMilestones", x => x.MilestoneId);
                    table.ForeignKey(
                        name: "FK_ProjectMilestones_Projects_ProjectId",
                        column: x => x.ProjectId,
                        principalTable: "Projects",
                        principalColumn: "ProjectId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ProjectUpdates",
                columns: table => new
                {
                    UpdateId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Content = table.Column<string>(type: "text", nullable: false),
                    ImageUrl = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ProjectUpdates", x => x.UpdateId);
                    table.ForeignKey(
                        name: "FK_ProjectUpdates_Projects_ProjectId",
                        column: x => x.ProjectId,
                        principalTable: "Projects",
                        principalColumn: "ProjectId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LeaderboardStandings",
                columns: table => new
                {
                    StandingId = table.Column<Guid>(type: "uuid", nullable: false),
                    SnapshotId = table.Column<Guid>(type: "uuid", nullable: true),
                    AccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    Period = table.Column<int>(type: "integer", nullable: false),
                    Rank = table.Column<int>(type: "integer", nullable: false),
                    Points = table.Column<int>(type: "integer", nullable: false),
                    CashbackAwarded = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    EngagementScore = table.Column<double>(type: "double precision", nullable: true),
                    StreakWeeks = table.Column<int>(type: "integer", nullable: false),
                    RewardSummary = table.Column<string>(type: "character varying(250)", maxLength: 250, nullable: true),
                    ComputedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
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

            migrationBuilder.CreateTable(
                name: "ChildProperties",
                columns: table => new
                {
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    ParentPropertyId = table.Column<Guid>(type: "uuid", nullable: true),
                    OwnerId = table.Column<Guid>(type: "uuid", nullable: true),
                    Phase = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    FloorNumber = table.Column<int>(type: "integer", nullable: true),
                    UnitNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    ViewType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Orientation = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    DeliveryDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ParkingSlots = table.Column<int>(type: "integer", nullable: true),
                    HasStorageRoom = table.Column<bool>(type: "boolean", nullable: true),
                    BuyingPrice = table.Column<decimal>(type: "numeric(18,2)", nullable: true),
                    BuyingDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Quantity = table.Column<int>(type: "integer", nullable: false),
                    HasNannyRoom = table.Column<bool>(type: "boolean", nullable: true),
                    HasDriverRoom = table.Column<bool>(type: "boolean", nullable: true),
                    HasMaidRoom = table.Column<bool>(type: "boolean", nullable: true),
                    HasPrivatePool = table.Column<bool>(type: "boolean", nullable: true),
                    HasRoofAccess = table.Column<bool>(type: "boolean", nullable: true),
                    HasBalcony = table.Column<bool>(type: "boolean", nullable: true),
                    HasGarden = table.Column<bool>(type: "boolean", nullable: true),
                    HasClubhouse = table.Column<bool>(type: "boolean", nullable: true),
                    HasInfrastructure = table.Column<bool>(type: "boolean", nullable: true),
                    HasUndergroundParking = table.Column<bool>(type: "boolean", nullable: true),
                    HasMedicalCenter = table.Column<bool>(type: "boolean", nullable: true),
                    HasCommercialStrip = table.Column<bool>(type: "boolean", nullable: true),
                    HasBusinessHub = table.Column<bool>(type: "boolean", nullable: true),
                    HasOutdoorPools = table.Column<bool>(type: "boolean", nullable: true),
                    HasBicycleLanes = table.Column<bool>(type: "boolean", nullable: true),
                    HasJoggingTrail = table.Column<bool>(type: "boolean", nullable: true),
                    SmartHome = table.Column<bool>(type: "boolean", nullable: true),
                    CentralAC = table.Column<bool>(type: "boolean", nullable: true),
                    NaturalGas = table.Column<bool>(type: "boolean", nullable: true),
                    HasGenerator = table.Column<bool>(type: "boolean", nullable: true),
                    SeaView = table.Column<bool>(type: "boolean", nullable: true),
                    NileView = table.Column<bool>(type: "boolean", nullable: true),
                    PyramidView = table.Column<bool>(type: "boolean", nullable: true),
                    GardenView = table.Column<bool>(type: "boolean", nullable: true),
                    StreetView = table.Column<bool>(type: "boolean", nullable: true),
                    Name = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    Description = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    Location = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    ImageUrl = table.Column<string>(type: "text", nullable: false),
                    SquareFeet = table.Column<int>(type: "integer", nullable: false),
                    YearBuilt = table.Column<int>(type: "integer", nullable: false),
                    IsApproved = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Bedrooms = table.Column<int>(type: "integer", nullable: false),
                    Bathrooms = table.Column<int>(type: "integer", nullable: false),
                    Type = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChildProperties", x => x.PropertyId);
                    table.ForeignKey(
                        name: "FK_ChildProperties_Accounts_OwnerId",
                        column: x => x.OwnerId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_ChildProperties_ParentProperties_ParentPropertyId",
                        column: x => x.ParentPropertyId,
                        principalTable: "ParentProperties",
                        principalColumn: "ParentPropertyId",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_ChildProperties_Projects_ProjectId",
                        column: x => x.ProjectId,
                        principalTable: "Projects",
                        principalColumn: "ProjectId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "Auctions",
                columns: table => new
                {
                    AuctionId = table.Column<Guid>(type: "uuid", nullable: false),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    StartPrice = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    CurrentPrice = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    StartAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Duration = table.Column<int>(type: "integer", nullable: false),
                    BidCount = table.Column<int>(type: "integer", nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Auctions", x => x.AuctionId);
                    table.ForeignKey(
                        name: "FK_Auctions_ChildProperties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "ChildProperties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ChatMessages",
                columns: table => new
                {
                    MessageId = table.Column<Guid>(type: "uuid", nullable: false),
                    ChatId = table.Column<Guid>(type: "uuid", nullable: false),
                    SenderId = table.Column<Guid>(type: "uuid", nullable: false),
                    Content = table.Column<string>(type: "text", nullable: false),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsRead = table.Column<bool>(type: "boolean", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChatMessages", x => x.MessageId);
                    table.ForeignKey(
                        name: "FK_ChatMessages_Accounts_SenderId",
                        column: x => x.SenderId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ChatMessages_Chats_ChatId",
                        column: x => x.ChatId,
                        principalTable: "Chats",
                        principalColumn: "ChatId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ChatMessages_ChildProperties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "ChildProperties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "InstallmentSummaries",
                columns: table => new
                {
                    SummaryId = table.Column<Guid>(type: "uuid", nullable: false),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    ContractedPrice = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    TotalPaid = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    DownPaymentPercent = table.Column<decimal>(type: "numeric(5,2)", nullable: false),
                    TermYears = table.Column<int>(type: "integer", nullable: true),
                    InstallmentEndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsFullyPaid = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    RemainingBalance = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_InstallmentSummaries", x => x.SummaryId);
                    table.ForeignKey(
                        name: "FK_InstallmentSummaries_ChildProperties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "ChildProperties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PropertyDocs",
                columns: table => new
                {
                    DocId = table.Column<Guid>(type: "uuid", nullable: false),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    DocType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ImgUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    DeleteUrl = table.Column<string>(type: "text", nullable: true),
                    UploadedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyDocs", x => x.DocId);
                    table.ForeignKey(
                        name: "FK_PropertyDocs_ChildProperties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "ChildProperties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PropertyImages",
                columns: table => new
                {
                    PropertyImageId = table.Column<Guid>(type: "uuid", nullable: false),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    ImageUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    ImageType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    IsMainImage = table.Column<bool>(type: "boolean", nullable: false),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false),
                    DeleteUrl = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyImages", x => x.PropertyImageId);
                    table.ForeignKey(
                        name: "FK_PropertyImages_ChildProperties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "ChildProperties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PropertyValuations",
                columns: table => new
                {
                    ValuationId = table.Column<Guid>(type: "uuid", nullable: false),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    EstimatedValue = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    Confidence = table.Column<decimal>(type: "numeric(5,2)", nullable: true),
                    CalculatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ValuationSource = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    AIReasoning = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    ComparablesCount = table.Column<int>(type: "integer", nullable: true),
                    PriceRangeLow = table.Column<decimal>(type: "numeric(18,2)", nullable: true),
                    PriceRangeHigh = table.Column<decimal>(type: "numeric(18,2)", nullable: true),
                    MarketTrends = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true)
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

            migrationBuilder.CreateTable(
                name: "PropertyViews",
                columns: table => new
                {
                    ViewId = table.Column<Guid>(type: "uuid", nullable: false),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    ViewedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UserLocation = table.Column<string>(type: "text", nullable: true),
                    DurationSeconds = table.Column<int>(type: "integer", nullable: false),
                    DeviceType = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyViews", x => x.ViewId);
                    table.ForeignKey(
                        name: "FK_PropertyViews_Accounts_UserId",
                        column: x => x.UserId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_PropertyViews_ChildProperties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "ChildProperties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Bids",
                columns: table => new
                {
                    BidId = table.Column<Guid>(type: "uuid", nullable: false),
                    AuctionId = table.Column<Guid>(type: "uuid", nullable: false),
                    BidderId = table.Column<Guid>(type: "uuid", nullable: false),
                    BidAmount = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Bids", x => x.BidId);
                    table.ForeignKey(
                        name: "FK_Bids_Accounts_BidderId",
                        column: x => x.BidderId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Bids_Auctions_AuctionId",
                        column: x => x.AuctionId,
                        principalTable: "Auctions",
                        principalColumn: "AuctionId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PropertyPriceHistories",
                columns: table => new
                {
                    PriceHistoryId = table.Column<Guid>(type: "uuid", nullable: false),
                    ParentPropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    Price = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    PriceDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Source = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    AuctionId = table.Column<Guid>(type: "uuid", nullable: true),
                    ChildPropertyId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyPriceHistories", x => x.PriceHistoryId);
                    table.ForeignKey(
                        name: "FK_PropertyPriceHistories_Auctions_AuctionId",
                        column: x => x.AuctionId,
                        principalTable: "Auctions",
                        principalColumn: "AuctionId",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_PropertyPriceHistories_ChildProperties_ChildPropertyId",
                        column: x => x.ChildPropertyId,
                        principalTable: "ChildProperties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_PropertyPriceHistories_ParentProperties_ParentPropertyId",
                        column: x => x.ParentPropertyId,
                        principalTable: "ParentProperties",
                        principalColumn: "ParentPropertyId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Faqs",
                columns: new[] { "FaqId", "Answer", "CreatedAt", "DisplayOrder", "Question" },
                values: new object[,]
                {
                    { new Guid("11111111-1111-1111-1111-111111111111"), "Go to the Add Property screen, fill out the mandatory fields, upload images, and submit for review.", new DateTime(2025, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 1, "How do I list a new property?" },
                    { new Guid("22222222-2222-2222-2222-222222222222"), "Yes, open the property from your dashboard and tap Edit. Changes trigger a short review cycle.", new DateTime(2025, 1, 1, 0, 1, 0, 0, DateTimeKind.Utc), 2, "Can I edit my property after submission?" },
                    { new Guid("33333333-3333-3333-3333-333333333333"), "At minimum you need proof of ownership and unit floor plans. Optional docs speed up verification.", new DateTime(2025, 1, 1, 0, 2, 0, 0, DateTimeKind.Utc), 3, "What documents are required?" },
                    { new Guid("44444444-4444-4444-4444-444444444444"), "Approved sellers can request an auction. Once approved, buyers place bids until the auction end date.", new DateTime(2025, 1, 1, 0, 3, 0, 0, DateTimeKind.Utc), 4, "How do auctions work?" },
                    { new Guid("55555555-5555-5555-5555-555555555555"), "Pricing leverages market comps, developer data, and our AI valuation engine.", new DateTime(2025, 1, 1, 0, 4, 0, 0, DateTimeKind.Utc), 5, "How is property pricing estimated?" },
                    { new Guid("66666666-6666-6666-6666-666666666666"), "Yes, tap the bookmark icon on any property to store it in your Saved list.", new DateTime(2025, 1, 1, 0, 5, 0, 0, DateTimeKind.Utc), 6, "Can I save favourite properties?" },
                    { new Guid("77777777-7777-7777-7777-777777777777"), "Use the Contact Developer button on the project or property page to open a chat.", new DateTime(2025, 1, 1, 0, 6, 0, 0, DateTimeKind.Utc), 7, "How do I contact a developer?" },
                    { new Guid("88888888-8888-8888-8888-888888888888"), "Our AI Broker suggests opportunities and answers investment questions in real time.", new DateTime(2025, 1, 1, 0, 7, 0, 0, DateTimeKind.Utc), 8, "What is the AI Broker?" },
                    { new Guid("99999999-9999-9999-9999-999999999999"), "Follow projects to receive push notifications and see updates in your feed.", new DateTime(2025, 1, 1, 0, 8, 0, 0, DateTimeKind.Utc), 9, "How do I track project updates?" },
                    { new Guid("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"), "Tap Forgot Password on the login screen and follow the emailed instructions.", new DateTime(2025, 1, 1, 0, 9, 0, 0, DateTimeKind.Utc), 10, "How can I reset my password?" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Accounts_AssignedDeveloperId",
                table: "Accounts",
                column: "AssignedDeveloperId");

            migrationBuilder.CreateIndex(
                name: "IX_Accounts_RoleId",
                table: "Accounts",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "IX_Accounts_RoleId1",
                table: "Accounts",
                column: "RoleId1");

            migrationBuilder.CreateIndex(
                name: "IX_Accounts_SalesTeamId",
                table: "Accounts",
                column: "SalesTeamId");

            migrationBuilder.CreateIndex(
                name: "IX_AIChatMessages_AIChatId",
                table: "AIChatMessages",
                column: "AIChatId");

            migrationBuilder.CreateIndex(
                name: "IX_AIChats_UserId",
                table: "AIChats",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Auctions_PropertyId",
                table: "Auctions",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_Bids_AuctionId",
                table: "Bids",
                column: "AuctionId");

            migrationBuilder.CreateIndex(
                name: "IX_Bids_BidderId",
                table: "Bids",
                column: "BidderId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatMessages_ChatId",
                table: "ChatMessages",
                column: "ChatId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatMessages_PropertyId",
                table: "ChatMessages",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatMessages_SenderId",
                table: "ChatMessages",
                column: "SenderId");

            migrationBuilder.CreateIndex(
                name: "IX_Chats_DeveloperId",
                table: "Chats",
                column: "DeveloperId");

            migrationBuilder.CreateIndex(
                name: "IX_Chats_ProjectId",
                table: "Chats",
                column: "ProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_Chats_SalesMemberId",
                table: "Chats",
                column: "SalesMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_Chats_UserId",
                table: "Chats",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_ChildProperties_OwnerId",
                table: "ChildProperties",
                column: "OwnerId");

            migrationBuilder.CreateIndex(
                name: "IX_ChildProperties_ParentPropertyId",
                table: "ChildProperties",
                column: "ParentPropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_ChildProperties_ProjectId",
                table: "ChildProperties",
                column: "ProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_DeveloperPermissions_DeveloperId_FeatureName",
                table: "DeveloperPermissions",
                columns: new[] { "DeveloperId", "FeatureName" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DeveloperProfiles_AccountId",
                table: "DeveloperProfiles",
                column: "AccountId");

            migrationBuilder.CreateIndex(
                name: "IX_DeveloperRatings_DeveloperId",
                table: "DeveloperRatings",
                column: "DeveloperId");

            migrationBuilder.CreateIndex(
                name: "IX_DeveloperRatings_UserId",
                table: "DeveloperRatings",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Events_UserId",
                table: "Events",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Faqs_DisplayOrder",
                table: "Faqs",
                column: "DisplayOrder");

            migrationBuilder.CreateIndex(
                name: "IX_InstallmentSummaries_PropertyId",
                table: "InstallmentSummaries",
                column: "PropertyId",
                unique: true);

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
                name: "IX_LiveStreams_DeveloperId",
                table: "LiveStreams",
                column: "DeveloperId");

            migrationBuilder.CreateIndex(
                name: "IX_NewsArticles_DeveloperId",
                table: "NewsArticles",
                column: "DeveloperId");

            migrationBuilder.CreateIndex(
                name: "IX_NewsImages_NewsArticleId",
                table: "NewsImages",
                column: "NewsArticleId");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_UserId",
                table: "Notifications",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_ParentProperties_ProjectId",
                table: "ParentProperties",
                column: "ProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_ProjectMilestones_ProjectId",
                table: "ProjectMilestones",
                column: "ProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_Projects_AdminAccountAccountId",
                table: "Projects",
                column: "AdminAccountAccountId");

            migrationBuilder.CreateIndex(
                name: "IX_Projects_DeveloperId",
                table: "Projects",
                column: "DeveloperId");

            migrationBuilder.CreateIndex(
                name: "IX_Projects_SalesAccountAccountId",
                table: "Projects",
                column: "SalesAccountAccountId");

            migrationBuilder.CreateIndex(
                name: "IX_Projects_UserAccountAccountId",
                table: "Projects",
                column: "UserAccountAccountId");

            migrationBuilder.CreateIndex(
                name: "IX_ProjectUpdates_ProjectId",
                table: "ProjectUpdates",
                column: "ProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyDocs_PropertyId",
                table: "PropertyDocs",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyImages_PropertyId",
                table: "PropertyImages",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyPriceHistories_AuctionId",
                table: "PropertyPriceHistories",
                column: "AuctionId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyPriceHistories_ChildPropertyId",
                table: "PropertyPriceHistories",
                column: "ChildPropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyPriceHistories_ParentPropertyId",
                table: "PropertyPriceHistories",
                column: "ParentPropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyValuations_PropertyId",
                table: "PropertyValuations",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyViews_PropertyId",
                table: "PropertyViews",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyViews_UserId",
                table: "PropertyViews",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Redemptions_AccountId",
                table: "Redemptions",
                column: "AccountId");

            migrationBuilder.CreateIndex(
                name: "IX_Referrals_ReferralCode",
                table: "Referrals",
                column: "ReferralCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Referrals_ReferredUserId",
                table: "Referrals",
                column: "ReferredUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Referrals_ReferrerId",
                table: "Referrals",
                column: "ReferrerId");

            migrationBuilder.CreateIndex(
                name: "IX_Roles_RoleName",
                table: "Roles",
                column: "RoleName",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SalesTeams_DeveloperId",
                table: "SalesTeams",
                column: "DeveloperId");

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

            migrationBuilder.CreateIndex(
                name: "IX_StreamViewers_StreamId_UserId",
                table: "StreamViewers",
                columns: new[] { "StreamId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_StreamViewers_UserId",
                table: "StreamViewers",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserAchievements_AccountId",
                table: "UserAchievements",
                column: "AccountId");

            migrationBuilder.CreateIndex(
                name: "IX_UserBadges_AccountId",
                table: "UserBadges",
                column: "AccountId");

            migrationBuilder.CreateIndex(
                name: "IX_UserDocs_UserId",
                table: "UserDocs",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserRewards_AccountId",
                table: "UserRewards",
                column: "AccountId");

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

            migrationBuilder.AddForeignKey(
                name: "FK_Accounts_SalesTeams_SalesTeamId",
                table: "Accounts",
                column: "SalesTeamId",
                principalTable: "SalesTeams",
                principalColumn: "TeamId",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Accounts_Roles_RoleId",
                table: "Accounts");

            migrationBuilder.DropForeignKey(
                name: "FK_Accounts_Roles_RoleId1",
                table: "Accounts");

            migrationBuilder.DropForeignKey(
                name: "FK_Accounts_SalesTeams_SalesTeamId",
                table: "Accounts");

            migrationBuilder.DropTable(
                name: "AIChatMessages");

            migrationBuilder.DropTable(
                name: "Bids");

            migrationBuilder.DropTable(
                name: "ChatMessages");

            migrationBuilder.DropTable(
                name: "DeveloperPermissions");

            migrationBuilder.DropTable(
                name: "DeveloperProfiles");

            migrationBuilder.DropTable(
                name: "DeveloperRatings");

            migrationBuilder.DropTable(
                name: "Events");

            migrationBuilder.DropTable(
                name: "Faqs");

            migrationBuilder.DropTable(
                name: "GoldPrices");

            migrationBuilder.DropTable(
                name: "InstallmentSummaries");

            migrationBuilder.DropTable(
                name: "LeaderboardStandings");

            migrationBuilder.DropTable(
                name: "NewsImages");

            migrationBuilder.DropTable(
                name: "Notifications");

            migrationBuilder.DropTable(
                name: "ProjectMilestones");

            migrationBuilder.DropTable(
                name: "ProjectUpdates");

            migrationBuilder.DropTable(
                name: "PropertyDocs");

            migrationBuilder.DropTable(
                name: "PropertyImages");

            migrationBuilder.DropTable(
                name: "PropertyPriceHistories");

            migrationBuilder.DropTable(
                name: "PropertyValuations");

            migrationBuilder.DropTable(
                name: "PropertyViews");

            migrationBuilder.DropTable(
                name: "Redemptions");

            migrationBuilder.DropTable(
                name: "Referrals");

            migrationBuilder.DropTable(
                name: "StreamChatMessages");

            migrationBuilder.DropTable(
                name: "StreamViewers");

            migrationBuilder.DropTable(
                name: "UserAchievements");

            migrationBuilder.DropTable(
                name: "UserBadges");

            migrationBuilder.DropTable(
                name: "UserDocs");

            migrationBuilder.DropTable(
                name: "UserRewards");

            migrationBuilder.DropTable(
                name: "AIChats");

            migrationBuilder.DropTable(
                name: "Chats");

            migrationBuilder.DropTable(
                name: "WeeklyLeaderboardSnapshots");

            migrationBuilder.DropTable(
                name: "NewsArticles");

            migrationBuilder.DropTable(
                name: "Auctions");

            migrationBuilder.DropTable(
                name: "LiveStreams");

            migrationBuilder.DropTable(
                name: "ChildProperties");

            migrationBuilder.DropTable(
                name: "ParentProperties");

            migrationBuilder.DropTable(
                name: "Projects");

            migrationBuilder.DropTable(
                name: "Roles");

            migrationBuilder.DropTable(
                name: "SalesTeams");

            migrationBuilder.DropTable(
                name: "Accounts");
        }
    }
}
