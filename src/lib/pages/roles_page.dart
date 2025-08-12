import "package:flutter/material.dart";
import "package:loading_animation_widget/loading_animation_widget.dart";
import "package:src/services/notifications_manager.dart";
import "package:src/services/secure_storage.dart";
import "package:src/services/settings_service.dart";
import "package:src/widgets/navigation.dart";
import "package:src/widgets/submit_overlay.dart";

class RolesPage extends StatefulWidget {
  const RolesPage({super.key});

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  late int user_id;
  late String email;
  String original = "";
  String role = "";
  bool loaded = false;
  TextEditingController controller = TextEditingController();

  late List roles;
  late List emails;
  late int total_users;

  bool autocomplete = true;

  bool submitted = false;

  Future<void> getRoles() async {
    Map info = await SettingsService.getRoles(
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
      controller.text = "";
      autocomplete = true;
      original = "";
      role = "";
      roles = info["data"]["roles"];
      emails = info["data"]["emails"];
      total_users = info["data"]["total_users"];
      loaded = true;
    });
  }

  Widget generateAutocomplete(String text, bool generate) {
    if (text == "" || !autocomplete) return SizedBox.shrink();

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
      email = info["email"]!;
    });
    await getRoles();
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
                      MediaQuery.of(context).padding.top -
                      kBottomNavigationBarHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Divider(color: Theme.of(context).primaryColor),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "Total Users: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: total_users.toString()),
                              ],
                            ),
                            style: Theme.of(context)
                                .typography
                                .black
                                .labelMedium!
                                .apply(fontSizeDelta: 2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 5),
                        child: TextFormField(
                          keyboardType: TextInputType.emailAddress,
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
                        controller.text.trim().toLowerCase(),
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
                                                content: Padding(
                                                  padding: const EdgeInsets.all(
                                                    10.0,
                                                  ),
                                                  child: TextFormField(
                                                    textAlignVertical:
                                                        TextAlignVertical
                                                            .center,
                                                    decoration: InputDecoration(
                                                      prefixIcon: Icon(
                                                        Icons.shield_outlined,
                                                        color:
                                                            Theme.of(
                                                              context,
                                                            ).primaryColor,
                                                      ),
                                                      hintText: "Role",
                                                      errorText: dialog_error,
                                                    ),
                                                    cursorColor:
                                                        Theme.of(
                                                          context,
                                                        ).primaryColor,
                                                    onChanged:
                                                        (value) => setState(() {
                                                          new_role =
                                                              value.trim();
                                                        }),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
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

                                                      Navigator.of(
                                                        dialogContext,
                                                      ).pop(new_role);
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
                                    ).then((new_role) {
                                      if (new_role != null) {
                                        setState(() {
                                          roles.add(new_role.toLowerCase());
                                          role = new_role.toLowerCase();
                                        });
                                      }
                                    });
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
                          : SizedBox.shrink(),
                      (original != role)
                          ? Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: TextButton(
                              onPressed: () async {
                                FocusScope.of(context).unfocus();

                                setState(() {
                                  submitted = true;
                                });

                                Map info = await SettingsService.editRole(
                                  body: {
                                    "user_id": user_id.toString(),
                                    "email": controller.text,
                                    "role": role,
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
                                              Theme.of(
                                                context,
                                              ).primaryColorLight,
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

                                await getRoles();

                                setState(() {
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
                          : SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: Navigation(selected: 4),
        ),
        SubmitOverlay(submitted: submitted),
      ],
    );
  }
}
