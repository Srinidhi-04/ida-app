import 'package:src/services/api_service.dart';

class AnnouncementsService {
  static Future<Map> sendAnnouncement({Map<String, String>? body}) async {
    return await ApiService.post("/send-announcement", body: body);
  }

  static Future<Map> addAnnouncement({Map<String, String>? body}) async {
    return await ApiService.post("/add-announcement", body: body);
  }

  static Future<Map> updateAnnouncement({Map<String, String>? body}) async {
    return await ApiService.post("/update-announcement", body: body);
  }

  static Future<Map> getAnnouncements({Map<String, String>? params}) async {
    return await ApiService.get("/get-announcements", params: params);
  }
}
