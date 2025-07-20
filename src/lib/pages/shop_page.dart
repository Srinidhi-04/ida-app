import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/notifications_manager.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/widgets/navigation.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late int user_id;
  late String token;
  late String role;

  Map<int, int> quantity = {};
  List items = [];

  bool cart = false;
  bool initialized = false;

  List<bool> loaded = [false, false];

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  Widget shopItem(
    int index,
    int item_id,
    String name,
    double price,
    String image,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Slidable(
          key: ValueKey(item_id),
          enabled: (role == "admin" && !cart),
          endActionPane: ActionPane(
            motion: BehindMotion(),
            dismissible: DismissiblePane(
              onDismissed: () async {
                setState(() {
                  items.removeAt(index);
                });
                var response = await post(
                  Uri.parse(baseUrl + "/delete-item/"),
                  headers: {"Authorization": "Bearer ${token}"},
                  body: {
                    "user_id": user_id.toString,
                    "item_id": item_id.toString(),
                  },
                );
                Map info = jsonDecode(response.body);
                if (info.containsKey("error") &&
                    info["error"] == "Invalid authorization token") {
                  await NotificationsManager.unsubscribeAllNotifications();
                  await SecureStorage.delete();
                  await Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil("/login", (route) => false);
                  return;
                }

                getItems();
                getCart();
              },
            ),
            children: [
              CustomSlidableAction(
                onPressed: (slideContext) async {
                  Navigator.of(context).pushNamed(
                    "/item",
                    arguments: {
                      "item_id": item_id,
                      "name": name,
                      "price": price,
                      "image": image,
                      "callback": () {
                        getItems();
                        getCart();
                      },
                    },
                  );
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: Icon(Icons.edit_outlined, size: 50),
              ),
              CustomSlidableAction(
                onPressed: (slideContext) async {
                  setState(() {
                    items.removeAt(index);
                  });
                  var response = await post(
                    Uri.parse(baseUrl + "/delete-item/"),
                    headers: {"Authorization": "Bearer ${token}"},
                    body: {
                      "user_id": user_id.toString(),
                      "item_id": item_id.toString(),
                    },
                  );
                  Map info = jsonDecode(response.body);
                  if (info.containsKey("error") &&
                      info["error"] == "Invalid authorization token") {
                    await NotificationsManager.unsubscribeAllNotifications();
                    await SecureStorage.delete();
                    await Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil("/login", (route) => false);
                    return;
                  }

                  getItems();
                  getCart();
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: Icon(Icons.delete_outline, size: 50),
              ),
            ],
          ),
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
                                  ).typography.white.labelMedium!.apply(
                                    color: Theme.of(context).primaryColorLight,
                                    fontSizeDelta: 2,
                                    fontWeightDelta: 3,
                                  ),
                                ),
                                Text(
                                  "\$${price.toStringAsFixed(2)}",
                                  style: Theme.of(
                                    context,
                                  ).typography.black.labelSmall!.apply(
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
                                (!quantity.containsKey(item_id) ||
                                        quantity[item_id] == 0)
                                    ? TextButton(
                                      onPressed: () async {
                                        setState(() {
                                          quantity[item_id] = 1;
                                        });
                                        var response = await post(
                                          Uri.parse(baseUrl + "/edit-cart/"),
                                          headers: {
                                            "Authorization": "Bearer ${token}",
                                          },
                                          body: {
                                            "user_id": user_id.toString(),
                                            "item_id": item_id.toString(),
                                            "quantity": "1",
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
                                      },
                                      child: Text(
                                        "Add to cart",
                                        style: Theme.of(
                                          context,
                                        ).typography.black.labelSmall!.apply(
                                          color:
                                              Theme.of(
                                                context,
                                              ).primaryColorDark,
                                          fontWeightDelta: 3,
                                        ),
                                      ),
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll(
                                          Theme.of(context).primaryColorLight,
                                        ),
                                        shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    : Container(
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color:
                                              Theme.of(
                                                context,
                                              ).primaryColorLight,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            constraints: BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: () async {
                                              setState(() {
                                                quantity[item_id] =
                                                    quantity[item_id]! - 1;
                                                if (quantity[item_id] == 0)
                                                  quantity.remove(item_id);
                                              });
                                              var response = await post(
                                                Uri.parse(
                                                  baseUrl + "/edit-cart/",
                                                ),
                                                headers: {
                                                  "Authorization":
                                                      "Bearer ${token}",
                                                },
                                                body: {
                                                  "user_id": user_id.toString(),
                                                  "item_id": item_id.toString(),
                                                  "quantity":
                                                      ((quantity.containsKey(
                                                            item_id,
                                                          ))
                                                          ? quantity[item_id]
                                                              .toString()
                                                          : "0"),
                                                },
                                              );
                                              Map info = jsonDecode(
                                                response.body,
                                              );
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
                                            },
                                            icon: Icon(Icons.remove, size: 15),
                                          ),
                                          Text(
                                            quantity[item_id]!.toString(),
                                            style:
                                                Theme.of(
                                                  context,
                                                ).typography.black.labelSmall,
                                          ),
                                          IconButton(
                                            constraints: BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: () async {
                                              setState(() {
                                                quantity[item_id] =
                                                    quantity[item_id]! + 1;
                                              });
                                              var response = await post(
                                                Uri.parse(
                                                  baseUrl + "/edit-cart/",
                                                ),
                                                headers: {
                                                  "Authorization":
                                                      "Bearer ${token}",
                                                },
                                                body: {
                                                  "user_id": user_id.toString(),
                                                  "item_id": item_id.toString(),
                                                  "quantity":
                                                      quantity[item_id]
                                                          .toString(),
                                                },
                                              );
                                              Map info = jsonDecode(
                                                response.body,
                                              );
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
                                            },
                                            icon: Icon(Icons.add, size: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                (quantity.containsKey(item_id) &&
                                        quantity[item_id]! > 0)
                                    ? Padding(
                                      padding: const EdgeInsets.only(top: 5.0),
                                      child: Text(
                                        "Total Price: \$${(quantity[item_id]! * price).toStringAsFixed(2)}",
                                        style: Theme.of(
                                          context,
                                        ).typography.black.labelSmall!.apply(
                                          color:
                                              Theme.of(
                                                context,
                                              ).primaryColorDark,
                                          fontWeightDelta: 3,
                                        ),
                                      ),
                                    )
                                    : Container(),
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
      ),
    );
  }

  double calculateTotal() {
    double total = 0;

    for (var item in items) {
      if (quantity.containsKey(item["item_id"])) {
        total += quantity[item["item_id"]]! * item["price"];
      }
    }

    return total;
  }

  Future<void> getItems() async {
    var response = await get(
      Uri.parse(baseUrl + "/get-items?user_id=${user_id}"),
      headers: {"Authorization": "Bearer ${token}"},
    );
    Map info = jsonDecode(response.body);
    if (info.containsKey("error") &&
        info["error"] == "Invalid authorization token") {
      await NotificationsManager.unsubscribeAllNotifications();
      await SecureStorage.delete();
      await Navigator.of(
        context,
      ).pushNamedAndRemoveUntil("/login", (route) => false);
      return;
    }

    List all_items = info["data"];

    setState(() {
      items = all_items;
      loaded[0] = true;
    });
  }

  Future<void> getCart() async {
    var response = await get(
      Uri.parse(baseUrl + "/get-cart?user_id=${user_id}"),
      headers: {"Authorization": "Bearer ${token}"},
    );
    Map info = jsonDecode(response.body);
    if (info.containsKey("error") &&
        info["error"] == "Invalid authorization token") {
      await NotificationsManager.unsubscribeAllNotifications();
      await SecureStorage.delete();
      await Navigator.of(
        context,
      ).pushNamedAndRemoveUntil("/login", (route) => false);
      return;
    }

    List data = info["data"];

    Map<int, int> cart = {};
    for (var item in data) {
      cart[item["item_id"]] = item["quantity"];
    }

    setState(() {
      quantity = cart;
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
      token = info["token"]!;
      role = info["role"]!;
    });
    await Future.wait([getItems(), getCart()]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!initialized) {
      Map args = {};
      if (ModalRoute.of(context)!.settings.arguments != null) {
        args = ModalRoute.of(context)!.settings.arguments as Map;
      }

      if (args.isNotEmpty) {
        setState(() {
          cart = true;
          quantity = args["quantity"];
          initialized = true;
        });
      }
    }
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
          (cart) ? "Cart" : "Shop",
          style: Theme.of(context).typography.black.headlineMedium!.apply(
            color: Theme.of(context).primaryColorDark,
          ),
        ),
        centerTitle: false,
        actions:
            (cart)
                ? []
                : [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed(
                            "/shop",
                            arguments: {"cart": true, "quantity": quantity},
                          )
                          .then((value) {
                            getCart();
                          });
                    },
                    child: Stack(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          color: Theme.of(context).primaryColorDark,
                          size: 32,
                        ),
                        (quantity.length > 0)
                            ? Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                                child: Center(
                                  child: Text(
                                    quantity.length.toString(),
                                    style: Theme.of(context)
                                        .typography
                                        .white
                                        .labelSmall!
                                        .apply(fontSizeDelta: -2),
                                  ),
                                ),
                              ),
                            )
                            : Container(),
                      ],
                    ),
                  ),
                ],
      ),
      body:
          (cart && quantity.isEmpty)
              ? Center(
                child: Text(
                  "Cart is empty",
                  style: Theme.of(context).typography.black.headlineLarge,
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
                      minHeight:
                          MediaQuery.of(context).size.height -
                          kToolbarHeight -
                          kBottomNavigationBarHeight,
                      minWidth: MediaQuery.of(context).size.width,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 20.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Cart Total: ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          "\$${calculateTotal().toStringAsFixed(2)}",
                                    ),
                                  ],
                                ),
                                style: Theme.of(
                                  context,
                                ).typography.black.labelMedium!.apply(
                                  color: Theme.of(context).primaryColorDark,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                items
                                    .map(
                                      (e) =>
                                          (!cart ||
                                                  quantity.containsKey(
                                                    e["item_id"],
                                                  ))
                                              ? shopItem(
                                                items.indexOf(e),
                                                e["item_id"],
                                                e["name"],
                                                e["price"],
                                                e["image"],
                                              )
                                              : Container(),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      floatingActionButton:
          (role == "admin" && !cart)
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    "/item",
                    arguments: {
                      "callback": () {
                        getItems();
                        getCart();
                      },
                    },
                  );
                },
                child: Icon(Icons.add_rounded),
                backgroundColor: Theme.of(context).primaryColorDark,
                foregroundColor: Theme.of(context).primaryColorLight,
                shape: CircleBorder(),
              )
              : null,
      bottomNavigationBar: Navigation(selected: 3),
    );
  }
}
