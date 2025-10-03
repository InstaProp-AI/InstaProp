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

            // Add any custom configuration here if needed
        }
    }
}
