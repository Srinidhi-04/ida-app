import 'package:src/services/api_service.dart';

class DonationsService {
  static Future<Map> stripePayment(Map<String, String>? body) async {
    return await ApiService.post("/stripe-payment", body);
  }

  static Future<Map> logDonation(Map<String, String>? body) async {
    return await ApiService.post("/log-donation", body);
  }
}
