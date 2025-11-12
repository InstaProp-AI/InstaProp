using System;
using System.Collections.Generic;
using System.Linq;

namespace PropertyFlipperAPI.Models
{
    public class AuctionDto
    {
        public long AuctionId { get; set; }
        public long PropertyId { get; set; }
        public AuctionPropertyDto Property { get; set; }
        public decimal StartPrice { get; set; }
        public decimal CurrentPrice { get; set; }
        public DateTime StartAt { get; set; }
        public DateTime EndAt { get; set; } // Calculated: StartAt + Duration
        public int Duration { get; set; }
        public int BidCount { get; set; }
        public string Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public decimal? CashToClose { get; set; }
        public decimal? EquityPaid { get; set; }
        public string? MasterPlanUrl { get; set; }

        public static AuctionDto FromAuction(Auction auction)
        {
            var summary = auction.Property?.InstallmentSummary;

            InstallmentSummaryDto? summaryDto = null;
            decimal? cashToClose = null;
            decimal? equityPaid = null;

            if (summary != null)
            {
                var downPaymentAmount = summary.DownPaymentPercent > 0
                    ? Math.Round(summary.ContractedPrice * summary.DownPaymentPercent / 100m, 2)
                    : 0m;

                summaryDto = new InstallmentSummaryDto
                {
                    SummaryId = summary.SummaryId,
                    ContractedPrice = summary.ContractedPrice,
                    TotalPaid = summary.TotalPaid,
                    DownPaymentPercent = summary.DownPaymentPercent,
                    DownPaymentAmount = downPaymentAmount,
                    TermYears = summary.TermYears,
                    InstallmentEndDate = summary.InstallmentEndDate,
                    IsFullyPaid = summary.IsFullyPaid,
                    RemainingBalance = summary.RemainingBalance,
                    CreatedAt = summary.CreatedAt,
                    UpdatedAt = summary.UpdatedAt
                };

                equityPaid = summary.TotalPaid > 0 ? summary.TotalPaid : null;
                cashToClose = Math.Max(0, summary.RemainingBalance);
            }

            var documentDtos = auction.Property?.PropertyDocs?
                .Select(doc => new PropertyDocumentDto
                {
                    DocId = doc.DocId,
                    PropertyId = doc.PropertyId,
                    DocType = doc.DocType,
                    ImgUrl = doc.ImgUrl,
                    UploadedAt = doc.UploadedAt
                })
                .OrderByDescending(d => d.UploadedAt)
                .ToList() ?? new List<PropertyDocumentDto>();

            var masterPlanUrl = ResolveMasterPlanUrl(documentDtos);

            // Use the database values directly instead of calculating from bids collection
            return new AuctionDto
            {
                AuctionId = auction.AuctionId,
                PropertyId = auction.PropertyId,
                Property = auction.Property != null ? new AuctionPropertyDto
                {
                    PropertyId = auction.Property.PropertyId,
                    Name = auction.Property.Name,
                    Description = auction.Property.Description,
                    Location = auction.Property.Location,
                    Type = PropertyTypeHelper.ToDisplayName(auction.Property.Type),
                    Status = auction.Property.Status.ToString(),
                    Bedrooms = auction.Property.Bedrooms,
                    Bathrooms = auction.Property.Bathrooms,
                    SquareFeet = auction.Property.SquareFeet,
                    YearBuilt = auction.Property.YearBuilt,
                    ImageUrl = auction.Property.ImageUrl,
                    Project = auction.Property.Project?.Name,
                    PropertyImages = auction.Property.PropertyImages?.Select(img => new PropertyImageDto
                    {
                        PropertyImageId = img.PropertyImageId,
                        PropertyId = img.PropertyId,
                        ImageUrl = img.ImageUrl,
                        ImageType = img.ImageType,
                        IsMainImage = img.IsMainImage,
                        DisplayOrder = img.DisplayOrder
                    }).ToList() ?? new List<PropertyImageDto>(),
                    InstallmentSummary = summaryDto,
                    PropertyDocs = documentDtos
                } : null,
                StartPrice = auction.StartPrice,
                CurrentPrice = auction.CurrentPrice, // Use database value
                StartAt = auction.StartAt,
                EndAt = auction.StartAt.AddHours(auction.Duration), // Calculated
                Duration = auction.Duration,
                BidCount = auction.BidCount, // Use database value
                Status = auction.Status,
                CreatedAt = auction.CreatedAt,
                CashToClose = cashToClose,
                EquityPaid = equityPaid,
                MasterPlanUrl = masterPlanUrl
            };
        }

        private static string? ResolveMasterPlanUrl(IEnumerable<PropertyDocumentDto> documents)
        {
            var exactMatch = documents.FirstOrDefault(d =>
                string.Equals(d.DocType, "Master Plan", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(d.DocType, "MasterPlan", StringComparison.OrdinalIgnoreCase));

            if (exactMatch != null)
            {
                return exactMatch.ImgUrl;
            }

            var fallback = documents.FirstOrDefault(d =>
            {
                if (string.IsNullOrWhiteSpace(d.DocType))
                    return false;

                var normalized = d.DocType.ToLowerInvariant();
                return normalized.Contains("master") ||
                       normalized.Contains("site plan") ||
                       normalized.Contains("layout") ||
                       normalized.Contains("floor plan") ||
                       normalized.Contains("plan");
            });

            return fallback?.ImgUrl;
        }
    }

    public class AuctionPropertyDto
    {
        public long PropertyId { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string Location { get; set; }
        public string Type { get; set; }
        public string Status { get; set; }
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public int SquareFeet { get; set; }
        public int YearBuilt { get; set; }
        public string ImageUrl { get; set; }
        public string Project { get; set; }
        public List<PropertyImageDto> PropertyImages { get; set; } = new List<PropertyImageDto>();
        public InstallmentSummaryDto? InstallmentSummary { get; set; }
        public List<PropertyDocumentDto> PropertyDocs { get; set; } = new List<PropertyDocumentDto>();
    }

    public class PropertyImageDto
    {
        public long PropertyImageId { get; set; }
        public long PropertyId { get; set; }
        public string ImageUrl { get; set; }
        public string ImageType { get; set; }
        public bool IsMainImage { get; set; }
        public int DisplayOrder { get; set; }
    }

    public class PropertyDocumentDto
    {
        public long DocId { get; set; }
        public int PropertyId { get; set; }
        public string DocType { get; set; }
        public string ImgUrl { get; set; }
        public DateTime UploadedAt { get; set; }
    }

    public class InstallmentSummaryDto
    {
        public int SummaryId { get; set; }
        public decimal ContractedPrice { get; set; }
        public decimal TotalPaid { get; set; }
        public decimal DownPaymentPercent { get; set; }
        public decimal DownPaymentAmount { get; set; }
        public int? TermYears { get; set; }
        public DateTime? InstallmentEndDate { get; set; }
        public bool IsFullyPaid { get; set; }
        public decimal RemainingBalance { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
