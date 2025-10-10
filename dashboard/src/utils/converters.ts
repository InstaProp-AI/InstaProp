/**
 * Type Converters - Convert backend numeric enums to frontend strings
 * These handle both old (numeric) and new (string) formats
 */

// Account Type Converter
export const convertAccountType = (type: number | string): string => {
  if (typeof type === 'string') return type;
  
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

// Convert Account object
export const convertAccount = (account: any): any => {
  const converted = {
    ...account,
    accountId: account.accountId || account.AccountId,
    firstName: account.firstName || account.FirstName,
    lastName: account.lastName || account.LastName,
    email: account.email || account.Email,
    phoneNumber: account.phoneNumber || account.PhoneNumber,
    type: convertAccountType(account.type || account.Type),
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

// Convert Property object
export const convertProperty = (property: any): any => {
  const status = typeof property.status === 'string' ? property.status : convertPropertyStatus(property.status);
  
  return {
    ...property,
    // Normalize field names to camelCase
    propertyId: property.propertyId || property.PropertyId,
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
    project: property.project || property.Project || null
  };
};


