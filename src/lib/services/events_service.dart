import 'package:src/services/api_service.dart';

class EventsService {
  static Future<Map> addEvent({Map<String, String>? body}) async {
    return await ApiService.post("/add-event", body: body);
  }

  static Future<Map> editEvent({Map<String, String>? body}) async {
    return await ApiService.post("/edit-event", body: body);
  }

  static Future<Map> deleteEvent({Map<String, String>? body}) async {
    return await ApiService.post("/delete-event", body: body);
  }

  static Future<Map> getEvents({Map<String, String>? params}) async {
    return await ApiService.get("/get-events", params: params);
  }

  static Future<Map> toggleRsvp({Map<String, String>? body}) async {
    return await ApiService.post("/toggle-rsvp", body: body);
  }

  static Future<Map> getRsvp({Map<String, String>? params}) async {
    return await ApiService.get("/get-rsvp", params: params);
  }

  static Future<Map> toggleNotification({Map<String, String>? body}) async {
    return await ApiService.post("/toggle-notification", body: body);
  }

  static Future<Map> getNotifications({Map<String, String>? params}) async {
    return await ApiService.get("/get-notifications", params: params);
  }
}
