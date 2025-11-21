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
        public DbSet<Account> Accounts { get; set; }
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

        // Community System
        public DbSet<Community> Communities { get; set; }
        public DbSet<CommunityMember> CommunityMembers { get; set; }
        public DbSet<CommunityPost> CommunityPosts { get; set; }
        public DbSet<PostComment> PostComments { get; set; }
        public DbSet<PostLike> PostLikes { get; set; }
        public DbSet<CommentLike> CommentLikes { get; set; }
        public DbSet<PostCategory> PostCategories { get; set; }
        public DbSet<InstallmentSummary> InstallmentSummaries { get; set; }
        public DbSet<Poll> Polls { get; set; }
        public DbSet<PollVote> PollVotes { get; set; }
        
        // Enhanced Community Features
        public DbSet<PostReaction> PostReactions { get; set; }
        public DbSet<CommentReaction> CommentReactions { get; set; }
        public DbSet<PostBookmark> PostBookmarks { get; set; }
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
                entity.Property(e => e.RoleId).ValueGeneratedNever(); // IDs are manually set (hardcoded constants)
                entity.Property(e => e.RoleName).HasMaxLength(50).IsRequired();
                entity.Property(e => e.Description).HasMaxLength(500);
                entity.HasIndex(e => e.RoleName).IsUnique();
            });

            // Configure Account
            modelBuilder.Entity<Account>(entity =>
            {
                entity.HasKey(e => e.AccountId);
                entity.Property(e => e.AccountId).ValueGeneratedOnAdd();
                entity.Property(e => e.FirstName).HasMaxLength(100);
                entity.Property(e => e.LastName).HasMaxLength(100);
                entity.Property(e => e.PhoneNumber).HasMaxLength(20).IsRequired();
                entity.Property(e => e.Email).HasMaxLength(255).IsRequired();
                entity.Property(e => e.RoleId).IsRequired();
                entity.Property(e => e.HashedPassword).HasMaxLength(255); // Nullable for OAuth users
                
                // Configure Role relationship
                entity.HasOne(e => e.Role)
                    .WithMany(r => r.Accounts)
                    .HasForeignKey(e => e.RoleId)
                    .OnDelete(DeleteBehavior.Restrict); // Prevent deletion of roles that are in use
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

                entity.HasData(
                    new Faq { FaqId = 1, Question = "How do I list a new property?", Answer = "Go to the Add Property screen, fill out the mandatory fields, upload images, and submit for review.", DisplayOrder = 1, CreatedAt = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = 2, Question = "Can I edit my property after submission?", Answer = "Yes, open the property from your dashboard and tap Edit. Changes trigger a short review cycle.", DisplayOrder = 2, CreatedAt = new DateTime(2025, 1, 1, 0, 1, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = 3, Question = "What documents are required?", Answer = "At minimum you need proof of ownership and unit floor plans. Optional docs speed up verification.", DisplayOrder = 3, CreatedAt = new DateTime(2025, 1, 1, 0, 2, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = 4, Question = "How do auctions work?", Answer = "Approved sellers can request an auction. Once approved, buyers place bids until the auction end date.", DisplayOrder = 4, CreatedAt = new DateTime(2025, 1, 1, 0, 3, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = 5, Question = "How is property pricing estimated?", Answer = "Pricing leverages market comps, developer data, and our AI valuation engine.", DisplayOrder = 5, CreatedAt = new DateTime(2025, 1, 1, 0, 4, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = 6, Question = "Can I save favourite properties?", Answer = "Yes, tap the bookmark icon on any property to store it in your Saved list.", DisplayOrder = 6, CreatedAt = new DateTime(2025, 1, 1, 0, 5, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = 7, Question = "How do I contact a developer?", Answer = "Use the Contact Developer button on the project or property page to open a chat.", DisplayOrder = 7, CreatedAt = new DateTime(2025, 1, 1, 0, 6, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = 8, Question = "What is the AI Broker?", Answer = "Our AI Broker suggests opportunities and answers investment questions in real time.", DisplayOrder = 8, CreatedAt = new DateTime(2025, 1, 1, 0, 7, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = 9, Question = "How do I track project updates?", Answer = "Follow projects to receive push notifications and see updates in your feed.", DisplayOrder = 9, CreatedAt = new DateTime(2025, 1, 1, 0, 8, 0, DateTimeKind.Utc) },
                    new Faq { FaqId = 10, Question = "How can I reset my password?", Answer = "Tap Forgot Password on the login screen and follow the emailed instructions.", DisplayOrder = 10, CreatedAt = new DateTime(2025, 1, 1, 0, 9, 0, DateTimeKind.Utc) }
                );
            });

            // Configure Community
            modelBuilder.Entity<Community>(entity =>
            {
                entity.HasKey(e => e.CommunityId);
                entity.Property(e => e.CommunityId).ValueGeneratedOnAdd();
                entity.Property(e => e.Name).HasMaxLength(200).IsRequired();
                entity.Property(e => e.ScopeType).HasConversion<int>();
                entity.Property(e => e.AccessType).HasConversion<int>();
                entity.HasOne(e => e.CreatedBy)
                    .WithMany()
                    .HasForeignKey(e => e.CreatedById)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Configure CommunityMember
            modelBuilder.Entity<CommunityMember>(entity =>
            {
                entity.HasKey(e => e.MemberId);
                entity.Property(e => e.MemberId).ValueGeneratedOnAdd();
                entity.Property(e => e.Role).HasConversion<int>();
                entity.HasOne(e => e.Community)
                    .WithMany(c => c.Members)
                    .HasForeignKey(e => e.CommunityId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Account)
                    .WithMany()
                    .HasForeignKey(e => e.AccountId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasIndex(e => new { e.CommunityId, e.AccountId }).IsUnique();
            });

            // Configure CommunityPost
            modelBuilder.Entity<CommunityPost>(entity =>
            {
                entity.HasKey(e => e.PostId);
                entity.Property(e => e.PostId).ValueGeneratedOnAdd();
                entity.Property(e => e.ImageUrl).HasMaxLength(500);
                entity.Property(e => e.PostType).HasConversion<int>();
                entity.HasOne(e => e.Community)
                    .WithMany(c => c.Posts)
                    .HasForeignKey(e => e.CommunityId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Author)
                    .WithMany()
                    .HasForeignKey(e => e.AuthorId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Configure PostComment
            modelBuilder.Entity<PostComment>(entity =>
            {
                entity.HasKey(e => e.CommentId);
                entity.Property(e => e.CommentId).ValueGeneratedOnAdd();
                entity.HasOne(e => e.Post)
                    .WithMany(p => p.Comments)
                    .HasForeignKey(e => e.PostId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Author)
                    .WithMany()
                    .HasForeignKey(e => e.AuthorId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.ParentComment)
                    .WithMany(p => p.Replies)
                    .HasForeignKey(e => e.ParentCommentId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Configure PostLike
            modelBuilder.Entity<PostLike>(entity =>
            {
                entity.HasKey(e => e.LikeId);
                entity.Property(e => e.LikeId).ValueGeneratedOnAdd();
                entity.HasOne(e => e.Post)
                    .WithMany(p => p.Likes)
                    .HasForeignKey(e => e.PostId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Account)
                    .WithMany()
                    .HasForeignKey(e => e.AccountId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasIndex(e => new { e.PostId, e.AccountId }).IsUnique();
            });

            // Configure CommentLike
            modelBuilder.Entity<CommentLike>(entity =>
            {
                entity.HasKey(e => e.LikeId);
                entity.Property(e => e.LikeId).ValueGeneratedOnAdd();
                entity.HasOne(e => e.Comment)
                    .WithMany(c => c.Likes)
                    .HasForeignKey(e => e.CommentId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Account)
                    .WithMany()
                    .HasForeignKey(e => e.AccountId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasIndex(e => new { e.CommentId, e.AccountId }).IsUnique();
            });

            // Configure PostCategory
            modelBuilder.Entity<PostCategory>(entity =>
            {
                entity.HasKey(e => e.CategoryId);
                entity.Property(e => e.CategoryId).ValueGeneratedOnAdd();
                entity.Property(e => e.CategoryName).HasMaxLength(50).IsRequired();
                entity.HasOne(e => e.Post)
                    .WithMany(p => p.Categories)
                    .HasForeignKey(e => e.PostId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure Poll
            modelBuilder.Entity<Poll>(entity =>
            {
                entity.HasKey(e => e.PollId);
                entity.Property(e => e.PollId).ValueGeneratedOnAdd();
                entity.HasOne(e => e.Post)
                    .WithOne(p => p.Poll)
                    .HasForeignKey<Poll>(e => e.PostId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure PollVote
            modelBuilder.Entity<PollVote>(entity =>
            {
                entity.HasKey(e => e.VoteId);
                entity.Property(e => e.VoteId).ValueGeneratedOnAdd();
                entity.HasOne(e => e.Poll)
                    .WithMany(p => p.Votes)
                    .HasForeignKey(e => e.PollId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Account)
                    .WithMany()
                    .HasForeignKey(e => e.AccountId)
                    .OnDelete(DeleteBehavior.Cascade);
                // Allow multiple selections by same user across options
                entity.HasIndex(e => new { e.PollId, e.AccountId, e.OptionIndex }).IsUnique();
            });

            // Configure PostReaction
            modelBuilder.Entity<PostReaction>(entity =>
            {
                entity.HasKey(e => e.ReactionId);
                entity.Property(e => e.ReactionId).ValueGeneratedOnAdd();
                entity.Property(e => e.ReactionType).HasConversion<int>();
                entity.HasOne(e => e.Post)
                    .WithMany()
                    .HasForeignKey(e => e.PostId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Account)
                    .WithMany()
                    .HasForeignKey(e => e.AccountId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasIndex(e => new { e.PostId, e.AccountId, e.ReactionType }).IsUnique();
            });

            // Configure CommentReaction
            modelBuilder.Entity<CommentReaction>(entity =>
            {
                entity.HasKey(e => e.ReactionId);
                entity.Property(e => e.ReactionId).ValueGeneratedOnAdd();
                entity.Property(e => e.ReactionType).HasConversion<int>();
                entity.HasOne(e => e.Comment)
                    .WithMany()
                    .HasForeignKey(e => e.CommentId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Account)
                    .WithMany()
                    .HasForeignKey(e => e.AccountId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasIndex(e => new { e.CommentId, e.AccountId, e.ReactionType }).IsUnique();
            });

            // Configure PostBookmark
            modelBuilder.Entity<PostBookmark>(entity =>
            {
                entity.HasKey(e => e.BookmarkId);
                entity.Property(e => e.BookmarkId).ValueGeneratedOnAdd();
                entity.HasOne(e => e.Post)
                    .WithMany(p => p.Bookmarks)
                    .HasForeignKey(e => e.PostId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Account)
                    .WithMany(a => a.BookmarkedPosts)
                    .HasForeignKey(e => e.AccountId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.HasIndex(e => new { e.PostId, e.AccountId }).IsUnique();
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
