namespace PropertyFlipperAPI.Models
{
    public class VerificationResult
    {
        public bool Success { get; set; }
        public string? ErrorMessage { get; set; }

        public static VerificationResult CreateSuccess()
        {
            return new VerificationResult { Success = true };
        }

        public static VerificationResult CreateError(string errorMessage)
        {
            return new VerificationResult { Success = false, ErrorMessage = errorMessage };
        }
    }
}
