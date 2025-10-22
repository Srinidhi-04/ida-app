import 'package:src/services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FirebaseMessaging fcm = FirebaseMessaging.instance;

class MiscService {
  static Future<Map> checkUpdate({Map<String, String>? params}) async {
    return await ApiService.get("/check-update", params: params);
  }

  static Future<Map> sendQuery({Map<String, String>? body}) async {
    return await ApiService.post("/send-query", body: body);
  }

  static Future<Map> refreshToken({Map<String, String>? body}) async {
    body ??= {};

    final token = await fcm.getToken();
    body["token"] = token!;

    return await ApiService.post("/refresh-token", body: body);
  }

  static Future<Map> deleteToken({Map<String, String>? body}) async {
    body ??= {};

    final token = await fcm.getToken();
    body["token"] = token!;

    return await ApiService.post("/delete-token", body: body);
  }
}
