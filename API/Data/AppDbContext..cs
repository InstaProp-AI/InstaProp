using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Models;

namespace PropertyFlipperAPI.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) {}

        public DbSet<User> Users { get; set; }
        public DbSet<Property> Properties { get; set; }
        public DbSet<PropertyDoc> PropertyDocs { get; set; }
        public DbSet<UserDoc> UserDocs { get; set; }
        public DbSet<Auction> Auctions { get; set; }
        public DbSet<Bid> Bids { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure User
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(e => e.UserId);
                entity.Property(e => e.UserId).ValueGeneratedOnAdd();
                entity.Property(e => e.FirstName).HasMaxLength(100);
                entity.Property(e => e.LastName).HasMaxLength(100);
                entity.Property(e => e.PhoneNumber).HasMaxLength(20).IsRequired();
                entity.Property(e => e.Email).HasMaxLength(255).IsRequired();
                entity.Property(e => e.Gender).HasMaxLength(10).IsRequired();
                entity.Property(e => e.HashedPassword).HasMaxLength(255).IsRequired();
            });

            // Configure Property
            modelBuilder.Entity<Property>(entity =>
            {
                entity.HasKey(e => e.PropertyId);
                entity.Property(e => e.PropertyId).ValueGeneratedOnAdd();
                entity.Property(e => e.Name).HasMaxLength(200).IsRequired();
                entity.Property(e => e.Location).HasMaxLength(255);
                entity.Property(e => e.StartingPrice).HasColumnType("decimal(18,2)");
                entity.HasOne(e => e.Owner)
                    .WithMany(u => u.Properties)
                    .HasForeignKey(e => e.OwnerId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Configure Auction
            modelBuilder.Entity<Auction>(entity =>
            {
                entity.HasKey(e => e.AuctionId);
                entity.Property(e => e.AuctionId).ValueGeneratedOnAdd();
                entity.Property(e => e.StartAt).HasColumnType("decimal(18,2)");
                entity.Property(e => e.BuyNowPrice).HasColumnType("decimal(18,2)");
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
        }
    }
}
