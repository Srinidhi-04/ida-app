import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/auth_service.dart';
import 'package:src/services/notifications_manager.dart';
import 'package:src/services/payments_service.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/services/shop_service.dart';
import 'package:src/widgets/cart_button.dart';
import 'package:src/widgets/navigation.dart';
import 'package:src/widgets/submit_overlay.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late int user_id;
  late String role;

  Map<int, int> quantity = {};
  List items = [];

  bool cart = false;
  bool initialized = false;

  List<bool> loaded = [false, false, false, false];

  List<String> admin_roles = ["admin", "merch"];
  bool admin_access = false;

  bool submitted = false;

  String banner = "";

  Widget shopItem(
    int index,
    int item_id,
    String name,
    double price,
    int inventory,
    String image,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Slidable(
          key: ValueKey(item_id),
          enabled: ((admin_roles.contains(role) || admin_access) && !cart),
          endActionPane: ActionPane(
            motion: BehindMotion(),
            dismissible: DismissiblePane(
              onDismissed: () async {
                setState(() {
                  items.removeAt(index);
                });

                Map info = await ShopService.deleteItem(
                  body: {
                    "user_id": user_id.toString(),
                    "item_id": item_id.toString(),
                  },
                );

                if (info.containsKey("error") &&
                    (info["error"] == "Invalid authorization token" ||
                        info["error"] ==
                            "A user with that user ID does not exist")) {
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
                        style: Theme.of(context).typography.white.bodyMedium!
                            .apply(color: Theme.of(context).primaryColorLight),
                      ),
                      backgroundColor: Theme.of(context).primaryColorDark,
                      showCloseIcon: true,
                      closeIconColor: Theme.of(context).primaryColorLight,
                    ),
                  );
                  return;
                }

                getItems();
                getCart();
              },
            ),
            children: [
              CustomSlidableAction(
                onPressed: (slideContext) async {
                  Navigator.of(context)
                      .pushNamed(
                        "/item",
                        arguments: {
                          "item_id": item_id,
                          "name": name,
                          "price": price,
                          "inventory": inventory,
                          "image": image,
                        },
                      )
                      .then((_) => checkLogin());
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

                  Map info = await ShopService.deleteItem(
                    body: {
                      "user_id": user_id.toString(),
                      "item_id": item_id.toString(),
                    },
                  );

                  if (info.containsKey("error") &&
                      (info["error"] == "Invalid authorization token" ||
                          info["error"] ==
                              "A user with that user ID does not exist")) {
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
                          style: Theme.of(
                            context,
                          ).typography.white.bodyMedium!.apply(
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
            child: Stack(
              children: [
                Padding(
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: Theme.of(
                                        context,
                                      ).typography.white.labelLarge!.apply(
                                        color:
                                            Theme.of(context).primaryColorLight,
                                        fontWeightDelta: 3,
                                      ),
                                    ),
                                    Text(
                                      "\$${price.toStringAsFixed(2)}",
                                      style: Theme.of(
                                        context,
                                      ).typography.black.labelMedium!.apply(
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        fontWeightDelta: 3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              (inventory > 0)
                                  ? Align(
                                    alignment: Alignment.centerRight,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        (!quantity.containsKey(item_id) ||
                                                quantity[item_id] == 0)
                                            ? TextButton(
                                              onPressed: () async {
                                                setState(() {
                                                  quantity[item_id] = 1;
                                                });

                                                Map info =
                                                    await ShopService.editCart(
                                                      body: {
                                                        "user_id":
                                                            user_id.toString(),
                                                        "item_id":
                                                            item_id.toString(),
                                                        "quantity": "1",
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
                                                } else if (info.containsKey(
                                                  "error",
                                                )) {
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
                                              },
                                              child: Text(
                                                "Add to cart",
                                                style: Theme.of(context)
                                                    .typography
                                                    .black
                                                    .labelSmall!
                                                    .apply(
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).primaryColorDark,
                                                      fontWeightDelta: 3,
                                                    ),
                                              ),
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    WidgetStatePropertyAll(
                                                      Theme.of(
                                                        context,
                                                      ).primaryColorLight,
                                                    ),
                                                shape: WidgetStatePropertyAll(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          30,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            : Container(
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(30),
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
                                                    constraints:
                                                        BoxConstraints(),
                                                    padding: EdgeInsets.zero,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    onPressed: () async {
                                                      setState(() {
                                                        quantity[item_id] =
                                                            quantity[item_id]! -
                                                            1;
                                                        if (quantity[item_id] ==
                                                            0)
                                                          quantity.remove(
                                                            item_id,
                                                          );
                                                      });

                                                      Map
                                                      info = await ShopService.editCart(
                                                        body: {
                                                          "user_id":
                                                              user_id
                                                                  .toString(),
                                                          "item_id":
                                                              item_id
                                                                  .toString(),
                                                          "quantity":
                                                              ((quantity
                                                                      .containsKey(
                                                                        item_id,
                                                                      ))
                                                                  ? quantity[item_id]
                                                                      .toString()
                                                                  : "0"),
                                                        },
                                                      );

                                                      if (info.containsKey(
                                                            "error",
                                                          ) &&
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
                                                      } else if (info
                                                          .containsKey(
                                                            "error",
                                                          )) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              info["error"],
                                                              style: Theme.of(
                                                                    context,
                                                                  )
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
                                                    },
                                                    icon: Icon(
                                                      Icons.remove,
                                                      size: 15,
                                                    ),
                                                  ),
                                                  Text(
                                                    quantity[item_id]!
                                                        .toString(),
                                                    style:
                                                        Theme.of(context)
                                                            .typography
                                                            .black
                                                            .labelSmall,
                                                  ),
                                                  IconButton(
                                                    constraints:
                                                        BoxConstraints(),
                                                    padding: EdgeInsets.zero,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    onPressed:
                                                        (quantity[item_id]! >=
                                                                inventory)
                                                            ? null
                                                            : () async {
                                                              setState(() {
                                                                quantity[item_id] =
                                                                    quantity[item_id]! +
                                                                    1;
                                                              });

                                                              Map
                                                              info = await ShopService.editCart(
                                                                body: {
                                                                  "user_id":
                                                                      user_id
                                                                          .toString(),
                                                                  "item_id":
                                                                      item_id
                                                                          .toString(),
                                                                  "quantity":
                                                                      quantity[item_id]
                                                                          .toString(),
                                                                },
                                                              );

                                                              if (info.containsKey(
                                                                    "error",
                                                                  ) &&
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
                                                                  (route) =>
                                                                      false,
                                                                );
                                                                return;
                                                              } else if (info
                                                                  .containsKey(
                                                                    "error",
                                                                  )) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      info["error"],
                                                                      style: Theme.of(
                                                                        context,
                                                                      ).typography.white.bodyMedium!.apply(
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
                                                                    showCloseIcon:
                                                                        true,
                                                                    closeIconColor:
                                                                        Theme.of(
                                                                          context,
                                                                        ).primaryColorLight,
                                                                  ),
                                                                );
                                                                return;
                                                              }
                                                            },
                                                    icon: Icon(
                                                      Icons.add,
                                                      size: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        (quantity.containsKey(item_id) &&
                                                quantity[item_id]! > 0)
                                            ? Padding(
                                              padding: const EdgeInsets.only(
                                                top: 5.0,
                                              ),
                                              child: Text(
                                                "Total Price: \$${(quantity[item_id]! * price).toStringAsFixed(2)}",
                                                style: Theme.of(context)
                                                    .typography
                                                    .black
                                                    .labelSmall!
                                                    .apply(
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).primaryColorDark,
                                                      fontWeightDelta: 3,
                                                    ),
                                              ),
                                            )
                                            : SizedBox.shrink(),
                                      ],
                                    ),
                                  )
                                  : SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                (inventory <= 0)
                    ? Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color(0x77000000),
                        ),
                        alignment: Alignment.center,
                        child: Center(
                          child: Container(
                            height: 30,
                            width: double.infinity,
                            color: Colors.red,
                            child: Center(
                              child: Text(
                                "Out of stock",
                                style:
                                    Theme.of(
                                      context,
                                    ).typography.white.labelMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    : SizedBox.shrink(),
              ],
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
    Map info = await ShopService.getItems(
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

    List all_items = info["data"];

    setState(() {
      items = all_items;
      loaded[0] = true;
    });
  }

  Future<void> getCart() async {
    Map info = await ShopService.getCart(
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
      loaded[2] = true;
    });
  }

  Future<void> getBanner() async {
    Map info = await ShopService.getBanner(
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

    setState(() {
      banner = info["message"];
      loaded[3] = true;
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
    await Future.wait([getItems(), getCart(), getPermissions(), getBanner()]);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLogin();
    });
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

    return Stack(
      children: [
        Scaffold(
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
                      CartButton(quantity: quantity, callback: () => getCart()),
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
                              MediaQuery.of(context).padding.top -
                              kBottomNavigationBarHeight,
                          minWidth: MediaQuery.of(context).size.width,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Column(
                            children: [
                              (!cart && banner.isNotEmpty)
                                  ? Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 10.0,
                                    ),
                                    child: Container(
                                      color:
                                          Theme.of(context).primaryColorLight,
                                      width: MediaQuery.of(context).size.width,
                                      height: 125,
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Text.rich(
                                            TextSpan(
                                              children:
                                                  banner
                                                      .split(" ")
                                                      .map(
                                                        (e) =>
                                                            (e.startsWith(
                                                                      "https://",
                                                                    ) ||
                                                                    e.startsWith(
                                                                      "www.",
                                                                    ))
                                                                ? TextSpan(
                                                                  text: e + " ",
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color:
                                                                        Theme.of(
                                                                          context,
                                                                        ).primaryColorDark,
                                                                    decoration:
                                                                        TextDecoration
                                                                            .underline,
                                                                  ),
                                                                  recognizer:
                                                                      TapGestureRecognizer()
                                                                        ..onTap = () {
                                                                          launchUrl(
                                                                            Uri.parse(
                                                                              e,
                                                                            ),
                                                                          );
                                                                        },
                                                                )
                                                                : TextSpan(
                                                                  text: e + " ",
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color:
                                                                        Theme.of(
                                                                          context,
                                                                        ).primaryColorDark,
                                                                  ),
                                                                ),
                                                      )
                                                      .toList(),
                                            ),
                                            style: Theme.of(context)
                                                .typography
                                                .black
                                                .labelMedium!
                                                .apply(fontSizeDelta: 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  : SizedBox.shrink(),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 20, 5),
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
                                      fontSizeDelta: 2,
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
                                                    e["inventory"],
                                                    e["image"],
                                                  )
                                                  : SizedBox.shrink(),
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
              ((admin_roles.contains(role) || admin_access) && !cart)
                  ? FloatingActionButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamed("/item").then((_) => checkLogin());
                    },
                    child: Icon(Icons.add_rounded),
                    backgroundColor: Theme.of(context).primaryColorDark,
                    foregroundColor: Theme.of(context).primaryColorLight,
                    shape: CircleBorder(),
                  )
                  : (cart && quantity.isNotEmpty)
                  ? FloatingActionButton(
                    onPressed: () async {
                      setState(() {
                        submitted = true;
                      });

                      double cart_total = calculateTotal();

                      List<Map> order_list = [];
                      for (var item in items) {
                        if (quantity.containsKey(item["item_id"])) {
                          order_list.add({
                            "item_id": item["item_id"],
                            "quantity": quantity[item["item_id"]],
                            "amount":
                                quantity[item["item_id"]]! * item["price"],
                          });
                        }
                      }

                      Map info = await PaymentsService.startOrder(
                        jsonBody: jsonEncode({
                          "user_id": user_id,
                          "amount": cart_total,
                          "cart": order_list,
                        }),
                      );

                      if (info.containsKey("error") &&
                          (info["error"] == "Invalid authorization token" ||
                              info["error"] ==
                                  "A user with that user ID does not exist")) {
                        await NotificationsManager.unsubscribeAllNotifications();
                        await SecureStorage.delete();
                        await Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil("/login", (route) => false);
                        return;
                      } else if (info.containsKey("error") &&
                          info["error"] == "Not enough items in inventory") {
                        await checkLogin();
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
                                  "Caution",
                                  style:
                                      Theme.of(
                                        context,
                                      ).typography.black.headlineMedium,
                                ),
                                content: Text(
                                  "Some items in your order are low in stock, so their quantities have been adjusted to match our current inventory. Please review your updated order before proceeding.",
                                  style: Theme.of(context)
                                      .typography
                                      .black
                                      .bodyMedium!
                                      .apply(fontSizeDelta: 2),
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
                        setState(() {
                          submitted = false;
                        });
                        return;
                      } else if (info.containsKey("error")) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              info["error"],
                              style: Theme.of(
                                context,
                              ).typography.white.bodyMedium!.apply(
                                color: Theme.of(context).primaryColorLight,
                              ),
                            ),
                            backgroundColor: Theme.of(context).primaryColorDark,
                            showCloseIcon: true,
                            closeIconColor: Theme.of(context).primaryColorLight,
                          ),
                        );
                        setState(() {
                          submitted = false;
                        });
                        return;
                      }

                      String payment_id = info["payment_id"];

                      await Stripe.instance.initPaymentSheet(
                        paymentSheetParameters: SetupPaymentSheetParameters(
                          customFlow: false,
                          paymentIntentClientSecret: info["payment_intent"],
                          merchantDisplayName: "Illini Dads Association",
                          style: ThemeMode.light,
                          applePay: const PaymentSheetApplePay(
                            merchantCountryCode: "US",
                            buttonType: PlatformButtonType.checkout,
                          ),
                          googlePay: const PaymentSheetGooglePay(
                            testEnv: false,
                            currencyCode: "USD",
                            merchantCountryCode: "US",
                            buttonType: PlatformButtonType.checkout,
                          ),
                        ),
                      );

                      setState(() {
                        submitted = false;
                      });

                      try {
                        await Stripe.instance.presentPaymentSheet();

                        setState(() {
                          submitted = true;
                        });

                        Map info = await PaymentsService.logOrder(
                          jsonBody: jsonEncode({
                            "user_id": user_id,
                            "value": cart_total,
                            "cart": order_list,
                            "payment_intent": payment_id,
                          }),
                        );

                        if (info.containsKey("error") &&
                            (info["error"] == "Invalid authorization token" ||
                                info["error"] ==
                                    "A user with that user ID does not exist")) {
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
                                style: Theme.of(
                                  context,
                                ).typography.white.bodyMedium!.apply(
                                  color: Theme.of(context).primaryColorLight,
                                ),
                              ),
                              backgroundColor:
                                  Theme.of(context).primaryColorDark,
                              showCloseIcon: true,
                              closeIconColor:
                                  Theme.of(context).primaryColorLight,
                            ),
                          );
                          setState(() {
                            submitted = false;
                          });
                          return;
                        }

                        setState(() {
                          submitted = false;
                          quantity = {};
                        });

                        Navigator.of(context).popAndPushNamed(
                          "/order",
                          arguments: {
                            "user_id": user_id,
                            "order_id": info["order_id"],
                            "date": DateTime.parse(info["date"]).toLocal(),
                            "receipt": info["receipt"],
                            "status": info["status"],
                            "amount": info["amount"],
                          },
                        );
                        return;
                      } catch (e) {
                        setState(() {
                          submitted = true;
                        });

                        await PaymentsService.cancelOrder(
                          jsonBody: jsonEncode({
                            "user_id": user_id,
                            "cart": order_list,
                          }),
                        );
                      }

                      setState(() {
                        submitted = false;
                      });
                    },
                    child: Icon(Icons.payment_outlined),
                    backgroundColor: Theme.of(context).primaryColorDark,
                    foregroundColor: Theme.of(context).primaryColorLight,
                    shape: CircleBorder(),
                  )
                  : null,
          bottomNavigationBar: Navigation(selected: 3),
        ),
        SubmitOverlay(submitted: submitted),
      ],
    );
  }
}
