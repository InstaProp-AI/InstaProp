using InstapropAPI.Models;

namespace InstapropAPI.Extensions
{
    public static class AccountExtensions
    {
        /// <summary>
        /// Check if account is Admin role using non-guessable RoleId
        /// </summary>
        public static bool IsAdmin(this Account account)
        {
            return account.RoleId == Role.ADMIN_ROLE_ID;
        }

        /// <summary>
        /// Check if account is Developer role using non-guessable RoleId
        /// </summary>
        public static bool IsDeveloper(this Account account)
        {
            return account.RoleId == Role.DEVELOPER_ROLE_ID;
        }

        /// <summary>
        /// Check if account is User role using non-guessable RoleId
        /// </summary>
        public static bool IsUser(this Account account)
        {
            return account.RoleId == Role.USER_ROLE_ID;
        }

        /// <summary>
        /// Check if account is Developer or Admin
        /// </summary>
        public static bool IsDeveloperOrAdmin(this Account account)
        {
            return account.RoleId == Role.DEVELOPER_ROLE_ID || account.RoleId == Role.ADMIN_ROLE_ID;
        }
    }
}




