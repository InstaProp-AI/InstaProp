enum AccountType { user, developer, admin }

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
  final AccountType type;
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
    required this.type,
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
    return Account(
      accountId: json['accountId'] ?? json['AccountId'] ?? 0,
      firstName: json['firstName'] ?? json['FirstName'] ?? '',
      lastName: json['lastName'] ?? json['LastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['PhoneNumber'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      type: AccountType.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            (json['type'] ?? json['Type'] ?? 'user').toString().toLowerCase(),
        orElse: () => AccountType.user,
      ),
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
      'type': type.toString().split('.').last,
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
}
