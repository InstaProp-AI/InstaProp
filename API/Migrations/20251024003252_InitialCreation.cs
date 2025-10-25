using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PropertyFlipperAPI.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Accounts",
                columns: table => new
                {
                    AccountId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    FirstName = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    LastName = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    PhoneNumber = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    Email = table.Column<string>(type: "TEXT", maxLength: 255, nullable: false),
                    Type = table.Column<int>(type: "INTEGER", nullable: false),
                    HashedPassword = table.Column<string>(type: "TEXT", maxLength: 255, nullable: true),
                    GoogleId = table.Column<string>(type: "TEXT", maxLength: 255, nullable: true),
                    AuthProvider = table.Column<string>(type: "TEXT", maxLength: 50, nullable: true),
                    Status = table.Column<int>(type: "INTEGER", nullable: false),
                    EmailVerified = table.Column<bool>(type: "INTEGER", nullable: false),
                    PhoneVerified = table.Column<bool>(type: "INTEGER", nullable: false),
                    EmailVerificationPin = table.Column<string>(type: "TEXT", maxLength: 6, nullable: true),
                    PhoneVerificationPin = table.Column<string>(type: "TEXT", maxLength: 6, nullable: true),
                    EmailVerificationPinExpiry = table.Column<DateTime>(type: "TEXT", nullable: true),
                    PhoneVerificationPinExpiry = table.Column<DateTime>(type: "TEXT", nullable: true),
                    RequiresPasswordChange = table.Column<bool>(type: "INTEGER", nullable: false),
                    PasswordResetRequestedEmail = table.Column<string>(type: "TEXT", nullable: true),
                    PasswordResetTokenExpiry = table.Column<DateTime>(type: "TEXT", nullable: true),
                    PreviousEmail = table.Column<string>(type: "TEXT", maxLength: 100, nullable: true),
                    PreviousPhoneNumber = table.Column<string>(type: "TEXT", nullable: true),
                    IsSuspended = table.Column<bool>(type: "INTEGER", nullable: false),
                    SuspendedUntil = table.Column<DateTime>(type: "TEXT", nullable: true),
                    SuspensionReason = table.Column<string>(type: "TEXT", nullable: true),
                    FailedLoginAttempts = table.Column<int>(type: "INTEGER", nullable: false),
                    LockedUntil = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Accounts", x => x.AccountId);
                });

            migrationBuilder.CreateTable(
                name: "GoldPrices",
                columns: table => new
                {
                    GoldPriceId = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    PricePerGram = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Month = table.Column<int>(type: "INTEGER", nullable: false),
                    Year = table.Column<int>(type: "INTEGER", nullable: false),
                    Date = table.Column<DateTime>(type: "TEXT", nullable: false),
                    Source = table.Column<string>(type: "TEXT", maxLength: 50, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GoldPrices", x => x.GoldPriceId);
                });

            migrationBuilder.CreateTable(
                name: "AIChats",
                columns: table => new
                {
                    AIChatId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<long>(type: "INTEGER", nullable: false),
                    StartedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    Status = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    UserPreferences = table.Column<string>(type: "TEXT", nullable: true)
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
                name: "DeveloperProfiles",
                columns: table => new
                {
                    ProfileId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    AccountId = table.Column<long>(type: "INTEGER", nullable: false),
                    Bio = table.Column<string>(type: "TEXT", nullable: true),
                    CompanyName = table.Column<string>(type: "TEXT", maxLength: 200, nullable: true),
                    ProfileImageUrl = table.Column<string>(type: "TEXT", nullable: true),
                    Rating = table.Column<decimal>(type: "decimal(3,2)", nullable: false),
                    TotalRatings = table.Column<int>(type: "INTEGER", nullable: false),
                    PortfolioDescription = table.Column<string>(type: "TEXT", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: true)
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
                    RatingId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    DeveloperId = table.Column<long>(type: "INTEGER", nullable: false),
                    UserId = table.Column<long>(type: "INTEGER", nullable: false),
                    Rating = table.Column<int>(type: "INTEGER", nullable: false),
                    Comment = table.Column<string>(type: "TEXT", nullable: true),
                    RatingType = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
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
                    EventId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<long>(type: "INTEGER", nullable: false),
                    Title = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "TEXT", nullable: true),
                    EventDate = table.Column<DateTime>(type: "TEXT", nullable: false),
                    Type = table.Column<int>(type: "INTEGER", nullable: false),
                    Location = table.Column<string>(type: "TEXT", maxLength: 50, nullable: true),
                    IsAllDay = table.Column<bool>(type: "INTEGER", nullable: false),
                    StartTime = table.Column<DateTime>(type: "TEXT", nullable: true),
                    EndTime = table.Column<DateTime>(type: "TEXT", nullable: true),
                    IsCompleted = table.Column<bool>(type: "INTEGER", nullable: false),
                    IsReminderSet = table.Column<bool>(type: "INTEGER", nullable: false),
                    ReminderMinutes = table.Column<int>(type: "INTEGER", nullable: true),
                    IsPublic = table.Column<bool>(type: "INTEGER", nullable: false),
                    IsRecurring = table.Column<bool>(type: "INTEGER", nullable: false),
                    RecurrencePattern = table.Column<int>(type: "INTEGER", nullable: true),
                    RecurrenceInterval = table.Column<int>(type: "INTEGER", nullable: true),
                    RecurrenceEndDate = table.Column<DateTime>(type: "TEXT", nullable: true),
                    RecurrenceCount = table.Column<int>(type: "INTEGER", nullable: true),
                    ParentEventId = table.Column<long>(type: "INTEGER", nullable: true),
                    Amount = table.Column<decimal>(type: "TEXT", nullable: true),
                    PropertyId = table.Column<long>(type: "INTEGER", nullable: true),
                    AuctionId = table.Column<long>(type: "INTEGER", nullable: true),
                    BidId = table.Column<long>(type: "INTEGER", nullable: true),
                    ScheduleImageUrl = table.Column<string>(type: "TEXT", nullable: true),
                    ScheduleGroupId = table.Column<string>(type: "TEXT", nullable: true),
                    ScheduleBuyingPrice = table.Column<decimal>(type: "TEXT", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: true)
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
                name: "Notifications",
                columns: table => new
                {
                    NotificationId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<long>(type: "INTEGER", nullable: true),
                    Title = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    Message = table.Column<string>(type: "TEXT", maxLength: 500, nullable: false),
                    Type = table.Column<int>(type: "INTEGER", nullable: false),
                    IsRead = table.Column<bool>(type: "INTEGER", nullable: false),
                    Recipients = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true),
                    ReadByUsers = table.Column<string>(type: "TEXT", maxLength: 5000, nullable: true),
                    AuctionId = table.Column<long>(type: "INTEGER", nullable: true),
                    BidId = table.Column<long>(type: "INTEGER", nullable: true),
                    PropertyId = table.Column<long>(type: "INTEGER", nullable: true),
                    EventId = table.Column<long>(type: "INTEGER", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    ReadAt = table.Column<DateTime>(type: "TEXT", nullable: true)
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
                    ProjectId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    DeveloperId = table.Column<long>(type: "INTEGER", nullable: false),
                    Name = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "TEXT", nullable: true),
                    Location = table.Column<string>(type: "TEXT", maxLength: 255, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: true),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Projects", x => x.ProjectId);
                    table.ForeignKey(
                        name: "FK_Projects_Accounts_DeveloperId",
                        column: x => x.DeveloperId,
                        principalTable: "Accounts",
                        principalColumn: "AccountId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Referrals",
                columns: table => new
                {
                    ReferralId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    ReferrerId = table.Column<long>(type: "INTEGER", nullable: false),
                    ReferredUserId = table.Column<long>(type: "INTEGER", nullable: true),
                    ReferralCode = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    IsConverted = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    ConvertedAt = table.Column<DateTime>(type: "TEXT", nullable: true)
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
                name: "UserBadges",
                columns: table => new
                {
                    BadgeId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    AccountId = table.Column<long>(type: "INTEGER", nullable: false),
                    BadgeName = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    BadgeIcon = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "TEXT", nullable: true),
                    AwardedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
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
                    DocId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<long>(type: "INTEGER", nullable: false),
                    DocType = table.Column<string>(type: "TEXT", maxLength: 50, nullable: false),
                    ImgUrl = table.Column<string>(type: "TEXT", maxLength: 500, nullable: false),
                    DeleteUrl = table.Column<string>(type: "TEXT", nullable: true),
                    UploadedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
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
                    RewardId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    AccountId = table.Column<long>(type: "INTEGER", nullable: false),
                    Points = table.Column<int>(type: "INTEGER", nullable: false),
                    RewardType = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "TEXT", nullable: true),
                    RelatedPropertyId = table.Column<long>(type: "INTEGER", nullable: true),
                    EarnedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
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
                name: "AIChatMessages",
                columns: table => new
                {
                    MessageId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    AIChatId = table.Column<long>(type: "INTEGER", nullable: false),
                    Role = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    Content = table.Column<string>(type: "TEXT", nullable: false),
                    MessageType = table.Column<string>(type: "TEXT", maxLength: 50, nullable: false),
                    PropertyId = table.Column<long>(type: "INTEGER", nullable: true),
                    ProjectId = table.Column<long>(type: "INTEGER", nullable: true),
                    DeveloperId = table.Column<long>(type: "INTEGER", nullable: true),
                    Options = table.Column<string>(type: "TEXT", nullable: true),
                    QuestionType = table.Column<string>(type: "TEXT", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
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
                name: "Chats",
                columns: table => new
                {
                    ChatId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    UserId = table.Column<long>(type: "INTEGER", nullable: false),
                    DeveloperId = table.Column<long>(type: "INTEGER", nullable: false),
                    ProjectId = table.Column<long>(type: "INTEGER", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    LastMessageAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false)
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
                    ParentPropertyId = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    ProjectName = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    Bedrooms = table.Column<int>(type: "INTEGER", nullable: false),
                    Bathrooms = table.Column<int>(type: "INTEGER", nullable: false),
                    AreaSqm = table.Column<int>(type: "INTEGER", nullable: false),
                    PropertyType = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    FinishingType = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    HasPool = table.Column<bool>(type: "INTEGER", nullable: false),
                    HasGym = table.Column<bool>(type: "INTEGER", nullable: false),
                    HasSecurity = table.Column<bool>(type: "INTEGER", nullable: false),
                    HasParking = table.Column<bool>(type: "INTEGER", nullable: false),
                    HasGarden = table.Column<bool>(type: "INTEGER", nullable: false),
                    HasPlayground = table.Column<bool>(type: "INTEGER", nullable: false),
                    HasClubhouse = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    ProjectId = table.Column<long>(type: "INTEGER", nullable: true)
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
                    MilestoneId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    ProjectId = table.Column<long>(type: "INTEGER", nullable: false),
                    Title = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "TEXT", nullable: true),
                    TargetDate = table.Column<DateTime>(type: "TEXT", nullable: false),
                    CompletedDate = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CompletionPercentage = table.Column<int>(type: "INTEGER", nullable: false),
                    Status = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: true)
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
                    UpdateId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    ProjectId = table.Column<long>(type: "INTEGER", nullable: false),
                    Title = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    Content = table.Column<string>(type: "TEXT", nullable: false),
                    ImageUrl = table.Column<string>(type: "TEXT", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
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
                name: "ChildProperties",
                columns: table => new
                {
                    PropertyId = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    ParentPropertyId = table.Column<int>(type: "INTEGER", nullable: false),
                    OwnerId = table.Column<long>(type: "INTEGER", nullable: true),
                    Phase = table.Column<string>(type: "TEXT", maxLength: 50, nullable: true),
                    FloorNumber = table.Column<int>(type: "INTEGER", nullable: true),
                    UnitNumber = table.Column<string>(type: "TEXT", maxLength: 50, nullable: true),
                    ViewType = table.Column<string>(type: "TEXT", maxLength: 100, nullable: true),
                    Orientation = table.Column<string>(type: "TEXT", maxLength: 100, nullable: true),
                    DeliveryDate = table.Column<DateTime>(type: "TEXT", nullable: true),
                    ParkingSlots = table.Column<int>(type: "INTEGER", nullable: true),
                    HasStorageRoom = table.Column<bool>(type: "INTEGER", nullable: true),
                    BuyingPrice = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    BuyingDate = table.Column<DateTime>(type: "TEXT", nullable: true),
                    Quantity = table.Column<int>(type: "INTEGER", nullable: false),
                    HasNannyRoom = table.Column<bool>(type: "INTEGER", nullable: true),
                    HasDriverRoom = table.Column<bool>(type: "INTEGER", nullable: true),
                    HasMaidRoom = table.Column<bool>(type: "INTEGER", nullable: true),
                    HasPrivatePool = table.Column<bool>(type: "INTEGER", nullable: true),
                    HasRoofAccess = table.Column<bool>(type: "INTEGER", nullable: true),
                    HasBalcony = table.Column<bool>(type: "INTEGER", nullable: true),
                    HasGarden = table.Column<bool>(type: "INTEGER", nullable: true),
                    SmartHome = table.Column<bool>(type: "INTEGER", nullable: true),
                    CentralAC = table.Column<bool>(type: "INTEGER", nullable: true),
                    NaturalGas = table.Column<bool>(type: "INTEGER", nullable: true),
                    HasGenerator = table.Column<bool>(type: "INTEGER", nullable: true),
                    SeaView = table.Column<bool>(type: "INTEGER", nullable: true),
                    NileView = table.Column<bool>(type: "INTEGER", nullable: true),
                    PyramidView = table.Column<bool>(type: "INTEGER", nullable: true),
                    GardenView = table.Column<bool>(type: "INTEGER", nullable: true),
                    StreetView = table.Column<bool>(type: "INTEGER", nullable: true),
                    Name = table.Column<string>(type: "TEXT", maxLength: 500, nullable: false),
                    Description = table.Column<string>(type: "TEXT", maxLength: 2000, nullable: false),
                    Location = table.Column<string>(type: "TEXT", maxLength: 500, nullable: false),
                    Category = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    ImageUrl = table.Column<string>(type: "TEXT", nullable: false),
                    SquareFeet = table.Column<int>(type: "INTEGER", nullable: false),
                    YearBuilt = table.Column<int>(type: "INTEGER", nullable: false),
                    IsApproved = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    Bedrooms = table.Column<int>(type: "INTEGER", nullable: false),
                    Bathrooms = table.Column<int>(type: "INTEGER", nullable: false),
                    PropertyType = table.Column<string>(type: "TEXT", nullable: false),
                    Type = table.Column<int>(type: "INTEGER", nullable: false),
                    Status = table.Column<int>(type: "INTEGER", nullable: false),
                    ProjectId = table.Column<long>(type: "INTEGER", nullable: true)
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
                        onDelete: ReferentialAction.Cascade);
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
                    AuctionId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    PropertyId = table.Column<int>(type: "INTEGER", nullable: false),
                    StartPrice = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    CurrentPrice = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    StartAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    Duration = table.Column<int>(type: "INTEGER", nullable: false),
                    BidCount = table.Column<int>(type: "INTEGER", nullable: false),
                    Status = table.Column<string>(type: "TEXT", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
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
                    MessageId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    ChatId = table.Column<long>(type: "INTEGER", nullable: false),
                    SenderId = table.Column<long>(type: "INTEGER", nullable: false),
                    Content = table.Column<string>(type: "TEXT", nullable: false),
                    PropertyId = table.Column<int>(type: "INTEGER", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    IsRead = table.Column<bool>(type: "INTEGER", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "TEXT", nullable: false)
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
                name: "PropertyDocs",
                columns: table => new
                {
                    DocId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    PropertyId = table.Column<int>(type: "INTEGER", nullable: false),
                    DocType = table.Column<string>(type: "TEXT", maxLength: 50, nullable: false),
                    ImgUrl = table.Column<string>(type: "TEXT", maxLength: 500, nullable: false),
                    DeleteUrl = table.Column<string>(type: "TEXT", nullable: true),
                    UploadedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
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
                    PropertyImageId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    PropertyId = table.Column<int>(type: "INTEGER", nullable: false),
                    ImageUrl = table.Column<string>(type: "TEXT", maxLength: 500, nullable: false),
                    ImageType = table.Column<string>(type: "TEXT", maxLength: 50, nullable: false),
                    IsMainImage = table.Column<bool>(type: "INTEGER", nullable: false),
                    DisplayOrder = table.Column<int>(type: "INTEGER", nullable: false),
                    DeleteUrl = table.Column<string>(type: "TEXT", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
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
                name: "PropertyViews",
                columns: table => new
                {
                    ViewId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    PropertyId = table.Column<int>(type: "INTEGER", nullable: false),
                    UserId = table.Column<long>(type: "INTEGER", nullable: true),
                    ViewedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UserLocation = table.Column<string>(type: "TEXT", nullable: true),
                    DurationSeconds = table.Column<int>(type: "INTEGER", nullable: false),
                    DeviceType = table.Column<string>(type: "TEXT", nullable: true)
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
                    BidId = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    AuctionId = table.Column<long>(type: "INTEGER", nullable: false),
                    BidderId = table.Column<long>(type: "INTEGER", nullable: false),
                    BidAmount = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
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
                    PriceHistoryId = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    ParentPropertyId = table.Column<int>(type: "INTEGER", nullable: false),
                    Price = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    PriceDate = table.Column<DateTime>(type: "TEXT", nullable: false),
                    Notes = table.Column<string>(type: "TEXT", maxLength: 500, nullable: true),
                    Source = table.Column<string>(type: "TEXT", maxLength: 50, nullable: false),
                    AuctionId = table.Column<long>(type: "INTEGER", nullable: true),
                    ChildPropertyId = table.Column<int>(type: "INTEGER", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
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
                name: "IX_Projects_DeveloperId",
                table: "Projects",
                column: "DeveloperId");

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
                name: "IX_PropertyViews_PropertyId",
                table: "PropertyViews",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyViews_UserId",
                table: "PropertyViews",
                column: "UserId");

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
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AIChatMessages");

            migrationBuilder.DropTable(
                name: "Bids");

            migrationBuilder.DropTable(
                name: "ChatMessages");

            migrationBuilder.DropTable(
                name: "DeveloperProfiles");

            migrationBuilder.DropTable(
                name: "DeveloperRatings");

            migrationBuilder.DropTable(
                name: "Events");

            migrationBuilder.DropTable(
                name: "GoldPrices");

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
                name: "PropertyViews");

            migrationBuilder.DropTable(
                name: "Referrals");

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
                name: "Auctions");

            migrationBuilder.DropTable(
                name: "ChildProperties");

            migrationBuilder.DropTable(
                name: "ParentProperties");

            migrationBuilder.DropTable(
                name: "Projects");

            migrationBuilder.DropTable(
                name: "Accounts");
        }
    }
}
