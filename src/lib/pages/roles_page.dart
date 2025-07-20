import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart";
import "package:loading_animation_widget/loading_animation_widget.dart";
import "package:src/services/notifications_manager.dart";
import "package:src/services/secure_storage.dart";
import "package:src/widgets/navigation.dart";

class RolesPage extends StatefulWidget {
  const RolesPage({super.key});

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  late int user_id;
  late String token;
  late String email;
  String original = "";
  String role = "";
  bool loaded = false;
  TextEditingController controller = TextEditingController();

  late List roles;
  late List emails;

  bool autocomplete = true;

  bool submitted = false;

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  Future<void> getRoles() async {
    var response = await get(
      Uri.parse(baseUrl + "/get-roles?user_id=${user_id}"),
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

    setState(() {
      roles = info["data"]["roles"];
      emails = info["data"]["emails"];
      loaded = true;
    });
  }

  Widget generateAutocomplete(String text, bool generate) {
    if (text == "" || !autocomplete) return Container();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: BoxBorder.all(color: Theme.of(context).primaryColor),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:
              emails
                  .where(
                    (e) =>
                        (e["email"].toLowerCase().contains(text) &&
                            e["email"] != email),
                  )
                  .map(
                    (e) => TextButton(
                      onPressed: () {
                        setState(() {
                          controller.text = e["email"];
                          original = e["role"];
                          role = original;
                          autocomplete = false;
                        });
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          e["email"],
                          style: Theme.of(context).typography.black.labelMedium,
                        ),
                      ),
                      style: ButtonStyle(
                        shape: WidgetStatePropertyAll(
                          LinearBorder.bottom(
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
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
      email = info["email"]!;
    });
    await getRoles();
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
            title: Text(
              "Assign Roles",
              style: Theme.of(context).typography.black.headlineMedium!.apply(
                color: Theme.of(context).primaryColorDark,
              ),
            ),
            centerTitle: false,
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
                  minWidth: MediaQuery.of(context).size.width,
                  minHeight:
                      MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      kBottomNavigationBarHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Divider(color: Theme.of(context).primaryColor),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 5),
                        child: TextFormField(
                          controller: controller,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Theme.of(context).primaryColor,
                            ),
                            hintText: "Email",
                          ),
                          cursorColor: Theme.of(context).primaryColor,
                          onChanged:
                              (value) => setState(() {
                                autocomplete = true;
                              }),
                        ),
                      ),
                      generateAutocomplete(
                        controller.text.toLowerCase(),
                        autocomplete,
                      ),
                      (!autocomplete)
                          ? Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Row(
                              children: [
                                Text(
                                  "Role:",
                                  style:
                                      Theme.of(
                                        context,
                                      ).typography.black.labelLarge,
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    10,
                                    0,
                                    30,
                                    0,
                                  ),
                                  child: DropdownButton(
                                    value: role,
                                    icon: const Icon(Icons.swap_vert),
                                    elevation: 16,
                                    style:
                                        Theme.of(
                                          context,
                                        ).typography.black.labelMedium,
                                    dropdownColor: Colors.white,
                                    onChanged: (String? value) {
                                      setState(() {
                                        role = value!;
                                      });
                                    },
                                    items:
                                        roles.map<DropdownMenuItem<String>>((
                                          var value,
                                        ) {
                                          String v = value.toString();
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              v.substring(0, 1).toUpperCase() +
                                                  v.substring(1),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (dialogContext) {
                                        String new_role = "";
                                        String? dialog_error;

                                        return StatefulBuilder(
                                          builder:
                                              (
                                                stateContext,
                                                setDialogState,
                                              ) => AlertDialog(
                                                backgroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                actionsAlignment:
                                                    MainAxisAlignment.end,
                                                title: Text(
                                                  "New Role",
                                                  style:
                                                      Theme.of(context)
                                                          .typography
                                                          .black
                                                          .headlineMedium,
                                                ),
                                                content: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              10.0,
                                                            ),
                                                        child: TextFormField(
                                                          textAlignVertical:
                                                              TextAlignVertical
                                                                  .center,
                                                          decoration: InputDecoration(
                                                            prefixIcon: Icon(
                                                              Icons
                                                                  .shield_outlined,
                                                              color:
                                                                  Theme.of(
                                                                    context,
                                                                  ).primaryColor,
                                                            ),
                                                            hintText: "Role",
                                                            errorText:
                                                                dialog_error,
                                                          ),
                                                          cursorColor:
                                                              Theme.of(
                                                                context,
                                                              ).primaryColor,
                                                          onChanged:
                                                              (value) =>
                                                                  setState(() {
                                                                    new_role =
                                                                        value;
                                                                  }),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      new_role =
                                                          new_role.trim();

                                                      if (new_role.isEmpty) {
                                                        setDialogState(() {
                                                          dialog_error =
                                                              "Role cannot be blank";
                                                        });
                                                        return;
                                                      }

                                                      if (RegExp(
                                                        r"[^a-zA-Z ]",
                                                      ).hasMatch(new_role)) {
                                                        setDialogState(() {
                                                          dialog_error =
                                                              "Role can only have letters and whitespaces";
                                                        });
                                                        return;
                                                      }

                                                      setState(() {
                                                        roles.add(
                                                          new_role
                                                              .toLowerCase(),
                                                        );
                                                        role =
                                                            new_role
                                                                .toLowerCase();
                                                        Navigator.pop(
                                                          dialogContext,
                                                        );
                                                      });
                                                    },
                                                    child: Text(
                                                      "Create",
                                                      style: Theme.of(context)
                                                          .typography
                                                          .black
                                                          .labelMedium!
                                                          .apply(
                                                            fontSizeDelta: 2,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        );
                                      },
                                    );
                                  },
                                  label: Text(
                                    "Create Role",
                                    style:
                                        Theme.of(
                                          context,
                                        ).typography.white.labelMedium,
                                  ),
                                  icon: Icon(Icons.add_circle_outline),
                                  style: ButtonStyle(
                                    foregroundColor: WidgetStatePropertyAll(
                                      Colors.white,
                                    ),
                                    backgroundColor: WidgetStatePropertyAll(
                                      Theme.of(context).primaryColorLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : Container(),
                      (original != role)
                          ? Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: TextButton(
                              onPressed: () async {
                                setState(() {
                                  submitted = true;
                                });

                                var response = await post(
                                  Uri.parse(baseUrl + "/edit-role/"),
                                  headers: {"Authorization": "Bearer ${token}"},
                                  body: {
                                    "user_id": user_id.toString(),
                                    "email": controller.text,
                                    "role": role,
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

                                print(info);

                                setState(() {
                                  controller.text = "";
                                  autocomplete = true;
                                  original = "";
                                  role = "";
                                  submitted = false;
                                });
                              },
                              child: Text(
                                "Save",
                                style: Theme.of(
                                  context,
                                ).typography.white.labelLarge!.apply(
                                  fontSizeDelta: 2,
                                  fontWeightDelta: 3,
                                ),
                              ),
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                  Theme.of(context).primaryColor,
                                ),
                                fixedSize: WidgetStatePropertyAll(
                                  Size(
                                    0.6 * MediaQuery.of(context).size.width,
                                    50,
                                  ),
                                ),
                                elevation: WidgetStatePropertyAll(10),
                              ),
                            ),
                          )
                          : Container(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: Navigation(selected: 4),
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
