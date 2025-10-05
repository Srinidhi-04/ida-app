import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/auth_service.dart';
import 'package:src/services/payments_service.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/services/notifications_manager.dart';
import 'package:src/widgets/navigation.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late int user_id;
  late String role;

  bool initialized = false;
  bool loaded = false;
  bool ordered = false;
  bool reload = false;

  late int order_user;
  late int order_id;
  DateTime? date;
  String? status;
  double? amount;
  List? receipt;

  List<String> statuses = ["Pending", "Delivered", "Cancelled"];

  late DateTime qr_time;

  List<String> admin_roles = ["admin"];
  bool admin_access = false;

  Widget orderItem(String name, double price, int quantity, String image) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Card(
          elevation: 5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: 200,
                    image: NetworkImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: Theme.of(
                                  context,
                                ).typography.white.labelLarge!.apply(
                                  color: Theme.of(context).primaryColorLight,
                                  fontWeightDelta: 3,
                                ),
                              ),
                              Text(
                                "\$${price.toStringAsFixed(2)}",
                                style: Theme.of(
                                  context,
                                ).typography.black.labelMedium!.apply(
                                  color: Theme.of(context).primaryColorDark,
                                  fontWeightDelta: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: Text(
                                  "Quantity: ${quantity}",
                                  style: Theme.of(
                                    context,
                                  ).typography.black.labelSmall!.apply(
                                    color: Theme.of(context).primaryColor,
                                    fontWeightDelta: 3,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: Text(
                                  "Total Price: \$${(quantity * price).toStringAsFixed(2)}",
                                  style: Theme.of(
                                    context,
                                  ).typography.black.labelSmall!.apply(
                                    color: Theme.of(context).primaryColor,
                                    fontWeightDelta: 3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> getOrder() async {
    Map info = await PaymentsService.getOrder(
      params: {
        "user_id": user_id.toString(),
        "order_user": order_user.toString(),
        "order_id": order_id.toString(),
      },
    );

    if (info.containsKey("error") &&
        (info["error"] == "Invalid authorization token" ||
            info["error"] == "A user with that user ID does not exist")) {
      await NotificationsManager.unsubscribeAllNotifications();
      await SecureStorage.delete();
      await Navigator.of(
        context,
      ).pushNamedAndRemoveUntil("/login", (route) => false);
      return;
    } else if (info.containsKey("error")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            info["error"],
            style: Theme.of(context).typography.white.bodyMedium!.apply(
              color: Theme.of(context).primaryColorLight,
            ),
          ),
          backgroundColor: Theme.of(context).primaryColorDark,
          showCloseIcon: true,
          closeIconColor: Theme.of(context).primaryColorLight,
        ),
      );
      return;
    }

    setState(() {
      order_id = info["data"]["order_id"];
      status = info["data"]["status"];
      receipt = info["data"]["items"];
      amount = info["data"]["amount"];
      date = DateTime.parse(info["data"]["date"]).toLocal();
      qr_time = DateTime.now();
    });
  }

  Future<void> getPermissions() async {
    Map info = await AuthService.getPermissions(
      params: {"category": "shop", "user_id": user_id.toString()},
    );

    if (info.containsKey("error") &&
        (info["error"] == "Invalid authorization token" ||
            info["error"] == "A user with that user ID does not exist")) {
      await NotificationsManager.unsubscribeAllNotifications();
      await SecureStorage.delete();
      await Navigator.of(
        context,
      ).pushNamedAndRemoveUntil("/login", (route) => false);
      return;
    } else if (info.containsKey("error")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            info["error"],
            style: Theme.of(context).typography.white.bodyMedium!.apply(
              color: Theme.of(context).primaryColorLight,
            ),
          ),
          backgroundColor: Theme.of(context).primaryColorDark,
          showCloseIcon: true,
          closeIconColor: Theme.of(context).primaryColorLight,
        ),
      );
      return;
    }

    await SecureStorage.writeOne("role", info["data"]["role"]);

    setState(() {
      admin_roles = info["data"]["roles"].cast<String>();
      admin_access = info["data"]["access"];
      role = info["data"]["role"];
      loaded = true;
    });
  }

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
      role = info["role"]!;
    });
    if (!ordered || reload)
      await Future.wait([getOrder(), getPermissions()]);
    else
      await getPermissions();
    setState(() {
      loaded = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!initialized) {
      Map args = ModalRoute.of(context)!.settings.arguments as Map;

      if (args.isNotEmpty) {
        setState(() {
          order_user = args["user_id"];
          order_id = args["order_id"];
          if (args.containsKey("date")) {
            date = args["date"];
          }
          if (args.containsKey("status")) {
            status = args["status"];
          }
          if (args.containsKey("amount")) {
            amount = args["amount"];
          }
          if (args.containsKey("receipt")) {
            receipt = args["receipt"];
            ordered = true;
          }
        });
      }

      setState(() {
        initialized = true;
        qr_time = DateTime.now();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLogin();
    });
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Order Details",
          style: Theme.of(context).typography.black.headlineMedium!.apply(
            color: Theme.of(context).primaryColorDark,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            reload = true;
          });
          await checkLogin();
        },
        color: Theme.of(context).primaryColorLight,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  kBottomNavigationBarHeight,
              minWidth: MediaQuery.of(context).size.width,
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Container(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Order Number: ${order_id}",
                          style: Theme.of(
                            context,
                          ).typography.white.labelLarge!.apply(
                            color: Theme.of(context).primaryColorLight,
                          ),
                        ),
                        Text(
                          "${date!.month}/${date!.day}/${date!.year}",
                          style: Theme.of(context).typography.white.labelLarge!
                              .apply(color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Amount: \$${amount!.toStringAsFixed(2)}",
                            style: Theme.of(
                              context,
                            ).typography.white.labelLarge!.apply(
                              color: Theme.of(context).primaryColorDark,
                            ),
                          ),
                          ((admin_roles.contains(role) || admin_access) &&
                                  status != "Cancelled")
                              ? DropdownButton(
                                value: status,
                                icon: const Icon(Icons.swap_vert),
                                elevation: 16,
                                style: Theme.of(context)
                                    .typography
                                    .black
                                    .labelMedium!
                                    .apply(fontSizeDelta: 2),
                                dropdownColor: Colors.white,
                                onChanged: (String? value) async {
                                  if (value == "Cancelled") {
                                    showDialog(
                                      context: context,
                                      builder: (dialogContext) {
                                        return AlertDialog(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          actionsAlignment:
                                              MainAxisAlignment.end,
                                          title: Text(
                                            "Confirm Cancellation",
                                            style:
                                                Theme.of(context)
                                                    .typography
                                                    .black
                                                    .headlineMedium,
                                          ),
                                          content: Text(
                                            "Are you sure you want to cancel this order? The customer's payment will be refunded and this action cannot be undone.",
                                            style: Theme.of(context)
                                                .typography
                                                .black
                                                .bodyMedium!
                                                .apply(fontSizeDelta: 2),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop(false);
                                              },
                                              child: Text(
                                                "Cancel",
                                                style: Theme.of(context)
                                                    .typography
                                                    .black
                                                    .labelMedium!
                                                    .apply(fontSizeDelta: 2),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop(true);
                                              },
                                              child: Text(
                                                "Confirm",
                                                style: Theme.of(context)
                                                    .typography
                                                    .black
                                                    .labelMedium!
                                                    .apply(
                                                      fontSizeDelta: 2,
                                                      color: Colors.red[900],
                                                    ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ).then((cancel) async {
                                      if (cancel != null && cancel) {
                                        setState(() {
                                          status = value!;
                                        });

                                        Map info =
                                            await PaymentsService.changeStatus(
                                              body: {
                                                "user_id": user_id.toString(),
                                                "order_user":
                                                    order_user.toString(),
                                                "order_id": order_id.toString(),
                                                "status": status!,
                                              },
                                            );

                                        if (info.containsKey("error") &&
                                            (info["error"] ==
                                                    "Invalid authorization token" ||
                                                info["error"] ==
                                                    "A user with that user ID does not exist")) {
                                          await NotificationsManager.unsubscribeAllNotifications();
                                          await SecureStorage.delete();
                                          await Navigator.of(
                                            context,
                                          ).pushNamedAndRemoveUntil(
                                            "/login",
                                            (route) => false,
                                          );
                                          return;
                                        } else if (info.containsKey("error")) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                info["error"],
                                                style: Theme.of(context)
                                                    .typography
                                                    .white
                                                    .bodyMedium!
                                                    .apply(
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).primaryColorLight,
                                                    ),
                                              ),
                                              backgroundColor:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColorDark,
                                              showCloseIcon: true,
                                              closeIconColor:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColorLight,
                                            ),
                                          );
                                          return;
                                        }
                                      }
                                    });

                                    return;
                                  }

                                  if (value != "Cancelled") {
                                    setState(() {
                                      status = value!;
                                    });

                                    Map info =
                                        await PaymentsService.changeStatus(
                                          body: {
                                            "user_id": user_id.toString(),
                                            "order_user": order_user.toString(),
                                            "order_id": order_id.toString(),
                                            "status": status!,
                                          },
                                        );

                                    if (info.containsKey("error") &&
                                        (info["error"] ==
                                                "Invalid authorization token" ||
                                            info["error"] ==
                                                "A user with that user ID does not exist")) {
                                      await NotificationsManager.unsubscribeAllNotifications();
                                      await SecureStorage.delete();
                                      await Navigator.of(
                                        context,
                                      ).pushNamedAndRemoveUntil(
                                        "/login",
                                        (route) => false,
                                      );
                                      return;
                                    } else if (info.containsKey("error")) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            info["error"],
                                            style: Theme.of(context)
                                                .typography
                                                .white
                                                .bodyMedium!
                                                .apply(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).primaryColorLight,
                                                ),
                                          ),
                                          backgroundColor:
                                              Theme.of(
                                                context,
                                              ).primaryColorDark,
                                          showCloseIcon: true,
                                          closeIconColor:
                                              Theme.of(
                                                context,
                                              ).primaryColorLight,
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                },
                                items:
                                    statuses.map<DropdownMenuItem<String>>((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                              )
                              : Text(
                                status!,
                                style: Theme.of(
                                  context,
                                ).typography.black.labelLarge!.apply(
                                  color:
                                      (status == "Pending")
                                          ? Theme.of(context).primaryColorDark
                                          : (status == "Delivered")
                                          ? Colors.lightGreen
                                          : Colors.red,
                                ),
                              ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 15),
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).primaryColorLight,
                            ),
                          ),
                          child: QrImageView(
                            data: jsonEncode({
                              "order_id": order_id,
                              "user_id": order_user,
                              "timestamp": qr_time.millisecondsSinceEpoch,
                            }),
                            size: MediaQuery.of(context).size.width * 0.6,
                            padding: EdgeInsets.all(20),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          receipt!
                              .map(
                                (e) => orderItem(
                                  e["name"],
                                  e["price"],
                                  e["quantity"],
                                  e["image"],
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Navigation(selected: (ordered) ? 3 : 4),
    );
  }
}
