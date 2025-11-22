enum AccountType {
  user,
  developer,
  admin,
} // DEPRECATED: Use roleId and roleName instead

// SECURITY: Role ID constants matching backend (non-guessable 64-bit IDs)
class RoleIds {
  static const int user = 8923748923748923;
  static const int developer = 7823647823647823;
  static const int admin = 9823749823749823;
  static const int sales = 6723546723546723;

  // Helper to get role name from role ID
  static String getRoleName(int roleId) {
    switch (roleId) {
      case admin:
        return 'Admin';
      case developer:
        return 'Developer';
      case user:
        return 'User';
      case sales:
        return 'Sales';
      default:
        return 'User';
    }
  }

  // Helper to get role ID from role name
  static int getRoleId(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'admin':
        return admin;
      case 'developer':
        return developer;
      case 'user':
        return user;
      case 'sales':
        return sales;
      default:
        return user;
    }
  }
}

enum VerificationStatus { notVerified, pending, verified }

class KycDocument {
  final String docType;
  final String imageUrl;
  final DateTime uploadedAt;

  KycDocument({
    required this.docType,
    required this.imageUrl,
    required this.uploadedAt,
  });

  factory KycDocument.fromJson(Map<String, dynamic> json) {
    return KycDocument(
      docType: json['docType'] ?? json['DocType'] ?? '',
      imageUrl: json['imageUrl'] ?? json['ImgUrl'] ?? '',
      uploadedAt: DateTime.parse(
        json['uploadedAt'] ??
            json['UploadedAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docType': docType,
      'imageUrl': imageUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

class Account {
  final int accountId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  // SECURITY: Use roleId (non-guessable 64-bit ID) instead of type enum
  final int roleId; // e.g., 9823749823749823 for Admin
  final String roleName; // 'User', 'Developer', or 'Admin'
  @Deprecated('Use roleId and roleName instead')
  final AccountType type; // DEPRECATED: Kept for backward compatibility
  final VerificationStatus status;
  final bool emailVerified;
  final bool phoneVerified;
  final bool requiresPasswordChange;
  final bool isSuspended;
  final DateTime? suspendedUntil;
  final String? suspensionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<KycDocument> kycDocuments;
  final int? totalEarnedPoints; // For badges/progress
  final int? currentPoints; // For redemption
  final String? topBadgeIcon;
  final String? topBadgeName;

  Account({
    required this.accountId,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.roleId,
    required this.roleName,
    required this.type, // DEPRECATED: Keep for backward compatibility
    required this.status,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.requiresPasswordChange = false,
    this.isSuspended = false,
    this.suspendedUntil,
    this.suspensionReason,
    required this.createdAt,
    this.updatedAt,
    this.kycDocuments = const [],
    this.totalEarnedPoints,
    this.currentPoints,
    this.topBadgeIcon,
    this.topBadgeName,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    // SECURITY: Get roleId and roleName from response (new format)
    final roleId = json['roleId'] ?? json['RoleId'];
    final roleName = json['roleName'] ?? json['RoleName'];

    // Determine roleId and roleName (handle both new and old formats)
    int finalRoleId;
    String finalRoleName;
    AccountType finalType;

    if (roleId != null && roleName != null) {
      // New format: Use roleId and roleName directly
      finalRoleId = roleId is int
          ? roleId
          : int.tryParse(roleId.toString()) ?? RoleIds.user;
      finalRoleName = roleName.toString();
      finalType = AccountType.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            finalRoleName.toLowerCase(),
        orElse: () => AccountType.user,
      );
    } else {
      // Old format: Parse from type field
      final typeStr = (json['type'] ?? json['Type'] ?? 'user')
          .toString()
          .toLowerCase();
      finalType = AccountType.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == typeStr,
        orElse: () => AccountType.user,
      );
      finalRoleId = RoleIds.getRoleId(typeStr);
      finalRoleName = RoleIds.getRoleName(finalRoleId);
    }

    return Account(
      accountId: json['accountId'] ?? json['AccountId'] ?? 0,
      firstName: json['firstName'] ?? json['FirstName'] ?? '',
      lastName: json['lastName'] ?? json['LastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['PhoneNumber'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      roleId: finalRoleId,
      roleName: finalRoleName,
      type: finalType,
      status: _parseVerificationStatus(json['status'] ?? json['Status']),
      emailVerified: json['emailVerified'] ?? json['EmailVerified'] ?? false,
      phoneVerified: json['phoneVerified'] ?? json['PhoneVerified'] ?? false,
      requiresPasswordChange:
          json['requiresPasswordChange'] ??
          json['RequiresPasswordChange'] ??
          false,
      isSuspended: json['isSuspended'] ?? json['IsSuspended'] ?? false,
      suspendedUntil:
          json['suspendedUntil'] != null || json['SuspendedUntil'] != null
          ? DateTime.parse(json['suspendedUntil'] ?? json['SuspendedUntil'])
          : null,
      suspensionReason: json['suspensionReason'] ?? json['SuspensionReason'],
      createdAt: DateTime.parse(
        json['createdAt'] ??
            json['CreatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updatedAt'] != null || json['UpdatedAt'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['UpdatedAt'])
          : null,
      kycDocuments: json['userDocs'] != null || json['UserDocs'] != null
          ? (json['userDocs'] ?? json['UserDocs'] ?? [])
                .map<KycDocument>((doc) => KycDocument.fromJson(doc))
                .toList()
          : [],
      totalEarnedPoints:
          (json['totalEarnedPoints'] ?? json['TotalEarnedPoints']) != null
          ? (json['totalEarnedPoints'] ?? json['TotalEarnedPoints']) as int
          : null,
      currentPoints: (json['currentPoints'] ?? json['CurrentPoints']) != null
          ? (json['currentPoints'] ?? json['CurrentPoints']) as int
          : null,
      topBadgeIcon: json['topBadgeIcon'] ?? json['TopBadgeIcon'],
      topBadgeName: json['topBadgeName'] ?? json['TopBadgeName'],
    );
  }

  static VerificationStatus _parseVerificationStatus(dynamic status) {
    if (status == null) return VerificationStatus.notVerified;

    // Handle numeric values (from enum)
    if (status is int) {
      switch (status) {
        case 0:
          return VerificationStatus.notVerified;
        case 1:
          return VerificationStatus.pending;
        case 2:
          return VerificationStatus.verified;
        default:
          return VerificationStatus.notVerified;
      }
    }

    // Handle string values
    final statusStr = status.toString().toLowerCase();
    if (statusStr.contains('verified') && !statusStr.contains('not')) {
      return VerificationStatus.verified;
    } else if (statusStr.contains('pending')) {
      return VerificationStatus.pending;
    } else {
      return VerificationStatus.notVerified;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'email': email,
      'roleId': roleId, // SECURITY: Use non-guessable roleId
      'roleName': roleName,
      'type': type
          .toString()
          .split('.')
          .last, // DEPRECATED: Keep for backward compatibility
      'status': status.index,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'kycDocuments': kycDocuments.map((doc) => doc.toJson()).toList(),
    };
  }

  // Helper getters for verification status
  bool get isVerified => status == VerificationStatus.verified;
  bool get isPending => status == VerificationStatus.pending;
  bool get isNotVerified => status == VerificationStatus.notVerified;

  String get fullName => '$firstName $lastName';

  // Helper methods to check user role (matching React dashboard logic)
  bool get isAdmin {
    // SECURITY: Check roleName first (from backend), then roleId, then legacy type
    return roleName == 'Admin' ||
        roleId == RoleIds.admin ||
        type == AccountType.admin;
  }

  bool get isDeveloper {
    // SECURITY: Check roleName first (from backend), then roleId, then legacy type
    return roleName == 'Developer' ||
        roleId == RoleIds.developer ||
        type == AccountType.developer;
  }

  bool get isUser {
    // SECURITY: Check roleName first (from backend), then roleId, then legacy type
    return roleName == 'User' ||
        roleId == RoleIds.user ||
        type == AccountType.user;
  }

  bool get isSales {
    // SECURITY: Check roleName first (from backend), then roleId
    return roleName == 'Sales' || roleId == RoleIds.sales;
  }

  // Check if user can access admin/developer features
  bool get canAccessAdminFeatures => isAdmin || isDeveloper;
}
