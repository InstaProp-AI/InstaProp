using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    /// <summary>
    /// Developer Account - Property developers who can create projects and properties
    /// No OAuth support, no sales team assignment
    /// </summary>
    public class DeveloperAccount : AccountBase
    {
    }
}

