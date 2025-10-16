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
  final bool isRecurring;
  final RecurrencePattern? recurrencePattern;
  final int? recurrenceInterval;
  final DateTime? recurrenceEndDate;
  final int? recurrenceCount;
  final int? parentEventId;
  final double? amount;
  final int? propertyId;
  final int? auctionId;
  final int? bidId;
  final DateTime createdAt;
  final String? scheduleImageUrl;
  final String? scheduleGroupId;
  final double? scheduleBuyingPrice;

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
    this.isRecurring = false,
    this.recurrencePattern,
    this.recurrenceInterval,
    this.recurrenceEndDate,
    this.recurrenceCount,
    this.parentEventId,
    this.amount,
    this.propertyId,
    this.auctionId,
    this.bidId,
    required this.createdAt,
    this.scheduleImageUrl,
    this.scheduleGroupId,
    this.scheduleBuyingPrice,
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
      isRecurring: json['isRecurring'] ?? json['IsRecurring'] ?? false,
      recurrencePattern:
          json['recurrencePattern'] != null || json['RecurrencePattern'] != null
          ? RecurrencePatternExtension.fromValue(
              json['recurrencePattern'] ?? json['RecurrencePattern'],
            )
          : null,
      recurrenceInterval:
          json['recurrenceInterval'] ?? json['RecurrenceInterval'],
      recurrenceEndDate:
          json['recurrenceEndDate'] != null || json['RecurrenceEndDate'] != null
          ? DateTime.parse(
              json['recurrenceEndDate'] ?? json['RecurrenceEndDate'],
            )
          : null,
      recurrenceCount: json['recurrenceCount'] ?? json['RecurrenceCount'],
      parentEventId: json['parentEventId'] ?? json['ParentEventId'],
      amount: json['amount'] != null
          ? (json['amount'] as num).toDouble()
          : json['Amount'] != null
          ? (json['Amount'] as num).toDouble()
          : null,
      propertyId: json['propertyId'] ?? json['PropertyId'],
      auctionId: json['auctionId'] ?? json['AuctionId'],
      bidId: json['bidId'] ?? json['BidId'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['CreatedAt']),
      scheduleImageUrl: json['scheduleImageUrl'] ?? json['ScheduleImageUrl'],
      scheduleGroupId: json['scheduleGroupId'] ?? json['ScheduleGroupId'],
      scheduleBuyingPrice:
          (json['scheduleBuyingPrice'] ?? json['ScheduleBuyingPrice']) != null
          ? (json['scheduleBuyingPrice'] ?? json['ScheduleBuyingPrice'] as num)
                .toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'type': type.value,
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
      'scheduleImageUrl': scheduleImageUrl,
      'scheduleGroupId': scheduleGroupId,
      'scheduleBuyingPrice': scheduleBuyingPrice,
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
    String? scheduleImageUrl,
    String? scheduleGroupId,
    double? scheduleBuyingPrice,
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
      scheduleImageUrl: scheduleImageUrl ?? this.scheduleImageUrl,
      scheduleGroupId: scheduleGroupId ?? this.scheduleGroupId,
      scheduleBuyingPrice: scheduleBuyingPrice ?? this.scheduleBuyingPrice,
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

  int get value {
    switch (this) {
      case EventType.installment:
        return 0;
      case EventType.auctionStart:
        return 1;
      case EventType.auctionEnd:
        return 2;
      case EventType.propertyInspection:
        return 3;
      case EventType.propertyValuation:
        return 4;
      case EventType.contractSigning:
        return 5;
      case EventType.moveInDate:
        return 6;
      case EventType.moveOutDate:
        return 7;
      case EventType.maintenance:
        return 8;
      case EventType.meeting:
        return 9;
      case EventType.other:
        return 10;
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
  final bool isRecurring;
  final RecurrencePattern? recurrencePattern;
  final int? recurrenceInterval;
  final DateTime? recurrenceEndDate;
  final int? recurrenceCount;
  final double? amount;
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
    this.isRecurring = false,
    this.recurrencePattern,
    this.recurrenceInterval,
    this.recurrenceEndDate,
    this.recurrenceCount,
    this.amount,
    this.propertyId,
    this.auctionId,
    this.bidId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'type': type.value,
      'location': location,
      'isAllDay': isAllDay,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isReminderSet': isReminderSet,
      'reminderMinutes': reminderMinutes,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern?.value,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'recurrenceCount': recurrenceCount,
      'amount': amount,
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
      'type': type.value,
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
      'type': type.value,
      'location': location,
      'isAllDay': isAllDay,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isReminderSet': isReminderSet,
      'reminderMinutes': reminderMinutes,
    };
  }
}

enum RecurrencePattern { daily, weekly, monthly, yearly }

extension RecurrencePatternExtension on RecurrencePattern {
  String get displayName {
    switch (this) {
      case RecurrencePattern.daily:
        return 'Daily';
      case RecurrencePattern.weekly:
        return 'Weekly';
      case RecurrencePattern.monthly:
        return 'Monthly';
      case RecurrencePattern.yearly:
        return 'Yearly';
    }
  }

  int get value {
    switch (this) {
      case RecurrencePattern.daily:
        return 0;
      case RecurrencePattern.weekly:
        return 1;
      case RecurrencePattern.monthly:
        return 2;
      case RecurrencePattern.yearly:
        return 3;
    }
  }

  static RecurrencePattern fromValue(dynamic value) {
    if (value is int) {
      switch (value) {
        case 0:
          return RecurrencePattern.daily;
        case 1:
          return RecurrencePattern.weekly;
        case 2:
          return RecurrencePattern.monthly;
        case 3:
          return RecurrencePattern.yearly;
        default:
          return RecurrencePattern.daily;
      }
    } else if (value is String) {
      switch (value.toLowerCase()) {
        case 'daily':
          return RecurrencePattern.daily;
        case 'weekly':
          return RecurrencePattern.weekly;
        case 'monthly':
          return RecurrencePattern.monthly;
        case 'yearly':
          return RecurrencePattern.yearly;
        default:
          return RecurrencePattern.daily;
      }
    }
    return RecurrencePattern.daily;
  }
}
