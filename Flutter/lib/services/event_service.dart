import '../models/event.dart';
import 'api_client.dart';

class EventService {
  // Get all events for the current user
  static Future<ApiResponse<List<Event>>> getEvents() async {
    return await ApiClient.getList('/api/event', Event.fromJson);
  }

  // Get a specific event by ID
  static Future<ApiResponse<Event>> getEvent(int eventId) async {
    return await ApiClient.get('/api/event/$eventId', Event.fromJson);
  }

  // Get events for a specific month
  static Future<ApiResponse<List<Event>>> getEventsByMonth(
    int year,
    int month,
  ) async {
    return await ApiClient.getList(
      '/api/event/month/$year/$month',
      Event.fromJson,
    );
  }

  // Get today's events
  static Future<ApiResponse<List<Event>>> getTodaysEvents() async {
    return await ApiClient.getList('/api/event/today', Event.fromJson);
  }

  // Get upcoming events
  static Future<ApiResponse<List<Event>>> getUpcomingEvents() async {
    return await ApiClient.getList('/api/event/upcoming', Event.fromJson);
  }

  // Create a new event
  static Future<ApiResponse<Event>> createEvent(EventCreateDto eventDto) async {
    return await ApiClient.post(
      '/api/event',
      eventDto.toJson(),
      Event.fromJson,
    );
  }

  // Update an existing event
  static Future<ApiResponse<void>> updateEvent(
    int eventId,
    EventUpdateDto eventDto,
  ) async {
    return await ApiClient.put(
      '/api/event/$eventId',
      eventDto.toJson(),
      (data) => null,
    );
  }

  // Mark an event as completed
  static Future<ApiResponse<void>> completeEvent(int eventId) async {
    return await ApiClient.put(
      '/api/event/$eventId/complete',
      {},
      (data) => null,
    );
  }

  // Delete an event
  static Future<ApiResponse<void>> deleteEvent(int eventId) async {
    return await ApiClient.delete('/api/event/$eventId');
  }

  // Helper method to get events for a specific date
  static Future<ApiResponse<List<Event>>> getEventsForDate(
    DateTime date,
  ) async {
    return await ApiClient.getList(
      '/api/event/month/${date.year}/${date.month}',
      Event.fromJson,
    );
  }

  // Helper method to create quick events
  static Future<ApiResponse<Event>> createQuickEvent({
    required String title,
    required DateTime date,
    EventType type = EventType.other,
    String? description,
    String? location,
  }) async {
    final eventDto = EventCreateDto(
      title: title,
      eventDate: date,
      type: type,
      description: description,
      location: location,
      isAllDay: true,
    );
    return await createEvent(eventDto);
  }

  // Create a public event (Admin only)
  static Future<ApiResponse<Event>> createPublicEvent(
    PublicEventCreateDto publicEventDto,
  ) async {
    return await ApiClient.post(
      '/api/event/public',
      publicEventDto.toJson(),
      Event.fromJson,
    );
  }

  // Get all public events (Admin only)
  static Future<ApiResponse<List<Event>>> getPublicEvents() async {
    return await ApiClient.getList('/api/event/public', Event.fromJson);
  }

  // PUBLIC ENDPOINTS (No authentication required)

  // Get public calendar events (No auth required)
  static Future<ApiResponse<List<Event>>> getPublicCalendarEvents() async {
    return await ApiClient.getList(
      '/api/event/public/calendar',
      Event.fromJson,
    );
  }

  // Get public events for a specific month (No auth required)
  static Future<ApiResponse<List<Event>>> getPublicEventsByMonth(
    int year,
    int month,
  ) async {
    return await ApiClient.getList(
      '/api/event/public/calendar/month/$year/$month',
      Event.fromJson,
    );
  }

  // Get today's public events (No auth required)
  static Future<ApiResponse<List<Event>>> getPublicTodaysEvents() async {
    return await ApiClient.getList(
      '/api/event/public/calendar/today',
      Event.fromJson,
    );
  }

  // Get upcoming public events (No auth required)
  static Future<ApiResponse<List<Event>>> getPublicUpcomingEvents() async {
    return await ApiClient.getList(
      '/api/event/public/calendar/upcoming',
      Event.fromJson,
    );
  }
}
