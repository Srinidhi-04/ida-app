import 'package:src/services/api_service.dart';

class ShopService {
  static Future<Map> addItem(Map<String, String>? body) async {
    return await ApiService.post("/add-item", body);
  }

  static Future<Map> editItem(Map<String, String>? body) async {
    return await ApiService.post("/edit-item", body);
  }

  static Future<Map> deleteItem(Map<String, String>? body) async {
    return await ApiService.post("/delete-item", body);
  }

  static Future<Map> getItems(Map<String, String>? params) async {
    return await ApiService.get("/get-items", params);
  }

  static Future<Map> editCart(Map<String, String>? body) async {
    return await ApiService.post("/edit-cart", body);
  }

  static Future<Map> getCart(Map<String, String>? params) async {
    return await ApiService.get("/get-cart", params);
  }
}
