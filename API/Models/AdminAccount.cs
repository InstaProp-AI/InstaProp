using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    /// <summary>
    /// Admin Account - System administrators with full access
    /// No OAuth support, no sales team assignment
    /// </summary>
    public class AdminAccount : AccountBase
    {
    }
}

