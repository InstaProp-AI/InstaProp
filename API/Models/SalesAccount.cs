using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    /// <summary>
    /// Sales Account - Sales team members assigned to developers
    /// Has SalesTeamId and AssignedDeveloperId
    /// No OAuth support
    /// </summary>
    public class SalesAccount : AccountBase
    {

        // Sales Assignment - Only for sales accounts
        public Guid? AssignedDeveloperId { get; set; }

        [ForeignKey(nameof(AssignedDeveloperId))]
        public DeveloperAccount? AssignedDeveloper { get; set; }

        // Sales Team Assignment - Only for sales accounts
        public Guid? SalesTeamId { get; set; }

        [ForeignKey(nameof(SalesTeamId))]
        public SalesTeam? SalesTeam { get; set; }
    }
}

