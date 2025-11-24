using InstapropAPI.Models;

namespace InstapropAPI.Extensions
{
    public static class AccountExtensions
    {
        /// <summary>
        /// Check if account is Admin role using UUID RoleId
        /// </summary>
        public static bool IsAdmin(this IAccount account)
        {
            return account.RoleId == Role.ADMIN_ROLE_ID;
        }

        /// <summary>
        /// Check if account is Developer role using UUID RoleId
        /// </summary>
        public static bool IsDeveloper(this IAccount account)
        {
            return account.RoleId == Role.DEVELOPER_ROLE_ID;
        }

        /// <summary>
        /// Check if account is User role using UUID RoleId
        /// </summary>
        public static bool IsUser(this IAccount account)
        {
            return account.RoleId == Role.USER_ROLE_ID;
        }

        /// <summary>
        /// Check if account is Sales role using UUID RoleId
        /// </summary>
        public static bool IsSales(this IAccount account)
        {
            return account.RoleId == Role.SALES_ROLE_ID;
        }

        /// <summary>
        /// Check if account is Developer or Admin
        /// </summary>
        public static bool IsDeveloperOrAdmin(this IAccount account)
        {
            return account.RoleId == Role.DEVELOPER_ROLE_ID || account.RoleId == Role.ADMIN_ROLE_ID;
        }
    }
}








