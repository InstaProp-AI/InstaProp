using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Models;

namespace PropertyFlipperAPI.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) {}

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
        
        // Phase 3: Project enhancements
        public DbSet<ProjectMilestone> ProjectMilestones { get; set; }
        public DbSet<ProjectUpdate> ProjectUpdates { get; set; }
        
        // Phase 4: Gamification & Engagement
        public DbSet<UserReward> UserRewards { get; set; }
        public DbSet<UserBadge> UserBadges { get; set; }
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

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure Account
            modelBuilder.Entity<Account>(entity =>
            {
                entity.HasKey(e => e.AccountId);
                entity.Property(e => e.AccountId).ValueGeneratedOnAdd();
                entity.Property(e => e.FirstName).HasMaxLength(100);
                entity.Property(e => e.LastName).HasMaxLength(100);
                entity.Property(e => e.PhoneNumber).HasMaxLength(20).IsRequired();
                entity.Property(e => e.Email).HasMaxLength(255).IsRequired();
                entity.Property(e => e.Type).HasConversion<int>();
                entity.Property(e => e.HashedPassword).HasMaxLength(255); // Nullable for OAuth users
            });

            // Configure Property (now ChildProperty)
            modelBuilder.Entity<ChildProperty>(entity =>
            {
                entity.HasKey(e => e.PropertyId);
                entity.Property(e => e.PropertyId).ValueGeneratedOnAdd();
                entity.Property(e => e.Name).HasMaxLength(500).IsRequired();
                entity.Property(e => e.Location).HasMaxLength(500);
                entity.Property(e => e.Type).HasConversion<int>();
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
                entity.Property(e => e.ProjectName).HasMaxLength(200).IsRequired();
                entity.Property(e => e.PropertyType).HasMaxLength(100).IsRequired();
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
        }
    }
}
