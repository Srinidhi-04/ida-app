import "package:flutter/material.dart";
import "package:loading_animation_widget/loading_animation_widget.dart";
import "package:src/services/notifications_manager.dart";
import "package:src/services/secure_storage.dart";
import "package:src/services/settings_service.dart";
import "package:src/widgets/navigation.dart";
import "package:src/widgets/submit_overlay.dart";

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String name;
  late int avatar;
  String original = "";
  bool loaded = false;
  bool submitted = false;
  String? error;
  TextEditingController controller = TextEditingController();

  late int selected;

  Widget avatarOption(int option) {
    return GestureDetector(
      onTap:
          () => setState(() {
            selected = option;
          }),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.12,
        height: MediaQuery.of(context).size.width * 0.12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage("assets/avatars/avatar_${option}.png"),
            colorFilter:
                (option == selected)
                    ? ColorFilter.mode(Color(0x88000000), BlendMode.darken)
                    : null,
          ),
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
      name = info["name"]!;
      avatar = int.parse(info["avatar"]!);
      selected = avatar;
      loaded = true;
      controller.text = name;
      original = name;
    });
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
              "Manage Profile",
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
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Change Avatar",
                            style: Theme.of(
                              context,
                            ).typography.black.labelLarge!.apply(
                              color: Theme.of(context).primaryColorDark,
                              fontWeightDelta: 3,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColorDark,
                            shape: BoxShape.circle,
                          ),
                          width: 150,
                          height: 150,
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Image(
                              image: AssetImage(
                                "assets/avatars/avatar_${selected}.png",
                              ),
                              height: 140,
                              width: 140,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            avatarOption(1),
                            avatarOption(6),
                            avatarOption(2),
                            avatarOption(7),
                            avatarOption(3),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            avatarOption(8),
                            avatarOption(4),
                            avatarOption(9),
                            avatarOption(5),
                            avatarOption(10),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 5),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Change Name",
                            style: Theme.of(
                              context,
                            ).typography.black.labelLarge!.apply(
                              color: Theme.of(context).primaryColorDark,
                              fontWeightDelta: 3,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                        child: TextFormField(
                          keyboardType: TextInputType.name,
                          controller: controller,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Theme.of(context).primaryColor,
                            ),
                            hintText: "Name",
                            errorText: error,
                          ),
                          cursorColor: Theme.of(context).primaryColor,
                          onChanged:
                              (value) => setState(() {
                                name = value.trim();
                              }),
                        ),
                      ),
                      (original != name || avatar != selected)
                          ? TextButton(
                            onPressed: () async {
                              FocusScope.of(context).unfocus();

                              if (name.isEmpty) {
                                setState(() {
                                  error = "Name cannot be empty";
                                });
                                return;
                              }

                              if (RegExp(r"[^a-zA-Z ]").hasMatch(name)) {
                                setState(() {
                                  error = "Invalid name";
                                });
                                return;
                              }

                              setState(() {
                                original = name;
                                avatar = selected;
                                error = null;
                              });
                              SecureStorage.writeMany({
                                "name": name,
                                "avatar": selected.toString(),
                              });

                              Map info = await SettingsService.editProfile(
                                body: {
                                  "name": name,
                                  "avatar": selected.toString(),
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
                            },
                            child: Text(
                              "Save",
                              style: Theme.of(context)
                                  .typography
                                  .white
                                  .labelLarge!
                                  .apply(fontSizeDelta: 2, fontWeightDelta: 3),
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
                          )
                          : SizedBox.shrink(),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: TextButton(
                          onPressed: () async {
                            FocusScope.of(context).unfocus();

                            showDialog(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  actionsAlignment: MainAxisAlignment.end,
                                  title: Text(
                                    "Confirm Deletion",
                                    style:
                                        Theme.of(
                                          context,
                                        ).typography.black.headlineMedium,
                                  ),
                                  content: Text(
                                    "Are you sure you want to delete your account? This action cannot be undone.",
                                    style: Theme.of(context)
                                        .typography
                                        .black
                                        .bodyMedium!
                                        .apply(fontSizeDelta: 2),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(true);
                                      },
                                      child: Text(
                                        "Delete",
                                        style: Theme.of(
                                          context,
                                        ).typography.black.labelMedium!.apply(
                                          fontSizeDelta: 2,
                                          color: Colors.red[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ).then((value) async {
                              if (value != null && value) {
                                setState(() {
                                  submitted = true;
                                });

                                await NotificationsManager.unsubscribeAllNotifications();
                                await SettingsService.deleteAccount();
                                await SecureStorage.delete();
                                await Navigator.of(
                                  context,
                                ).pushNamedAndRemoveUntil(
                                  "/login",
                                  (route) => false,
                                );
                              }
                            });
                          },
                          child: Text(
                            "Delete Account",
                            style: Theme.of(
                              context,
                            ).typography.white.labelLarge!.apply(
                              fontWeightDelta: 3,
                              color: Colors.red[900],
                            ),
                          ),
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              Colors.white,
                            ),
                            foregroundColor: WidgetStatePropertyAll(
                              Colors.red[900],
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.red.shade900),
                              ),
                            ),
                            fixedSize: WidgetStatePropertyAll(
                              Size(MediaQuery.of(context).size.width - 40, 50),
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
          bottomNavigationBar: Navigation(selected: 4),
        ),
        SubmitOverlay(submitted: submitted),
      ],
    );
  }
}
