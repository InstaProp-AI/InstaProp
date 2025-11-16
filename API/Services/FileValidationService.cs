using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace InstapropAPI.Services
{
    /// <summary>
    /// Service for validating uploaded files using magic numbers (file signatures)
    /// to prevent malicious file uploads
    /// </summary>
    public class FileValidationService
    {
        // Maximum file size: 10 MB
        private const long MaxFileSize = 10 * 1024 * 1024;

        // File type signatures (magic numbers) - first bytes that identify file types
        private static readonly (byte[] Signature, string Extension, string MimeType)[] AllowedFileTypes = new[]
        {
            // JPEG files
            (new byte[] { 0xFF, 0xD8, 0xFF }, ".jpg", "image/jpeg"),
            (new byte[] { 0xFF, 0xD8, 0xFF }, ".jpeg", "image/jpeg"),
            
            // PNG files
            (new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }, ".png", "image/png"),
            
            // PDF files
            (new byte[] { 0x25, 0x50, 0x44, 0x46 }, ".pdf", "application/pdf")
        };

        // Known dangerous file signatures to explicitly reject
        private static readonly byte[][] DangerousSignatures = new[]
        {
            // PE executables (Windows .exe, .dll)
            new byte[] { 0x4D, 0x5A },
            
            // ELF executables (Linux)
            new byte[] { 0x7F, 0x45, 0x4C, 0x46 },
            
            // Mach-O executables (macOS)
            new byte[] { 0xCF, 0xFA, 0xED, 0xFE },
            new byte[] { 0xCE, 0xFA, 0xED, 0xFE },
            new byte[] { 0xFE, 0xED, 0xFA, 0xCE },
            new byte[] { 0xFE, 0xED, 0xFA, 0xCF },
            
            // ZIP archives (could contain executables)
            new byte[] { 0x50, 0x4B, 0x03, 0x04 },
            new byte[] { 0x50, 0x4B, 0x05, 0x06 },
            new byte[] { 0x50, 0x4B, 0x07, 0x08 },
            
            // RAR archives
            new byte[] { 0x52, 0x61, 0x72, 0x21, 0x1A, 0x07 },
            
            // 7-Zip archives
            new byte[] { 0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C },
            
            // TAR archives
            new byte[] { 0x75, 0x73, 0x74, 0x61, 0x72 },
            
            // Shell scripts
            new byte[] { 0x23, 0x21 }, // #! shebang
            
            // HTML files (could contain scripts)
            new byte[] { 0x3C, 0x68, 0x74, 0x6D, 0x6C }, // <html
            new byte[] { 0x3C, 0x48, 0x54, 0x4D, 0x4C }, // <HTML
            new byte[] { 0x3C, 0x21, 0x44, 0x4F, 0x43 }, // <!DOC
            
            // XML files (could contain scripts)
            new byte[] { 0x3C, 0x3F, 0x78, 0x6D, 0x6C }, // <?xml
        };

        /// <summary>
        /// Validates an uploaded file for security
        /// </summary>
        public async Task<FileValidationResult> ValidateFileAsync(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                return FileValidationResult.Fail("No file provided or file is empty.");
            }

            // Check file size
            if (file.Length > MaxFileSize)
            {
                return FileValidationResult.Fail($"File size exceeds maximum allowed size of {MaxFileSize / (1024 * 1024)} MB.");
            }

            // Check file extension
            var extension = Path.GetExtension(file.FileName)?.ToLowerInvariant();
            if (string.IsNullOrEmpty(extension))
            {
                return FileValidationResult.Fail("File must have an extension.");
            }

            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".pdf" };
            if (!allowedExtensions.Contains(extension))
            {
                return FileValidationResult.Fail($"File type '{extension}' is not allowed. Only .jpg, .jpeg, .png, and .pdf files are permitted.");
            }

            // Read file header to check magic numbers
            byte[] fileHeader;
            try
            {
                using var stream = file.OpenReadStream();
                
                // Read first 512 bytes (enough to check most file signatures)
                var headerSize = Math.Min(512, (int)stream.Length);
                fileHeader = new byte[headerSize];
                await stream.ReadAsync(fileHeader, 0, headerSize);
                stream.Position = 0; // Reset stream position
            }
            catch (Exception ex)
            {
                return FileValidationResult.Fail($"Error reading file: {ex.Message}");
            }

            // Check if file matches dangerous signatures
            if (IsDangerousFile(fileHeader))
            {
                return FileValidationResult.Fail("File contains dangerous content and has been rejected.");
            }

            // Validate file signature matches claimed extension
            var validationResult = ValidateFileSignature(fileHeader, extension);
            if (!validationResult.IsValid)
            {
                return validationResult;
            }

            // Additional validation for images
            if (extension == ".jpg" || extension == ".jpeg" || extension == ".png")
            {
                var imageValidation = await ValidateImageFileAsync(file);
                if (!imageValidation.IsValid)
                {
                    return imageValidation;
                }
            }

            // Additional validation for PDFs
            if (extension == ".pdf")
            {
                var pdfValidation = ValidatePdfFile(fileHeader);
                if (!pdfValidation.IsValid)
                {
                    return pdfValidation;
                }
            }

            return FileValidationResult.Success();
        }

        /// <summary>
        /// Checks if file header matches any dangerous file signatures
        /// </summary>
        private bool IsDangerousFile(byte[] fileHeader)
        {
            foreach (var dangerousSignature in DangerousSignatures)
            {
                if (fileHeader.Length >= dangerousSignature.Length)
                {
                    if (ByteArrayStartsWith(fileHeader, dangerousSignature))
                    {
                        return true;
                    }
                }
            }
            return false;
        }

        /// <summary>
        /// Validates that file signature matches the claimed extension
        /// </summary>
        private FileValidationResult ValidateFileSignature(byte[] fileHeader, string extension)
        {
            var matchingTypes = AllowedFileTypes
                .Where(ft => ft.Extension == extension)
                .ToList();

            if (!matchingTypes.Any())
            {
                return FileValidationResult.Fail($"Extension '{extension}' is not in the allowed list.");
            }

            foreach (var fileType in matchingTypes)
            {
                if (ByteArrayStartsWith(fileHeader, fileType.Signature))
                {
                    return FileValidationResult.Success();
                }
            }

            return FileValidationResult.Fail($"File content does not match the '{extension}' format. The file may be corrupted or renamed.");
        }

        /// <summary>
        /// Additional validation for image files
        /// </summary>
        private async Task<FileValidationResult> ValidateImageFileAsync(IFormFile file)
        {
            try
            {
                using var stream = file.OpenReadStream();
                
                // Try to read the image to ensure it's valid
                // Note: This is a basic check. In production, you might want to use
                // a library like ImageSharp for more thorough validation
                
                // Check minimum dimensions for images
                if (stream.Length < 100) // Very small file, likely not a real image
                {
                    return FileValidationResult.Fail("Image file is too small to be valid.");
                }

                return FileValidationResult.Success();
            }
            catch (Exception ex)
            {
                return FileValidationResult.Fail($"Invalid image file: {ex.Message}");
            }
        }

        /// <summary>
        /// Additional validation for PDF files
        /// </summary>
        private FileValidationResult ValidatePdfFile(byte[] fileHeader)
        {
            // Check for PDF header: %PDF-
            if (fileHeader.Length < 5)
            {
                return FileValidationResult.Fail("File is too small to be a valid PDF.");
            }

            // Verify PDF version is present (e.g., %PDF-1.4, %PDF-1.7)
            if (fileHeader.Length >= 8)
            {
                var pdfVersion = System.Text.Encoding.ASCII.GetString(fileHeader, 0, 8);
                if (!pdfVersion.StartsWith("%PDF-"))
                {
                    return FileValidationResult.Fail("Invalid PDF format.");
                }
            }

            // Check for embedded JavaScript or launch actions (basic check)
            var headerString = System.Text.Encoding.ASCII.GetString(fileHeader);
            if (headerString.Contains("/JavaScript") || 
                headerString.Contains("/JS") || 
                headerString.Contains("/Launch") ||
                headerString.Contains("/EmbeddedFile"))
            {
                return FileValidationResult.Fail("PDF contains potentially dangerous content.");
            }

            return FileValidationResult.Success();
        }

        /// <summary>
        /// Helper method to check if byte array starts with a specific signature
        /// </summary>
        private bool ByteArrayStartsWith(byte[] array, byte[] signature)
        {
            if (array.Length < signature.Length)
                return false;

            for (int i = 0; i < signature.Length; i++)
            {
                if (array[i] != signature[i])
                    return false;
            }

            return true;
        }

        /// <summary>
        /// Gets a safe filename by removing potentially dangerous characters
        /// </summary>
        public string GetSafeFileName(string fileName)
        {
            // Remove path traversal attempts
            fileName = Path.GetFileName(fileName);
            
            // Remove or replace dangerous characters
            var invalidChars = Path.GetInvalidFileNameChars();
            foreach (var c in invalidChars)
            {
                fileName = fileName.Replace(c, '_');
            }

            // Remove additional potentially dangerous characters
            fileName = fileName.Replace("..", "_");
            fileName = fileName.Replace("~", "_");
            
            return fileName;
        }

        /// <summary>
        /// Generates a unique, safe filename for uploaded files
        /// </summary>
        public string GenerateUniqueFileName(string originalFileName, long userId, string docType)
        {
            var extension = Path.GetExtension(originalFileName)?.ToLowerInvariant();
            var safeFileName = GetSafeFileName(Path.GetFileNameWithoutExtension(originalFileName));
            
            // Limit filename length
            if (safeFileName.Length > 50)
            {
                safeFileName = safeFileName.Substring(0, 50);
            }

            var uniqueId = Guid.NewGuid().ToString("N").Substring(0, 8);
            return $"{userId}_{docType}_{uniqueId}_{safeFileName}{extension}";
        }
    }

    /// <summary>
    /// Result of file validation
    /// </summary>
    public class FileValidationResult
    {
        public bool IsValid { get; set; }
        public string? ErrorMessage { get; set; }

        public static FileValidationResult Success() => new FileValidationResult { IsValid = true };
        public static FileValidationResult Fail(string errorMessage) => new FileValidationResult 
        { 
            IsValid = false, 
            ErrorMessage = errorMessage 
        };
    }
}

