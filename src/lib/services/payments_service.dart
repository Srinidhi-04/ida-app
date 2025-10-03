import 'package:src/services/api_service.dart';

class PaymentsService {
  static Future<Map> stripePayment({Map<String, String>? body}) async {
    return await ApiService.post("/stripe-payment", body: body);
  }

  static Future<Map> logDonation({Map<String, String>? body}) async {
    return await ApiService.post("/log-donation", body: body);
  }

  static Future<Map> logOrder({String? jsonBody}) async {
    return await ApiService.post("/log-order", jsonBody: jsonBody);
  }

  static Future<Map> getOrder({Map<String, String>? params}) async {
    return await ApiService.get("/get-order", params: params);
  }

  static Future<Map> getOrders({Map<String, String>? params}) async {
    return await ApiService.get("/get-orders", params: params);
  }
  
  static Future<Map> getDonations({Map<String, String>? params}) async {
    return await ApiService.get("/get-donations", params: params);
  }

  static Future<Map> changeStatus({Map<String, String>? body}) async {
    return await ApiService.post("/change-status", body: body);
  }

  static Future<Map> startOrder({String? jsonBody}) async {
    return await ApiService.post("/start-order", jsonBody: jsonBody);
  }

  static Future<Map> cancelOrder({String? jsonBody}) async {
    return await ApiService.post("/cancel-order", jsonBody: jsonBody);
  }
}
