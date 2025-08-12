import 'package:src/services/api_service.dart';

class MiscService {
  static Future<Map> checkUpdate({Map<String, String>? params}) async {
    return await ApiService.get("/check-update", params: params);
  }

  static Future<Map> sendQuery({Map<String, String>? body}) async {
    return await ApiService.post("/send-query", body: body);
  }
}
