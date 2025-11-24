using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    /// <summary>
    /// User Account - Regular users who can browse properties, place bids, and use OAuth
    /// Has GoogleId and AuthProvider for OAuth support
    /// </summary>
    public class UserAccount : AccountBase
    {

        // OAuth Support - Only for User accounts
        [MaxLength(255)]
        public string? GoogleId { get; set; }
        
        [MaxLength(50)]
        public string? AuthProvider { get; set; } // "google", "email", etc.
    }
}

