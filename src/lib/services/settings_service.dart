import 'package:src/services/api_service.dart';

class SettingsService {
  static Future<Map> deleteAccount(Map<String, String>? body) async {
    return await ApiService.post("/delete-account", body);
  }

  static Future<Map> changeSettings(Map<String, String>? body) async {
    return await ApiService.post("/change-settings", body);
  }

  static Future<Map> getSettings(Map<String, String>? params) async {
    return await ApiService.get("/get-settings", params);
  }

  static Future<Map> editProfile(Map<String, String>? body) async {
    return await ApiService.post("/edit-profile", body);
  }

  static Future<Map> editRole(Map<String, String>? body) async {
    return await ApiService.post("/edit-role", body);
  }

  static Future<Map> getRoles(Map<String, String>? params) async {
    return await ApiService.get("/get-roles", params);
  }
}
