import "package:flutter/material.dart";
import "package:src/services/notifications_manager.dart";
import "package:src/services/secure_storage.dart";
import "package:src/services/shop_service.dart";
import "package:src/widgets/submit_overlay.dart";

class ItemPage extends StatefulWidget {
  const ItemPage({super.key});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  late int user_id;

  int? item_id;

  String name = "";
  double? price;
  int? inventory;
  int? change;
  String image = "";
  List<String?> errors = [null, null, null, null];
  bool initialized = false;

  bool submitted = false;

  TextEditingController name_controller = TextEditingController();
  TextEditingController price_controller = TextEditingController();
  TextEditingController image_controller = TextEditingController();
  TextEditingController inventory_controller = TextEditingController();
  TextEditingController change_controller = TextEditingController();

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
          item_id = args["item_id"];

          name = args["name"];
          name_controller.text = name;

          price = args["price"];
          price_controller.text = price.toString();

          inventory = args["inventory"];
          inventory_controller.text = inventory.toString();

          image = args["image"];
          image_controller.text = image;
        });
      }

      setState(() {
        initialized = true;
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
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              (item_id == null) ? "Add Item" : "Edit Item",
              style: Theme.of(context).typography.black.headlineMedium!.apply(
                color: Theme.of(context).primaryColorDark,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
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
                        keyboardType: TextInputType.numberWithOptions(
                          signed: false,
                          decimal: true,
                        ),
                        controller: price_controller,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.attach_money_outlined,
                            color: Theme.of(context).primaryColor,
                          ),
                          hintText: "Price",
                          errorText: errors[1],
                        ),
                        cursorColor: Theme.of(context).primaryColor,
                        onChanged:
                            (value) => setState(() {
                              try {
                                if (value.trim() != "") {
                                  price = double.parse(value.trim());
                                  if (price! <= 0) {
                                    errors[1] = "Price must be positive";
                                  } else {
                                    errors[1] = null;
                                  }
                                } else {
                                  price = null;
                                  errors[1] = null;
                                }
                              } catch (e) {
                                errors[1] = "Price must be a float";
                              }
                            }),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        controller: inventory_controller,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.inventory_2_outlined,
                            color: Theme.of(context).primaryColor,
                          ),
                          hintText: "Inventory",
                          errorText: errors[2],
                        ),
                        cursorColor: Theme.of(context).primaryColor,
                        onChanged:
                            (value) => setState(() {
                              try {
                                if (value.trim() != "") {
                                  inventory = int.parse(value.trim());
                                  if (inventory! < 0) {
                                    errors[2] =
                                        "Inventory must not be negative";
                                  } else {
                                    errors[2] = null;
                                  }
                                } else {
                                  inventory = null;
                                  errors[2] = null;
                                }
                              } catch (e) {
                                errors[2] = "Inventory must be an int";
                              }
                            }),
                      ),
                    ),
                    (item_id != null)
                        ? Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  keyboardType: TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: false
                                  ),
                                  controller: change_controller,
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.unfold_more_outlined,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    hintText: "Change Inventory",
                                    errorText: errors[3],
                                  ),
                                  cursorColor: Theme.of(context).primaryColor,
                                  onChanged: (value) {
                                    setState(() {
                                      try {
                                        if (value.trim() != "") {
                                          change = int.parse(value.trim());
                                          if (inventory! + change! < 0) {
                                            errors[3] =
                                                "Cannot have a negative inventory";
                                          } else {
                                            errors[3] = null;
                                          }
                                        } else {
                                          change = null;
                                          errors[3] = null;
                                        }
                                      } catch (e) {
                                        errors[3] = "Change must be an int";
                                      }
                                    });
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
                                child: TextButton(
                                  onPressed: () async {
                                    if (errors[3] != null) {
                                      return;
                                    }

                                    FocusScope.of(context).unfocus();

                                    if (change == null)
                                      errors[3] = "Enter a number to change";
                                    else
                                      errors[3] = null;

                                    if (errors[3] == null) {
                                      setState(() {
                                        submitted = true;
                                      });

                                      Map info =
                                          await ShopService.changeInventory(
                                            body: {
                                              "user_id": user_id.toString(),
                                              "item_id": item_id.toString(),
                                              "quantity": change.toString(),
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
                                      } else if (info.containsKey("error") &&
                                          (info["error"] ==
                                              "Not enough items in inventory to reduce")) {
                                        setState(() {
                                          inventory_controller.text =
                                              info["inventory"].toString();
                                          errors[3] = info["error"];
                                          submitted = false;
                                        });
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

                                      setState(() {
                                        change_controller.text = "";
                                        inventory_controller.text =
                                            info["inventory"].toString();
                                      });
                                    }

                                    setState(() {
                                      errors = errors;
                                      submitted = false;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      "Change",
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
                        )
                        : SizedBox.shrink(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextFormField(
                        keyboardType: TextInputType.webSearch,
                        controller: image_controller,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.image_outlined,
                            color: Theme.of(context).primaryColor,
                          ),
                          hintText: "Thumbnail",
                        ),
                        cursorColor: Theme.of(context).primaryColor,
                        onChanged:
                            (value) => setState(() {
                              image = value.trim();
                            }),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: TextButton(
                        onPressed: () async {
                          if (errors[1] != null || errors[2] != null) {
                            return;
                          }

                          FocusScope.of(context).unfocus();

                          if (name == "")
                            errors[0] = "Name is a required field";
                          else
                            errors[0] = null;

                          if (price == null)
                            errors[1] = "Price is a required field";
                          else
                            errors[1] = null;

                          if (inventory == null)
                            errors[2] = "Inventory is a required field";
                          else
                            errors[2] = null;

                          if (errors[0] == null &&
                              errors[1] == null &&
                              errors[2] == null) {
                            setState(() {
                              submitted = true;
                            });

                            if (item_id == null) {
                              Map info = await ShopService.addItem(
                                body: {
                                  "user_id": user_id.toString(),
                                  "name": name,
                                  "price": price.toString(),
                                  "image": image,
                                  "inventory": inventory.toString(),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      info["error"],
                                      style: Theme.of(
                                        context,
                                      ).typography.white.bodyMedium!.apply(
                                        color:
                                            Theme.of(context).primaryColorLight,
                                      ),
                                    ),
                                    backgroundColor:
                                        Theme.of(context).primaryColorDark,
                                    showCloseIcon: true,
                                    closeIconColor:
                                        Theme.of(context).primaryColorLight,
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(context);
                            } else {
                              Map info = await ShopService.editItem(
                                body: {
                                  "user_id": user_id.toString(),
                                  "item_id": item_id.toString(),
                                  "name": name,
                                  "price": price.toString(),
                                  "image": image,
                                  "inventory": inventory.toString(),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      info["error"],
                                      style: Theme.of(
                                        context,
                                      ).typography.white.bodyMedium!.apply(
                                        color:
                                            Theme.of(context).primaryColorLight,
                                      ),
                                    ),
                                    backgroundColor:
                                        Theme.of(context).primaryColorDark,
                                    showCloseIcon: true,
                                    closeIconColor:
                                        Theme.of(context).primaryColorLight,
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(context);
                              return;
                            }
                          }

                          setState(() {
                            errors = errors;
                            submitted = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            (item_id == null) ? "Add" : "Save",
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
                          foregroundColor: WidgetStatePropertyAll(Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SubmitOverlay(submitted: submitted),
      ],
    );
  }
}
