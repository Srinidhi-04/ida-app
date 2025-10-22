import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:src/services/secure_storage.dart';

class ApiService {
  static const String baseUrl =
      "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  static Future<Map> get(String endpoint, {Map<String, String>? params}) async {
    String? user_id = await SecureStorage.read("user_id");
    if (user_id != null) {
      params ??= {};
      params["user_id"] = user_id;
    }

    var response = await http.get(
      Uri.parse(baseUrl + endpoint).replace(queryParameters: params),
      headers: await headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map> post(String endpoint, {Map<String, String>? body, String? jsonBody}) async {
    String? user_id = await SecureStorage.read("user_id");
    if (user_id != null) {
      if (body == null && jsonBody == null) {
        body = {"user_id": user_id};
      } else if (body != null) {
        body["user_id"] = user_id;
      } else {
        var jBody = jsonDecode(jsonBody!);
        jBody["user_id"] = user_id;
        jsonBody = jsonEncode(jBody);
      }
    }

    var response = await http.post(
      Uri.parse(baseUrl + endpoint),
      headers: await headers(),
      body: (body != null) ? body : jsonBody,
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, String>> headers() async {
    String? token = await SecureStorage.read("token");

    return (token == null) ? {} : {"Authorization": "Bearer ${token}"};
  }
}
