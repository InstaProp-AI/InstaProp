/**
 * Type Converters - Convert backend numeric enums to frontend strings
 * These handle both old (numeric) and new (string) formats
 */

// SECURITY: Account Role Converter - Uses non-guessable 64-bit RoleIds
// Role IDs: User=8923748923748923, Developer=7823647823647823, Admin=9823749823749823
export const convertAccountRole = (roleId: number | null | undefined, roleName?: string | null): { roleId: number; roleName: string } => {
  // If roleName is provided, use it
  if (roleName) {
    const roleIdValue = roleId || getRoleIdFromName(roleName);
    return { roleId: roleIdValue, roleName };
  }
  
  // If roleId is provided, get role name from it
  if (roleId) {
    const name = getRoleNameFromId(roleId);
    return { roleId, roleName: name };
  }
  
  // Default to User
  return { roleId: 8923748923748923, roleName: 'User' };
};

// Helper to get role ID from role name
const getRoleIdFromName = (roleName: string): number => {
  switch (roleName.toLowerCase()) {
    case 'admin': return 9823749823749823;
    case 'developer': return 7823647823647823;
    case 'user': return 8923748923748923;
    default: return 8923748923748923;
  }
};

// Helper to get role name from role ID
const getRoleNameFromId = (roleId: number): string => {
  switch (roleId) {
    case 9823749823749823: return 'Admin';
    case 7823647823647823: return 'Developer';
    case 8923748923748923: return 'User';
    default: return 'User';
  }
};

// Legacy: Account Type Converter (for backward compatibility)
export const convertAccountType = (type: number | string | null | undefined): string => {
  if (typeof type === 'string') return type;
  if (type == null) return 'User';
  
  switch (type) {
    case 0: return 'User';
    case 1: return 'Developer';
    case 2: return 'Admin';
    default: return 'User';
  }
};

// Account Status Converter
export const convertAccountStatus = (status: number | string): string => {
  if (typeof status === 'string') return status;
  
  switch (status) {
    case 0: return 'NotVerified';
    case 1: return 'Pending';
    case 2: return 'Verified';
    default: return 'NotVerified';
  }
};

// Property Status Converter
export const convertPropertyStatus = (status: number | string): string => {
  if (typeof status === 'string') return status;
  
  switch (status) {
    case 0: return 'NotApproved';
    case 1: return 'Pending';
    case 2: return 'Approved';
    default: return 'NotApproved';
  }
};

// Convert Account object - SECURITY: Now uses roleId and roleName instead of type
export const convertAccount = (account: any): any => {
  // Get roleId and roleName from response (backend now returns these)
  const roleId = account.roleId ?? account.RoleId;
  const roleName = account.roleName ?? account.RoleName;
  
  // Convert role if not present (backward compatibility)
  const role = roleId && roleName 
    ? { roleId, roleName } 
    : convertAccountRole(roleId, roleName || account.type || account.Type);
  
  // For backward compatibility, keep type field if not present
  const legacyType = account.type || account.Type 
    ? convertAccountType(account.type || account.Type)
    : role.roleName;
  
  const converted = {
    ...account,
    accountId: account.accountId || account.AccountId,
    firstName: account.firstName || account.FirstName,
    lastName: account.lastName || account.LastName,
    email: account.email || account.Email,
    phoneNumber: account.phoneNumber || account.PhoneNumber,
    // SECURITY: Use non-guessable roleId and roleName
    roleId: role.roleId,
    roleName: role.roleName,
    // Legacy type field for backward compatibility
    type: legacyType,
    status: convertAccountStatus(account.status || account.Status),
    emailVerified: account.emailVerified ?? account.EmailVerified ?? false,
    phoneVerified: account.phoneVerified ?? account.PhoneVerified ?? false,
    // Explicitly preserve suspension fields (handle both camelCase and PascalCase)
    isSuspended: account.isSuspended ?? account.IsSuspended ?? false,
    suspendedUntil: account.suspendedUntil || account.SuspendedUntil || null,
    suspensionReason: account.suspensionReason || account.SuspensionReason || null,
    createdAt: account.createdAt || account.CreatedAt,
    updatedAt: account.updatedAt || account.UpdatedAt || null
  };
  
  return converted;
};

// Convert Property object (ChildProperty with parent-child relationship support)
export const convertProperty = (property: any): any => {
  const status = typeof property.status === 'string' ? property.status : convertPropertyStatus(property.status);
  
  // Convert parent property if present
  const parentProperty = property.parentProperty || property.ParentProperty 
    ? {
        parentPropertyId: property.parentProperty?.parentPropertyId || property.parentProperty?.ParentPropertyId || property.ParentProperty?.ParentPropertyId,
        projectName: property.parentProperty?.projectName || property.parentProperty?.ProjectName || property.ParentProperty?.ProjectName,
        type: property.parentProperty?.type || property.parentProperty?.Type || property.ParentProperty?.Type,
        bedrooms: property.parentProperty?.bedrooms || property.parentProperty?.Bedrooms || property.ParentProperty?.Bedrooms,
        bathrooms: property.parentProperty?.bathrooms || property.parentProperty?.Bathrooms || property.ParentProperty?.Bathrooms,
        areaSqm: property.parentProperty?.areaSqm || property.parentProperty?.AreaSqm || property.ParentProperty?.AreaSqm,
        finishingType: property.parentProperty?.finishingType || property.parentProperty?.FinishingType || property.ParentProperty?.FinishingType
      }
    : null;
  
  return {
    ...property,
    // Normalize field names to camelCase
    propertyId: property.propertyId || property.PropertyId,
    parentPropertyId: property.parentPropertyId || property.ParentPropertyId || null, // Include ParentPropertyId
    ownerId: property.ownerId || property.OwnerId,
    projectId: property.projectId || property.ProjectId,
    name: property.name || property.Name,
    description: property.description || property.Description,
    location: property.location || property.Location,
    type: property.type || property.Type,
    bedrooms: property.bedrooms || property.Bedrooms,
    bathrooms: property.bathrooms || property.Bathrooms,
    squareFeet: property.squareFeet || property.SquareFeet,
    yearBuilt: property.yearBuilt || property.YearBuilt,
    category: property.category || property.Category,
    imageUrl: property.imageUrl || property.ImageUrl,
    createdAt: property.createdAt || property.CreatedAt,
    updatedAt: property.updatedAt || property.UpdatedAt,
    status: status,
    isApproved: status === 'Approved', // Add computed isApproved field
    owner: property.owner || property.Owner ? convertAccount(property.owner || property.Owner) : null,
    project: property.project || property.Project || null,
    parentProperty: parentProperty // Include parent property information
  };
};


