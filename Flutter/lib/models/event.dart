import 'package:flutter/material.dart';

class Event {
  final int eventId;
  final String title;
  final String? description;
  final DateTime eventDate;
  final EventType type;
  final String? location;
  final bool isAllDay;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final bool isReminderSet;
  final int? reminderMinutes;
  final bool isPublic;
  final int? propertyId;
  final int? auctionId;
  final int? bidId;
  final DateTime createdAt;

  Event({
    required this.eventId,
    required this.title,
    this.description,
    required this.eventDate,
    required this.type,
    this.location,
    this.isAllDay = false,
    this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.isReminderSet = false,
    this.reminderMinutes,
    this.isPublic = false,
    this.propertyId,
    this.auctionId,
    this.bidId,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['eventId'] ?? json['EventId'] ?? 0,
      title: json['title'] ?? json['Title'] ?? '',
      description: json['description'] ?? json['Description'],
      eventDate: DateTime.parse(json['eventDate'] ?? json['EventDate']),
      type: EventTypeExtension.fromValue(json['type'] ?? json['Type'] ?? 0),
      location: json['location'] ?? json['Location'],
      isAllDay: json['isAllDay'] ?? json['IsAllDay'] ?? false,
      startTime: json['startTime'] != null || json['StartTime'] != null
          ? DateTime.parse(json['startTime'] ?? json['StartTime'])
          : null,
      endTime: json['endTime'] != null || json['EndTime'] != null
          ? DateTime.parse(json['endTime'] ?? json['EndTime'])
          : null,
      isCompleted: json['isCompleted'] ?? json['IsCompleted'] ?? false,
      isReminderSet: json['isReminderSet'] ?? json['IsReminderSet'] ?? false,
      reminderMinutes: json['reminderMinutes'] ?? json['ReminderMinutes'],
      isPublic: json['isPublic'] ?? json['IsPublic'] ?? false,
      propertyId: json['propertyId'] ?? json['PropertyId'],
      auctionId: json['auctionId'] ?? json['AuctionId'],
      bidId: json['bidId'] ?? json['BidId'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['CreatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'type': type.toString().split('.').last,
      'location': location,
      'isAllDay': isAllDay,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isCompleted': isCompleted,
      'isReminderSet': isReminderSet,
      'reminderMinutes': reminderMinutes,
      'propertyId': propertyId,
      'auctionId': auctionId,
      'bidId': bidId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Event copyWith({
    int? eventId,
    String? title,
    String? description,
    DateTime? eventDate,
    EventType? type,
    String? location,
    bool? isAllDay,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    bool? isReminderSet,
    int? reminderMinutes,
    int? propertyId,
    int? auctionId,
    int? bidId,
    DateTime? createdAt,
  }) {
    return Event(
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      type: type ?? this.type,
      location: location ?? this.location,
      isAllDay: isAllDay ?? this.isAllDay,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isReminderSet: isReminderSet ?? this.isReminderSet,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      propertyId: propertyId ?? this.propertyId,
      auctionId: auctionId ?? this.auctionId,
      bidId: bidId ?? this.bidId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum EventType {
  installment, // Payment due dates
  auctionStart, // Auction starting dates
  auctionEnd, // Auction ending dates
  propertyInspection, // Property viewing/inspection
  propertyValuation, // Property appraisal dates
  contractSigning, // Legal document signing
  moveInDate, // Moving into property
  moveOutDate, // Moving out of property
  maintenance, // Property maintenance
  meeting, // General meetings
  other, // Custom events
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.installment:
        return 'Installment Payment';
      case EventType.auctionStart:
        return 'Auction Start';
      case EventType.auctionEnd:
        return 'Auction End';
      case EventType.propertyInspection:
        return 'Property Inspection';
      case EventType.propertyValuation:
        return 'Property Valuation';
      case EventType.contractSigning:
        return 'Contract Signing';
      case EventType.moveInDate:
        return 'Move In Date';
      case EventType.moveOutDate:
        return 'Move Out Date';
      case EventType.maintenance:
        return 'Maintenance';
      case EventType.meeting:
        return 'Meeting';
      case EventType.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case EventType.installment:
        return Colors.blue;
      case EventType.auctionStart:
      case EventType.auctionEnd:
        return Colors.orange;
      case EventType.propertyInspection:
      case EventType.propertyValuation:
        return Colors.green;
      case EventType.contractSigning:
        return Colors.purple;
      case EventType.moveInDate:
      case EventType.moveOutDate:
        return Colors.teal;
      case EventType.maintenance:
        return Colors.brown;
      case EventType.meeting:
        return Colors.indigo;
      case EventType.other:
        return Colors.grey;
    }
  }

  static EventType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'installment':
        return EventType.installment;
      case 'auctionstart':
        return EventType.auctionStart;
      case 'auctionend':
        return EventType.auctionEnd;
      case 'propertyinspection':
        return EventType.propertyInspection;
      case 'propertyvaluation':
        return EventType.propertyValuation;
      case 'contractsigning':
        return EventType.contractSigning;
      case 'moveindate':
        return EventType.moveInDate;
      case 'moveoutdate':
        return EventType.moveOutDate;
      case 'maintenance':
        return EventType.maintenance;
      case 'meeting':
        return EventType.meeting;
      case 'other':
      default:
        return EventType.other;
    }
  }

  static EventType fromValue(dynamic value) {
    // Handle both int and string values
    if (value is int) {
      switch (value) {
        case 0:
          return EventType.installment;
        case 1:
          return EventType.auctionStart;
        case 2:
          return EventType.auctionEnd;
        case 3:
          return EventType.propertyInspection;
        case 4:
          return EventType.propertyValuation;
        case 5:
          return EventType.contractSigning;
        case 6:
          return EventType.moveInDate;
        case 7:
          return EventType.moveOutDate;
        case 8:
          return EventType.maintenance;
        case 9:
          return EventType.meeting;
        case 10:
        default:
          return EventType.other;
      }
    } else if (value is String) {
      return fromString(value);
    } else {
      return EventType.other;
    }
  }
}

class EventCreateDto {
  final String title;
  final String? description;
  final DateTime eventDate;
  final EventType type;
  final String? location;
  final bool isAllDay;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isReminderSet;
  final int? reminderMinutes;
  final int? propertyId;
  final int? auctionId;
  final int? bidId;

  EventCreateDto({
    required this.title,
    this.description,
    required this.eventDate,
    required this.type,
    this.location,
    this.isAllDay = false,
    this.startTime,
    this.endTime,
    this.isReminderSet = false,
    this.reminderMinutes,
    this.propertyId,
    this.auctionId,
    this.bidId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'type': type.toString().split('.').last,
      'location': location,
      'isAllDay': isAllDay,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isReminderSet': isReminderSet,
      'reminderMinutes': reminderMinutes,
      'propertyId': propertyId,
      'auctionId': auctionId,
      'bidId': bidId,
    };
  }
}

class EventUpdateDto {
  final String title;
  final String? description;
  final DateTime eventDate;
  final EventType type;
  final String? location;
  final bool isAllDay;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final bool isReminderSet;
  final int? reminderMinutes;

  EventUpdateDto({
    required this.title,
    this.description,
    required this.eventDate,
    required this.type,
    this.location,
    this.isAllDay = false,
    this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.isReminderSet = false,
    this.reminderMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'type': type.toString().split('.').last,
      'location': location,
      'isAllDay': isAllDay,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isCompleted': isCompleted,
      'isReminderSet': isReminderSet,
      'reminderMinutes': reminderMinutes,
    };
  }
}

class PublicEventCreateDto {
  final String title;
  final String? description;
  final DateTime eventDate;
  final EventType type;
  final String? location;
  final bool isAllDay;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isReminderSet;
  final int? reminderMinutes;

  PublicEventCreateDto({
    required this.title,
    this.description,
    required this.eventDate,
    required this.type,
    this.location,
    this.isAllDay = false,
    this.startTime,
    this.endTime,
    this.isReminderSet = false,
    this.reminderMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'type': type.toString().split('.').last,
      'location': location,
      'isAllDay': isAllDay,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isReminderSet': isReminderSet,
      'reminderMinutes': reminderMinutes,
    };
  }
}
