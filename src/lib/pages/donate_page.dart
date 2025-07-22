import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/notifications_manager.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/widgets/navigation.dart';

class DonatePage extends StatefulWidget {
  const DonatePage({super.key});

  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  late int user_id;
  late String token;
  late String name;
  late String email;

  TextEditingController name_controller = TextEditingController();
  TextEditingController email_controller = TextEditingController();

  List<String?> errors = [null, null, null];

  Map? receipt;

  double? amount = null;

  bool loaded = false;
  bool submitted = false;

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  Future<void> checkLogin() async {
    Map<String, String> info = await SecureStorage.read();
    if (info["last_login"] != null) {
      DateTime date = DateTime.parse(info["last_login"]!);
      if (DateTime.now().subtract(Duration(days: 30)).compareTo(date) >= 0) {
        await NotificationsManager.unsubscribeAllNotifications();
        await SecureStorage.delete();
        await Navigator.of(
          context,
        ).pushNamedAndRemoveUntil("/login", (route) => false);
        return;
      }
    }
    if (info["user_id"] == null) {
      await Navigator.popAndPushNamed(context, "/login");
      return;
    }

    setState(() {
      user_id = int.parse(info["user_id"]!);
      token = info["token"]!;
      name = info["name"]!;
      email = info["email"]!;
      name_controller.text = name;
      email_controller.text = email;
      loaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded)
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.inkDrop(
            color: Theme.of(context).primaryColorLight,
            size: 100,
          ),
        ),
      );

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Image(image: AssetImage("assets/logo.png"), height: 40),
            centerTitle: true,
          ),
          body:
              (receipt != null)
                  ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Thank you so much for your donation!",
                          style: Theme.of(context)
                              .typography
                              .black
                              .headlineSmall!
                              .apply(fontSizeDelta: -1),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                          child: Text(
                            "Here is a receipt of your donation:",
                            style:
                                Theme.of(context).typography.black.bodyMedium,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "Name: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: receipt!["name"]),
                            ],
                          ),
                          style: Theme.of(context).typography.black.labelMedium,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "Email: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: receipt!["email"]),
                              ],
                            ),
                            style:
                                Theme.of(context).typography.black.labelMedium,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "Amount: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    "\$${receipt!["amount"].toStringAsFixed(2)}",
                              ),
                            ],
                          ),
                          style: Theme.of(context).typography.black.labelMedium,
                        ),
                      ],
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: () async {
                      await checkLogin();
                    },
                    color: Theme.of(context).primaryColorLight,
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width,
                          minHeight:
                              MediaQuery.of(context).size.height -
                              kToolbarHeight -
                              kBottomNavigationBarHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(30, 20, 30, 20),
                          child: Column(
                            children: [
                              Text(
                                "Support the Illini Dads Association!",
                                style: Theme.of(context)
                                    .typography
                                    .black
                                    .headlineSmall!
                                    .apply(fontSizeDelta: -1),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  10,
                                  0,
                                  20,
                                ),
                                child: Text(
                                  "Your generosity helps us fund events, scholarships, and initiatives that benefit the entire UIUC community. Every contribution, big or small, make a difference.",
                                  style:
                                      Theme.of(
                                        context,
                                      ).typography.black.bodyMedium,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: TextFormField(
                                  controller: name_controller,
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.badge_outlined,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    hintText: "Name",
                                    errorText: errors[0],
                                  ),
                                  cursorColor: Theme.of(context).primaryColor,
                                  onChanged:
                                      (value) => setState(() {
                                        name = value.trim();
                                      }),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: TextFormField(
                                  controller: email_controller,
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.alternate_email_outlined,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    hintText: "Email",
                                    errorText: errors[1],
                                  ),
                                  cursorColor: Theme.of(context).primaryColor,
                                  onChanged:
                                      (value) => setState(() {
                                        email = value.trim();
                                      }),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: TextFormField(
                                  keyboardType: TextInputType.numberWithOptions(
                                    signed: false,
                                    decimal: true,
                                  ),
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.attach_money_outlined,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    hintText: "Amount",
                                    errorText: errors[2],
                                  ),
                                  cursorColor: Theme.of(context).primaryColor,
                                  onChanged:
                                      (value) => setState(() {
                                        try {
                                          if (value.trim() != "") {
                                            amount = double.parse(value.trim());
                                            if (amount! <= 0) {
                                              errors[2] =
                                                  "Amount must be positive";
                                            } else {
                                              errors[2] = null;
                                            }
                                          } else {
                                            amount = null;
                                            errors[2] = null;
                                          }
                                        } catch (e) {
                                          errors[2] = "Amount must be a float";
                                        }
                                      }),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: TextButton(
                                  onPressed: () async {
                                    if (errors[2] != null) {
                                      return;
                                    }

                                    FocusScope.of(context).unfocus();

                                    if (name == "")
                                      errors[0] = "Name is a required field";
                                    else
                                      errors[0] = null;

                                    if (email == "")
                                      errors[1] = "Email is a required field";
                                    else
                                      errors[1] = null;

                                    if (amount == null)
                                      errors[2] = "Amount is a required field";
                                    else
                                      errors[2] = null;

                                    if (errors[0] == null &&
                                        errors[1] == null &&
                                        errors[2] == null) {
                                      setState(() {
                                        submitted = true;
                                      });

                                      var response = await post(
                                        Uri.parse(baseUrl + "/stripe-payment/"),
                                        headers: {
                                          "Authorization": "Bearer ${token}",
                                        },
                                        body: {
                                          "user_id": user_id.toString(),
                                          "amount": amount.toString(),
                                        },
                                      );
                                      Map info = jsonDecode(response.body);
                                      if (info.containsKey("error") &&
                                          info["error"] ==
                                              "Invalid authorization token") {
                                        await NotificationsManager.unsubscribeAllNotifications();
                                        await SecureStorage.delete();
                                        await Navigator.of(
                                          context,
                                        ).pushNamedAndRemoveUntil(
                                          "/login",
                                          (route) => false,
                                        );
                                        return;
                                      }

                                      await Stripe.instance.initPaymentSheet(
                                        paymentSheetParameters:
                                            SetupPaymentSheetParameters(
                                              customFlow: false,
                                              paymentIntentClientSecret:
                                                  info["payment_intent"],
                                              merchantDisplayName:
                                                  "Illini Dads Association",
                                              style: ThemeMode.light,
                                              googlePay:
                                                  const PaymentSheetGooglePay(
                                                    testEnv: true,
                                                    currencyCode: "USD",
                                                    merchantCountryCode: "US",
                                                  ),
                                            ),
                                      );

                                      setState(() {
                                        submitted = false;
                                      });

                                      try {
                                        await Stripe.instance
                                            .presentPaymentSheet();

                                        setState(() {
                                          submitted = true;
                                        });

                                        var response = await post(
                                          Uri.parse(baseUrl + "/log-donation/"),
                                          headers: {
                                            "Authorization": "Bearer ${token}",
                                          },
                                          body: {
                                            "user_id": user_id.toString(),
                                            "name": name,
                                            "email": email,
                                            "amount": amount.toString(),
                                          },
                                        );
                                        Map info = jsonDecode(response.body);
                                        if (info.containsKey("error") &&
                                            info["error"] ==
                                                "Invalid authorization token") {
                                          await NotificationsManager.unsubscribeAllNotifications();
                                          await SecureStorage.delete();
                                          await Navigator.of(
                                            context,
                                          ).pushNamedAndRemoveUntil(
                                            "/login",
                                            (route) => false,
                                          );
                                          return;
                                        }

                                        setState(() {
                                          receipt = {
                                            "name": name,
                                            "email": email,
                                            "amount": amount,
                                          };
                                        });
                                      } catch (e) {}
                                    }

                                    setState(() {
                                      errors = errors;
                                      submitted = false;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      "Donate",
                                      style: Theme.of(context)
                                          .typography
                                          .white
                                          .labelLarge!
                                          .apply(fontWeightDelta: 3),
                                    ),
                                  ),
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                      Theme.of(context).primaryColorLight,
                                    ),
                                    foregroundColor: WidgetStatePropertyAll(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          bottomNavigationBar: Navigation(selected: 0),
        ),
        (submitted)
            ? Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Color(0x99FFFFFF),
              child: LoadingAnimationWidget.threeArchedCircle(
                color: Theme.of(context).primaryColorLight,
                size: 100,
              ),
            )
            : Container(),
      ],
    );
  }
}
