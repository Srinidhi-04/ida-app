import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/notifications_manager.dart';
import 'package:src/services/payments_service.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/widgets/navigation.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late int user_id;

  List orders = [];
  List donations = [];

  List<bool> loaded = [false, false];

  int selected = 0;

  Widget switchOption(int index, String text) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: TextButton(
        onPressed: () {
          setState(() {
            selected = index;
          });
        },
        child: Text(
          text,
          style: Theme.of(context).typography.black.labelMedium!.apply(
            fontWeightDelta: 3,
            color:
                (selected == index)
                    ? Theme.of(context).primaryColorLight
                    : Color(0xFF707372),
          ),
        ),
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            (selected == index) ? Colors.white : Colors.transparent,
          ),
          foregroundColor: WidgetStatePropertyAll(
            (selected == index)
                ? Theme.of(context).primaryColorLight
                : Color(0xFF707372),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
          minimumSize: WidgetStatePropertyAll(
            Size(MediaQuery.of(context).size.width * 0.3, 40),
          ),
        ),
      ),
    );
  }

  Widget transactionCard(
    bool purchase,
    int uid,
    double amount,
    DateTime date,
    String status, [
    String? name,
    String? email,
  ]) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 150,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Card(
          elevation: 5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order Number: ${uid}",
                          style: Theme.of(
                            context,
                          ).typography.white.labelMedium!.apply(
                            color: Theme.of(context).primaryColorLight,
                            fontSizeDelta: 2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Text(
                            "Total Amount: \$${amount}",
                            style: Theme.of(
                              context,
                            ).typography.white.labelMedium!.apply(
                              color: Theme.of(context).primaryColor,
                              fontSizeDelta: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${date.month}/${date.day}/${date.year}",
                      style: Theme.of(
                        context,
                      ).typography.white.labelMedium!.apply(
                        color: Theme.of(context).primaryColor,
                        fontSizeDelta: 2,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${status}",
                      style: Theme.of(
                        context,
                      ).typography.white.labelLarge!.apply(
                        color:
                            (status == "Pending")
                                ? Theme.of(context).primaryColorDark
                                : (status == "Delivered")
                                ? Colors.lightGreen
                                : Colors.red,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (purchase) {
                          Navigator.pushNamed(
                            context,
                            "/order",
                            arguments: {
                              "user_id": user_id,
                              "order_id": uid,
                              "date": date,
                              "status": status,
                              "amount": amount,
                            },
                          ).then((_) => checkLogin());
                        } else {
                          showDialog(
                            context: context,
                            builder:
                                (dialogContext) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  actionsAlignment: MainAxisAlignment.end,
                                  title: Text(
                                    "Receipt",
                                    style:
                                        Theme.of(
                                          context,
                                        ).typography.black.headlineMedium,
                                  ),
                                  content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: "Name: ",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: name),
                                          ],
                                        ),
                                        style: Theme.of(context)
                                            .typography
                                            .black
                                            .labelMedium!
                                            .apply(fontSizeDelta: 2),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          0,
                                          10,
                                          0,
                                          10,
                                        ),
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: "Email: ",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(text: email),
                                            ],
                                          ),
                                          style: Theme.of(context)
                                              .typography
                                              .black
                                              .labelMedium!
                                              .apply(fontSizeDelta: 2),
                                        ),
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: "Amount: ",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  "\$${amount.toStringAsFixed(2)}",
                                            ),
                                          ],
                                        ),
                                        style: Theme.of(context)
                                            .typography
                                            .black
                                            .labelMedium!
                                            .apply(fontSizeDelta: 2),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(dialogContext);
                                      },
                                      child: Text(
                                        "Close",
                                        style: Theme.of(context)
                                            .typography
                                            .black
                                            .labelMedium!
                                            .apply(fontSizeDelta: 2),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                        child: Text(
                          "Details",
                          style: Theme.of(context).typography.white.labelMedium,
                        ),
                      ),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          Theme.of(context).primaryColorDark,
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> getOrders() async {
    Map info = await PaymentsService.getOrders(
      params: {"user_id": user_id.toString()},
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

    List all_orders = info["data"];

    setState(() {
      orders = all_orders;
      loaded[0] = true;
    });
  }

  Future<void> getDonations() async {
    Map info = await PaymentsService.getDonations(
      params: {"user_id": user_id.toString()},
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

    List all_donations = info["data"];

    setState(() {
      donations = all_donations;
      loaded[1] = true;
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
    });
    await Future.wait([getOrders(), getDonations()]);
  }

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  @override
  Widget build(BuildContext context) {
    if (loaded.contains(false))
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
          "My Transactions",
          style: Theme.of(context).typography.black.headlineMedium!.apply(
            color: Theme.of(context).primaryColorDark,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
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
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top -
                  kBottomNavigationBarHeight,
              minWidth: MediaQuery.of(context).size.width,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFC8C6C7),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        switchOption(0, "PURCHASES"),
                        switchOption(1, "DONATIONS"),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      (selected == 0)
                          ? (orders.isEmpty)
                              ? [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Text(
                                      "No purchases",
                                      style:
                                          Theme.of(
                                            context,
                                          ).typography.black.headlineLarge,
                                    ),
                                  ),
                                ),
                              ]
                              : orders
                                  .map(
                                    (e) => transactionCard(
                                      true,
                                      e["order_id"],
                                      e["value"],
                                      DateTime.parse(e["created_at"]).toLocal(),
                                      e["status"],
                                    ),
                                  )
                                  .toList()
                          : (donations.isEmpty)
                          ? [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Text(
                                  "No donations",
                                  style:
                                      Theme.of(
                                        context,
                                      ).typography.black.headlineLarge,
                                ),
                              ),
                            ),
                          ]
                          : donations
                              .map(
                                (e) => transactionCard(
                                  false,
                                  e["record_id"],
                                  e["amount"],
                                  DateTime.parse(e["created_at"]).toLocal(),
                                  "",
                                  e["name"],
                                  e["email"],
                                ),
                              )
                              .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Navigation(selected: 4),
    );
  }
}
