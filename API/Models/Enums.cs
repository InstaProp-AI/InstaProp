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
        Resale = 0,
        Primary = 1
    }

    public enum PropertyStatus
    {
        NotApproved = 0,
        Pending = 1,
        Approved = 2
    }
}

