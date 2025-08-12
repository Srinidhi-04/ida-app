import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:src/services/secure_storage.dart';

class ApiService {
  static const String baseUrl =
      "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  static Future<Map> get(String endpoint, {Map<String, String>? params}) async {
    var response = await http.get(
      Uri.parse(baseUrl + endpoint).replace(queryParameters: params),
      headers: await headers(),
    );

    return jsonDecode(response.body);
  }

  static Future<Map> post(String endpoint, {Map<String, String>? body}) async {
    var response = await http.post(
      Uri.parse(baseUrl + endpoint),
      headers: await headers(),
      body: body,
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, String>> headers() async {
    String? token = await SecureStorage.read("token");

    return (token == null) ? {} : {"Authorization": "Bearer ${token}"};
  }
}
