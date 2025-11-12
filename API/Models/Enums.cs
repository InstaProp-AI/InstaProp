using System;
using System.Collections.Generic;
using System.Linq;

namespace PropertyFlipperAPI.Models
{
    public enum AccountType
    {
        User = 0,
        Developer = 1,
        Admin = 2
    }

    public enum VerificationStatus
    {
        NotVerified = 0,
        Pending = 1,
        Verified = 2
    }

    public enum PropertyType
    {
        Apartment = 0,
        Villa = 1,
        Townhouse = 2,
        Twinhouse = 3,
        Duplex = 4,
        Penthouse = 5,
        Studio = 6,
        Chalet = 7,
        ServicedApartment = 8,
        ServicedStudio = 9,
        Office = 10,
        Retail = 11,
        Clinic = 12,
        Pharmacy = 13,
        Cabin = 14,
        BrandedApartment = 15,
        BrandedVilla = 16,
        LuxuryApartment = 17,
        UltraLuxuryApartment = 18,
        UltraLuxuryVilla = 19,
        OneStoryVilla = 20,
        Loft = 21,
        Other = 99
    }

    public static class PropertyTypeHelper
    {
        private static readonly IReadOnlyDictionary<PropertyType, string> DisplayNames =
            new Dictionary<PropertyType, string>
            {
                [PropertyType.Apartment] = "Apartment",
                [PropertyType.Villa] = "Villa",
                [PropertyType.Townhouse] = "Townhouse",
                [PropertyType.Twinhouse] = "Twinhouse",
                [PropertyType.Duplex] = "Duplex",
                [PropertyType.Penthouse] = "Penthouse",
                [PropertyType.Studio] = "Studio",
                [PropertyType.Chalet] = "Chalet",
                [PropertyType.ServicedApartment] = "Serviced Apartment",
                [PropertyType.ServicedStudio] = "Serviced Studio",
                [PropertyType.Office] = "Office",
                [PropertyType.Retail] = "Retail",
                [PropertyType.Clinic] = "Clinic",
                [PropertyType.Pharmacy] = "Pharmacy",
                [PropertyType.Cabin] = "Cabin",
                [PropertyType.BrandedApartment] = "Branded Apartment",
                [PropertyType.BrandedVilla] = "Branded Villa",
                [PropertyType.LuxuryApartment] = "Luxury Apartment",
                [PropertyType.UltraLuxuryApartment] = "Ultra Luxury Apartment",
                [PropertyType.UltraLuxuryVilla] = "Ultra Luxury Villa",
                [PropertyType.OneStoryVilla] = "One-story Villa",
                [PropertyType.Loft] = "Loft",
                [PropertyType.Other] = "Other"
            };

        public static IReadOnlyList<PropertyType> OrderedValues { get; } = new[]
        {
            PropertyType.Apartment,
            PropertyType.Villa,
            PropertyType.Townhouse,
            PropertyType.Twinhouse,
            PropertyType.Duplex,
            PropertyType.Penthouse,
            PropertyType.Studio,
            PropertyType.Chalet,
            PropertyType.ServicedApartment,
            PropertyType.ServicedStudio,
            PropertyType.Office,
            PropertyType.Retail,
            PropertyType.Clinic,
            PropertyType.Pharmacy,
            PropertyType.Cabin,
            PropertyType.BrandedApartment,
            PropertyType.BrandedVilla,
            PropertyType.LuxuryApartment,
            PropertyType.UltraLuxuryApartment,
            PropertyType.UltraLuxuryVilla,
            PropertyType.OneStoryVilla,
            PropertyType.Loft,
            PropertyType.Other
        };

        public static string ToDisplayName(this PropertyType type) =>
            DisplayNames.TryGetValue(type, out var label) ? label : "Other";

        public static PropertyType FromDisplayName(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return PropertyType.Other;
            }

            foreach (var kvp in DisplayNames)
            {
                if (string.Equals(kvp.Value, value, StringComparison.OrdinalIgnoreCase))
                {
                    return kvp.Key;
                }
            }

            var collapsed = new string(value.Where(char.IsLetterOrDigit).ToArray());
            foreach (var kvp in DisplayNames)
            {
                var normalized = new string(kvp.Value.Where(char.IsLetterOrDigit).ToArray());
                if (string.Equals(normalized, collapsed, StringComparison.OrdinalIgnoreCase))
                {
                    return kvp.Key;
                }
            }

            if (Enum.TryParse<PropertyType>(value, true, out var parsed))
            {
                return parsed;
            }

            if (Enum.TryParse<PropertyType>(collapsed, true, out parsed))
            {
                return parsed;
            }

            return PropertyType.Other;
        }
    }

    public enum FinishingType
    {
        Finished = 0,
        SemiFinished = 1,
        CoreAndShell = 2,
        SuperLuxury = 3
    }

    public enum PropertyStatus
    {
        NotApproved = 0,
        Pending = 1,
        Approved = 2
    }

    public enum AuctionStatus
    {
        Requested = 0,
        Approved = 1,
        Active = 2,
        Closed = 3,
        Cancelled = 4,
        Completed = 5
    }
}

