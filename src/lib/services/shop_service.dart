import 'package:src/services/api_service.dart';

class ShopService {
  static Future<Map> addItem({Map<String, String>? body}) async {
    return await ApiService.post("/add-item", body: body);
  }

  static Future<Map> editItem({Map<String, String>? body}) async {
    return await ApiService.post("/edit-item", body: body);
  }
  
  static Future<Map> changeInventory({Map<String, String>? body}) async {
    return await ApiService.post("/change-inventory", body: body);
  }

  static Future<Map> deleteItem({Map<String, String>? body}) async {
    return await ApiService.post("/delete-item", body: body);
  }

  static Future<Map> getItems({Map<String, String>? params}) async {
    return await ApiService.get("/get-items", params: params);
  }

  static Future<Map> editCart({Map<String, String>? body}) async {
    return await ApiService.post("/edit-cart", body: body);
  }

  static Future<Map> getCart({Map<String, String>? params}) async {
    return await ApiService.get("/get-cart", params: params);
  }

  static Future<Map> getBanner({Map<String, String>? params}) async {
    return await ApiService.get("/get-banner", params: params);
  }
}
