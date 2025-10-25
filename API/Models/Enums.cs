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
        Duplex = 3,
        Penthouse = 4,
        Studio = 5,
        Loft = 6
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

