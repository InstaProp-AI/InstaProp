using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using InstapropAPI.Models;

namespace InstapropAPI.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) {}

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            // Suppress pending model changes warning in production
            // This allows migrations to run even if model has minor differences
            optionsBuilder.ConfigureWarnings(warnings =>
                warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
        }

        public DbSet<Role> Roles { get; set; }
        public DbSet<AccountBase> Accounts { get; set; } // Query all account types through base class
        public DbSet<UserAccount> UserAccounts { get; set; }
        public DbSet<DeveloperAccount> DeveloperAccounts { get; set; }
        public DbSet<AdminAccount> AdminAccounts { get; set; }
        public DbSet<SalesAccount> SalesAccounts { get; set; }
        public DbSet<SalesTeam> SalesTeams { get; set; }
        // Removed: public DbSet<Property> Properties { get; set; } - Now using ChildProperty
        public DbSet<PropertyDoc> PropertyDocs { get; set; }
        public DbSet<PropertyImage> PropertyImages { get; set; }
        public DbSet<UserDoc> UserDocs { get; set; }
        public DbSet<Auction> Auctions { get; set; }
        public DbSet<Bid> Bids { get; set; }
        public DbSet<Project> Projects { get; set; }
        public DbSet<Event> Events { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<Chat> Chats { get; set; }
        public DbSet<ChatMessage> ChatMessages { get; set; }
        public DbSet<DeveloperProfile> DeveloperProfiles { get; set; }
        public DbSet<DeveloperRating> DeveloperRatings { get; set; }
        public DbSet<DeveloperPermission> DeveloperPermissions { get; set; }
        
        // Phase 3: Project enhancements
        public DbSet<ProjectMilestone> ProjectMilestones { get; set; }
        public DbSet<ProjectUpdate> ProjectUpdates { get; set; }
        
        // Phase 4: Gamification & Engagement
        public DbSet<UserReward> UserRewards { get; set; }
        public DbSet<UserBadge> UserBadges { get; set; }
        public DbSet<WeeklyLeaderboardSnapshot> WeeklyLeaderboardSnapshots { get; set; }
        public DbSet<LeaderboardStanding> LeaderboardStandings { get; set; }
        public DbSet<Referral> Referrals { get; set; }
        public DbSet<PropertyView> PropertyViews { get; set; }
        public DbSet<Redemption> Redemptions { get; set; }

        // AI Broker Chat System
        public DbSet<AIChat> AIChats { get; set; }
        public DbSet<AIChatMessage> AIChatMessages { get; set; }

        // Parent-Child Property System
        public DbSet<ParentProperty> ParentProperties { get; set; }
        public DbSet<ChildProperty> ChildProperties { get; set; }
        public DbSet<GoldPrice> GoldPrices { get; set; }
        public DbSet<PropertyPriceHistory> PropertyPriceHistories { get; set; }
        public DbSet<PropertyValuation> PropertyValuations { get; set; }

        // News System
        public DbSet<NewsArticle> NewsArticles { get; set; }
        public DbSet<NewsImage> NewsImages { get; set; }

        public DbSet<Faq> Faqs { get; set; }

        public DbSet<InstallmentSummary> InstallmentSummaries { get; set; }
        public DbSet<UserAchievement> UserAchievements { get; set; }
        
        // Live Streaming
        public DbSet<LiveStream> LiveStreams { get; set; }
        public DbSet<StreamViewer> StreamViewers { get; set; }
        public DbSet<StreamChatMessage> StreamChatMessages { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure Role
            modelBuilder.Entity<Role>(entity =>
            {
                entity.HasKey(e => e.RoleId);
                entity.Property(e => e.RoleId).ValueGeneratedNever(); // IDs are manually set (UUID constants)
                entity.Property(e => e.RoleName).HasMaxLength(50).IsRequired();
                entity.Property(e => e.Description).HasMaxLength(500);
                entity.HasIndex(e => e.RoleName).IsUnique();
            });

            // Configure Account Types using Table-Per-Hierarchy (TPH)
            // All account types share the same table with a discriminator column
            // AccountBase is the abstract base class that implements IAccount
            modelBuilder.Entity<AccountBase>(entity =>
            {
                entity.HasKey(e => e.AccountId);
                entity.Property(e => e.AccountId).ValueGeneratedOnAdd();
                entity.Property(e => e.FirstName).HasMaxLength(100);
                entity.Property(e => e.LastName).HasMaxLength(100);
                entity.Property(e => e.PhoneNumber).HasMaxLength(20).IsRequired();
                entity.Property(e => e.Email).HasMaxLength(255).IsRequired();
                entity.Property(e => e.RoleId).IsRequired();
                entity.Property(e => e.HashedPassword).HasMaxLength(255);
                
                entity.HasDiscriminator<string>("AccountType")
                    .HasValue<UserAccount>("User")
                    .HasValue<DeveloperAccount>("Developer")
                    .HasValue<AdminAccount>("Admin")
                    .HasValue<SalesAccount>("Sales");
                
                entity.HasOne(e => e.Role)
                    .WithMany()
                    .HasForeignKey(e => e.RoleId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Configure UserAccount (has GoogleId, AuthProvider)
            modelBuilder.Entity<UserAccount>(entity =>
            {
                entity.Property(e => e.GoogleId).HasMaxLength(255);
                entity.Property(e => e.AuthProvider).HasMaxLength(50);
            });

            // Configure DeveloperAccount (no additional properties)
            // Uses base class properties only

            // Configure AdminAccount (no additional properties)
            // Uses base class properties only

            // Configure SalesAccount (has SalesTeamId, AssignedDeveloperId)
            modelBuilder.Entity<SalesAccount>(entity =>
            {
                entity.HasOne(e => e.AssignedDeveloper)
                    .WithMany()
                    .HasForeignKey(e => e.AssignedDeveloperId)
                    .OnDelete(DeleteBehavior.Restrict);
                
                entity.HasOne(e => e.SalesTeam)
                    .WithMany(t => t.SalesMembers)
                    .HasForeignKey(e => e.SalesTeamId)
                    .OnDelete(DeleteBehavior.SetNull);
            });


            var propertyTypeConverter = new ValueConverter<PropertyType, string>(
                type => PropertyTypeHelper.ToDisplayName(type),
                value => PropertyTypeHelper.FromDisplayName(value));

            // Configure Property (now ChildProperty)
            modelBuilder.Entity<ChildProperty>(entity =>
            {
                entity.HasKey(e => e.PropertyId);
                entity.Property(e => e.PropertyId).ValueGeneratedOnAdd();
                entity.Property(e => e.Name).HasMaxLength(500).IsRequired();
                entity.Property(e => e.Location).HasMaxLength(500);
                entity.Property(e => e.Type)
                    .HasConversion(propertyTypeConverter)
                    .HasMaxLength(100);
                entity.Property(e => e.BuyingPrice).HasColumnType("decimal(18,2)");
                entity.HasOne(e => e.Owner)
                    .WithMany()
                    .HasForeignKey(e => e.OwnerId)
                    .OnDelete(DeleteBehavior.SetNull);
                entity.HasOne(e => e.Project)
                    .WithMany()
                    .HasForeignKey(e => e.ProjectId)
                    .OnDelete(DeleteBehavior.SetNull);
                entity.HasOne(e => e.ParentProperty)
                    .WithMany(p => p.ChildProperties)
                    .HasForeignKey(e => e.ParentPropertyId)
                    .OnDelete(DeleteBehavior.SetNull);
            });

            modelBuilder.Entity<InstallmentSummary>(entity =>
            {
                entity.HasKey(e => e.SummaryId);
                entity.Property(e => e.SummaryId).ValueGeneratedOnAdd();
                entity.Property(e => e.ContractedPrice).HasColumnType("decimal(18,2)");
                entity.Property(e => e.TotalPaid).HasColumnType("decimal(18,2)");
                entity.Property(e => e.DownPaymentPercent).HasColumnType("decimal(5,2)");
                entity.Property(e => e.RemainingBalance).HasColumnType("decimal(18,2)");
                entity.Property(e => e.IsFullyPaid).HasDefaultValue(false);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
                entity.Property(e => e.UpdatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");

                entity.HasOne(e => e.Property)
                    .WithOne(p => p.InstallmentSummary)
                    .HasForeignKey<InstallmentSummary>(e => e.PropertyId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure Auction
            modelBuilder.Entity<Auction>(entity =>
            {
                entity.HasKey(e => e.AuctionId);
                entity.Property(e => e.AuctionId).ValueGeneratedOnAdd();
                entity.Property(e => e.StartPrice).HasColumnType("decimal(18,2)");
                entity.Property(e => e.CurrentPrice).HasColumnType("decimal(18,2)");
                entity.Property(e => e.Status).HasMaxLength(20);
                entity.HasOne(e => e.Property)
                    .WithMany(p => p.Auctions)
                    .HasForeignKey(e => e.PropertyId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure Bid
            modelBuilder.Entity<Bid>(entity =>
            {
                entity.HasKey(e => e.BidId);
                entity.Property(e => e.BidId).ValueGeneratedOnAdd();
                entity.Property(e => e.BidAmount).HasColumnType("decimal(18,2)");
                entity.HasOne(e => e.Auction)
                    .WithMany(a => a.Bids)
                    .HasForeignKey(e => e.AuctionId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Bidder)
                    .WithMany(u => u.Bids)
                    .HasForeignKey(e => e.BidderId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure PropertyDoc
            modelBuilder.Entity<PropertyDoc>(entity =>
            {
                entity.HasKey(e => e.DocId);
                entity.Property(e => e.DocId).ValueGeneratedOnAdd();
                entity.Property(e => e.DocType).HasMaxLength(50).IsRequired();
                entity.Property(e => e.ImgUrl).HasMaxLength(500).IsRequired();
                entity.HasOne(e => e.Property)
                    .WithMany(p => p.PropertyDocs)
                    .HasForeignKey(e => e.PropertyId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure PropertyImage
            modelBuilder.Entity<PropertyImage>(entity =>
            {
                entity.HasKey(e => e.PropertyImageId);
                entity.Property(e => e.PropertyImageId).ValueGeneratedOnAdd();
                entity.Property(e => e.ImageUrl).HasMaxLength(500).IsRequired();
                entity.Property(e => e.ImageType).HasMaxLength(50).IsRequired();
                entity.HasOne(e => e.Property)
                    .WithMany(p => p.PropertyImages)
                    .HasForeignKey(e => e.PropertyId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure UserDoc
            modelBuilder.Entity<UserDoc>(entity =>
            {
                entity.HasKey(e => e.DocId);
                entity.Property(e => e.DocId).ValueGeneratedOnAdd();
                entity.Property(e => e.DocType).HasMaxLength(50).IsRequired();
                entity.Property(e => e.ImgUrl).HasMaxLength(500).IsRequired();
                entity.HasOne(e => e.User)
                    .WithMany(u => u.UserDocs)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure Project
            modelBuilder.Entity<Project>(entity =>
            {
                entity.HasKey(e => e.ProjectId);
                entity.Property(e => e.ProjectId).ValueGeneratedOnAdd();
                entity.Property(e => e.Name).HasMaxLength(200).IsRequired();
                entity.Property(e => e.Location).HasMaxLength(255);
                entity.HasOne(e => e.Developer)
                    .WithMany(a => a.Projects)
                    .HasForeignKey(e => e.DeveloperId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure Event
            modelBuilder.Entity<Event>(entity =>
            {
                entity.HasKey(e => e.EventId);
                entity.Property(e => e.EventId).ValueGeneratedOnAdd();
                entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
                entity.Property(e => e.Location).HasMaxLength(50);
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure Notification
            modelBuilder.Entity<Notification>(entity =>
            {
                entity.HasKey(e => e.NotificationId);
                entity.Property(e => e.NotificationId).ValueGeneratedOnAdd();
                entity.Property(e => e.Title).HasMaxLength(100).IsRequired();
                entity.Property(e => e.Message).HasMaxLength(500).IsRequired();
                entity.Property(e => e.Type).HasConversion<int>();
                entity.Property(e => e.Recipients).HasMaxLength(500);
                entity.Property(e => e.ReadByUsers).HasMaxLength(5000); // Can store many user IDs
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade)
                    .IsRequired(false); // UserId is now optional for bulk notifications
            });

            // Configure Chat
            modelBuilder.Entity<Chat>(entity =>
            {
                entity.HasKey(e => e.ChatId);
                entity.Property(e => e.ChatId).ValueGeneratedOnAdd();
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.Developer)
                    .WithMany()
                    .HasForeignKey(e => e.DeveloperId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.Project)
                    .WithMany()
                    .HasForeignKey(e => e.ProjectId)
                    .OnDelete(DeleteBehavior.SetNull);
                entity.Property(e => e.IsSupportChat)
                    .HasDefaultValue(false);
            });

            // Configure ChatMessage
            modelBuilder.Entity<ChatMessage>(entity =>
            {
                entity.HasKey(e => e.MessageId);
                entity.Property(e => e.MessageId).ValueGeneratedOnAdd();
                entity.Property(e => e.Content).IsRequired();
                entity.HasOne(e => e.Chat)
                    .WithMany(c => c.Messages)
                    .HasForeignKey(e => e.ChatId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Sender)
                    .WithMany()
                    .HasForeignKey(e => e.SenderId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.Property)
                    .WithMany()
                    .HasForeignKey(e => e.PropertyId)
                    .OnDelete(DeleteBehavior.SetNull);
            });

            // Configure DeveloperProfile
            modelBuilder.Entity<DeveloperProfile>(entity =>
            {
                entity.HasKey(e => e.ProfileId);
                entity.Property(e => e.ProfileId).ValueGeneratedOnAdd();
                entity.Property(e => e.Rating).HasColumnType("decimal(3,2)");
                entity.HasOne(e => e.Account)
                    .WithMany()
                    .HasForeignKey(e => e.AccountId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure DeveloperRating
            modelBuilder.Entity<DeveloperRating>(entity =>
            {
                entity.HasKey(e => e.RatingId);
                entity.Property(e => e.RatingId).ValueGeneratedOnAdd();
                entity.Property(e => e.Rating).IsRequired();
                entity.Property(e => e.RatingType).HasConversion<int>();
                entity.HasOne(e => e.Developer)
                    .WithMany()
                    .HasForeignKey(e => e.DeveloperId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Configure DeveloperPermission
            modelBuilder.Entity<DeveloperPermission>(entity =>
            {
                entity.HasKey(e => e.DeveloperPermissionId);
                entity.Property(e => e.DeveloperPermissionId).ValueGeneratedOnAdd();
                entity.Property(e => e.FeatureName).HasMaxLength(50).IsRequired();
                entity.HasOne(e => e.Developer)
                    .WithMany()
                    .HasForeignKey(e => e.DeveloperId)
                    .OnDelete(DeleteBehavior.Cascade);
                // Unique constraint: one permission record per developer per feature
                entity.HasIndex(e => new { e.DeveloperId, e.FeatureName }).IsUnique();
            });

            // Configure ProjectMilestone
            modelBuilder.Entity<ProjectMilestone>(entity =>
            {
                entity.HasKey(e => e.MilestoneId);
                entity.Property(e => e.MilestoneId).ValueGeneratedOnAdd();
                entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
                entity.Property(e => e.Status).HasConversion<int>();
                entity.HasOne(e => e.Project)
                    .WithMany()
                    .HasForeignKey(e => e.ProjectId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure ProjectUpdate
            modelBuilder.Entity<ProjectUpdate>(entity =>
            {
                entity.HasKey(e => e.UpdateId);
                entity.Property(e => e.UpdateId).ValueGeneratedOnAdd();
                entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
                entity.HasOne(e => e.Project)
                    .WithMany()
                    .HasForeignKey(e => e.ProjectId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure UserReward
            modelBuilder.Entity<UserReward>(entity =>
            {
                entity.HasKey(e => e.RewardId);
                entity.Property(e => e.RewardId).ValueGeneratedOnAdd();
                entity.Property(e => e.RewardType).HasMaxLength(100).IsRequired();
                entity.HasOne(e => e.Account)
                    .WithMany()
                    .HasForeignKey(e => e.AccountId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure UserBadge
            modelBuilder.Entity<UserBadge>(entity =>
            {
                entity.HasKey(e => e.BadgeId);
                entity.Property(e => e.BadgeId).ValueGeneratedOnAdd();
                entity.Property(e => e.BadgeName).HasMaxLength(100).IsRequired();
                entity.Property(e => e.BadgeIcon).HasMaxLength(100).IsRequired();
                entity.HasOne(e => e.Account)
                    .WithMany()
                    .HasForeignKey(e => e.AccountId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<WeeklyLeaderboardSnapshot>(entity =>
            {
                entity.HasKey(e => e.SnapshotId);
                entity.Property(e => e.SnapshotId).ValueGeneratedOnAdd();
                entity.Property(e => e.HighlightHeadline).HasMaxLength(250);
                entity.Property(e => e.HighlightSummary).HasMaxLength(500);
                entity.HasIndex(e => new { e.WeekStart, e.WeekEnd }).IsUnique();
                entity.HasIndex(e => e.PayoutProcessed);
                entity.HasOne(e => e.WinnerAccount)
                    .WithMany()
                    .HasForeignKey(e => e.WinnerAccountId)
                    .OnDelete(DeleteBehavior.SetNull);
                entity.HasOne(e => e.SecondPlaceAccount)
                    .WithMany()
                    .HasForeignKey(e => e.SecondPlaceAccountId)
                    .OnDelete(DeleteBehavior.SetNull);
                entity.HasOne(e => e.ThirdPlaceAccount)
                    .WithMany()
                    .HasForeignKey(e => e.ThirdPlaceAccountId)
                    .OnDelete(DeleteBehavior.SetNull);
            });

            modelBuilder.Entity<LeaderboardStanding>(entity =>
            {
                entity.HasKey(e => e.StandingId);
                entity.Property(e => e.StandingId).ValueGeneratedOnAdd();
                entity.Property(e => e.Period).HasConversion<int>();
                entity.Property(e => e.CashbackAwarded).HasColumnType("decimal(18,2)");
                entity.Property(e => e.RewardSummary).HasMaxLength(250);
                entity.HasIndex(e => new { e.Period, e.Rank });
                entity.HasIndex(e => new { e.AccountId, e.Period });
                entity.HasOne(e => e.Account)
                    .WithMany()
                    .HasForeignKey(e => e.AccountId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Snapshot)
                    .WithMany(s => s.Standings)
                    .HasForeignKey(e => e.SnapshotId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure Redemption
            modelBuilder.Entity<Redemption>(entity =>
            {
                entity.HasKey(e => e.RedemptionId);
                entity.Property(e => e.RedemptionId).ValueGeneratedOnAdd();
                entity.Property(e => e.RewardType).HasMaxLength(100).IsRequired();
                entity.Property(e => e.PromoCode).HasMaxLength(5).IsRequired();
                entity.HasOne(e => e.Account)
                    .WithMany()
                    .HasForeignKey(e => e.AccountId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Removed SavedSearch entity

            // Configure Referral
            modelBuilder.Entity<Referral>(entity =>
            {
                entity.HasKey(e => e.ReferralId);
                entity.Property(e => e.ReferralId).ValueGeneratedOnAdd();
                entity.Property(e => e.ReferralCode).HasMaxLength(20).IsRequired();
                entity.HasOne(e => e.Referrer)
                    .WithMany()
                    .HasForeignKey(e => e.ReferrerId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.ReferredUser)
                    .WithMany()
                    .HasForeignKey(e => e.ReferredUserId)
                    .OnDelete(DeleteBehavior.SetNull);
                entity.HasIndex(e => e.ReferralCode).IsUnique();
            });

            // Configure PropertyView
            modelBuilder.Entity<PropertyView>(entity =>
            {
                entity.HasKey(e => e.ViewId);
                entity.Property(e => e.ViewId).ValueGeneratedOnAdd();
                entity.HasOne(e => e.Property)
                    .WithMany()
                    .HasForeignKey(e => e.PropertyId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.SetNull);
            });

            // Configure ParentProperty
            modelBuilder.Entity<ParentProperty>(entity =>
            {
                entity.HasKey(e => e.ParentPropertyId);
                entity.Property(e => e.ParentPropertyId).ValueGeneratedOnAdd();
                entity.Property(e => e.ProjectName).HasMaxLength(200);
                entity.Property(e => e.Type).HasMaxLength(100).IsRequired();
                entity.Property(e => e.FinishingType).HasMaxLength(100).IsRequired();
                entity.HasOne(e => e.Project)
                    .WithMany()
                    .HasForeignKey(e => e.ProjectId)
                    .OnDelete(DeleteBehavior.SetNull);
            });


            // Configure GoldPrice
            modelBuilder.Entity<GoldPrice>(entity =>
            {
                entity.HasKey(e => e.GoldPriceId);
                entity.Property(e => e.GoldPriceId).ValueGeneratedOnAdd();
                entity.Property(e => e.PricePerGram).HasColumnType("decimal(18,2)").IsRequired();
                entity.Property(e => e.Source).HasMaxLength(50).IsRequired();
            });

            // Configure PropertyPriceHistory
            modelBuilder.Entity<PropertyPriceHistory>(entity =>
            {
                entity.HasKey(e => e.PriceHistoryId);
                entity.Property(e => e.PriceHistoryId).ValueGeneratedOnAdd();
                entity.Property(e => e.Price).HasColumnType("decimal(18,2)").IsRequired();
                entity.Property(e => e.Source).HasMaxLength(50).IsRequired();
                entity.Property(e => e.Notes).HasMaxLength(500);
                entity.HasOne(e => e.ParentProperty)
                    .WithMany(p => p.PriceHistories)
                    .HasForeignKey(e => e.ParentPropertyId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Auction)
                    .WithMany()
                    .HasForeignKey(e => e.AuctionId)
                    .OnDelete(DeleteBehavior.SetNull);
                entity.HasOne(e => e.ChildProperty)
                    .WithMany()
                    .HasForeignKey(e => e.ChildPropertyId)
                    .OnDelete(DeleteBehavior.SetNull);
            });

            // Configure NewsArticle
            modelBuilder.Entity<NewsArticle>(entity =>
            {
                entity.HasKey(e => e.NewsArticleId);
                entity.Property(e => e.NewsArticleId).ValueGeneratedOnAdd();
                entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
                entity.Property(e => e.Content).IsRequired();
                entity.Property(e => e.Category).HasMaxLength(50);
                entity.Property(e => e.PublishedDate).IsRequired();
                entity.Property(e => e.CreatedAt).IsRequired();
                entity.Property(e => e.IsPublished).IsRequired();
                entity.HasOne(e => e.Developer)
                    .WithMany()
                    .HasForeignKey(e => e.DeveloperId)
                    .OnDelete(DeleteBehavior.SetNull);
            });

            // Configure NewsImage
            modelBuilder.Entity<NewsImage>(entity =>
            {
                entity.HasKey(e => e.NewsImageId);
                entity.Property(e => e.NewsImageId).ValueGeneratedOnAdd();
                entity.Property(e => e.ImageUrl).HasMaxLength(500).IsRequired();
                entity.Property(e => e.DisplayOrder).IsRequired();
                entity.HasOne(e => e.NewsArticle)
                    .WithMany(n => n.Images)
                    .HasForeignKey(e => e.NewsArticleId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Faq>(entity =>
            {
                entity.HasKey(e => e.FaqId);
                entity.Property(e => e.FaqId).ValueGeneratedOnAdd();
                entity.Property(e => e.Question).HasMaxLength(250).IsRequired();
                entity.Property(e => e.Answer).IsRequired();
                entity.Property(e => e.DisplayOrder).HasDefaultValue(0);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");

                entity.HasIndex(e => e.DisplayOrder);

                // FAQ seed data with UUIDs
                entity.HasData(
                    new Faq { FaqId = Guid.Parse("11111111-1111-1111-1111-111111111111"), Question = "How do I list a new property?", Answer = "Go to the Add Property screen, fill out the mandatory fields, upload images, and submit for review.", DisplayOrder = 1, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = Guid.Parse("22222222-2222-2222-2222-222222222222"), Question = "Can I edit my property after submission?", Answer = "Yes, open the property from your dashboard and tap Edit. Changes trigger a short review cycle.", DisplayOrder = 2, CreatedAt = new DateTime(2025, 1, 1, 0, 1, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = Guid.Parse("33333333-3333-3333-3333-333333333333"), Question = "What documents are required?", Answer = "At minimum you need proof of ownership and unit floor plans. Optional docs speed up verification.", DisplayOrder = 3, CreatedAt = new DateTime(2025, 1, 1, 0, 2, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = Guid.Parse("44444444-4444-4444-4444-444444444444"), Question = "How do auctions work?", Answer = "Approved sellers can request an auction. Once approved, buyers place bids until the auction end date.", DisplayOrder = 4, CreatedAt = new DateTime(2025, 1, 1, 0, 3, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = Guid.Parse("55555555-5555-5555-5555-555555555555"), Question = "How is property pricing estimated?", Answer = "Pricing leverages market comps, developer data, and our AI valuation engine.", DisplayOrder = 5, CreatedAt = new DateTime(2025, 1, 1, 0, 4, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = Guid.Parse("66666666-6666-6666-6666-666666666666"), Question = "Can I save favourite properties?", Answer = "Yes, tap the bookmark icon on any property to store it in your Saved list.", DisplayOrder = 6, CreatedAt = new DateTime(2025, 1, 1, 0, 5, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = Guid.Parse("77777777-7777-7777-7777-777777777777"), Question = "How do I contact a developer?", Answer = "Use the Contact Developer button on the project or property page to open a chat.", DisplayOrder = 7, CreatedAt = new DateTime(2025, 1, 1, 0, 6, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = Guid.Parse("88888888-8888-8888-8888-888888888888"), Question = "What is the AI Broker?", Answer = "Our AI Broker suggests opportunities and answers investment questions in real time.", DisplayOrder = 8, CreatedAt = new DateTime(2025, 1, 1, 0, 7, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = Guid.Parse("99999999-9999-9999-9999-999999999999"), Question = "How do I track project updates?", Answer = "Follow projects to receive push notifications and see updates in your feed.", DisplayOrder = 9, CreatedAt = new DateTime(2025, 1, 1, 0, 8, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"), Question = "How can I reset my password?", Answer = "Tap Forgot Password on the login screen and follow the emailed instructions.", DisplayOrder = 10, CreatedAt = new DateTime(2025, 1, 1, 0, 9, 0, DateTimeKind.Utc) }
                );
            });

            // Configure UserAchievement
            modelBuilder.Entity<UserAchievement>(entity =>
            {
                entity.HasKey(e => e.AchievementId);
                entity.Property(e => e.AchievementId).ValueGeneratedOnAdd();
                entity.Property(e => e.AchievementType).HasConversion<int>();
                entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
                entity.Property(e => e.Description).HasMaxLength(500);
                entity.HasOne(e => e.Account)
                    .WithMany()
                    .HasForeignKey(e => e.AccountId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure LiveStream
            modelBuilder.Entity<LiveStream>(entity =>
            {
                entity.HasKey(e => e.StreamId);
                entity.Property(e => e.StreamId).ValueGeneratedOnAdd();
                entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
                entity.Property(e => e.StreamUrl).HasMaxLength(500).IsRequired();
                entity.Property(e => e.ThumbnailUrl).HasMaxLength(500);
                entity.Property(e => e.Status).HasMaxLength(20).IsRequired();
                entity.HasOne(e => e.Developer)
                    .WithMany()
                    .HasForeignKey(e => e.DeveloperId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure StreamViewer
            modelBuilder.Entity<StreamViewer>(entity =>
            {
                entity.HasKey(e => e.ViewerId);
                entity.Property(e => e.ViewerId).ValueGeneratedOnAdd();
                entity.HasOne(e => e.Stream)
                    .WithMany(s => s.Viewers)
                    .HasForeignKey(e => e.StreamId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasIndex(e => new { e.StreamId, e.UserId }).IsUnique();
            });

            // Configure StreamChatMessage
            modelBuilder.Entity<StreamChatMessage>(entity =>
            {
                entity.HasKey(e => e.MessageId);
                entity.Property(e => e.MessageId).ValueGeneratedOnAdd();
                entity.Property(e => e.Message).HasMaxLength(500).IsRequired();
                entity.HasOne(e => e.Stream)
                    .WithMany()
                    .HasForeignKey(e => e.StreamId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasIndex(e => e.StreamId);
                entity.HasIndex(e => e.CreatedAt);
            });
        }
    }
}
