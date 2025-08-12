import 'package:src/services/api_service.dart';

class AuthService {
  static Future<Map> signup(Map<String, String>? body) async {
    return await ApiService.post("/signup", body);
  }

  static Future<Map> verifyCode(Map<String, String>? body) async {
    return await ApiService.post("/verify-code", body);
  }

  static Future<Map> sendCode(Map<String, String>? body) async {
    return await ApiService.post("/send-code", body);
  }

  static Future<Map> changePassword(Map<String, String>? body) async {
    return await ApiService.post("/change-password", body);
  }

  static Future<Map> login(Map<String, String>? body) async {
    return await ApiService.post("/login", body);
  }

  static Future<Map> getPermissions(Map<String, String>? params) async {
    return await ApiService.get("/get-permissions", params);
  }
}
