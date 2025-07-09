import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/notifications_manager.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/widgets/navigation.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late int user_id;
  late String token;
  late bool admin;
  late String name;
  late int avatar;
  late String email;
  late String reminders;

  bool loaded = false;
  bool submitted = false;

  Widget profileButton(String name, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        child: TextButton(
          onPressed: () {
            Navigator.pushNamed(context, route).then((value) => checkLogin());
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: Theme.of(context).typography.black.labelMedium!.apply(),
              ),
              Icon(Icons.keyboard_arrow_right_outlined, color: Colors.black),
            ],
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
        await SecureStorage.delete();
        await Navigator.popAndPushNamed(context, "/login");
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
      name = info["name"]!;
      avatar = int.parse(info["avatar"]!);
      admin = bool.parse(info["admin"]!);
      reminders = info["reminders"]!;
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
            title: Text(
              "Profile",
              style: Theme.of(
                context,
              ).typography.white.headlineLarge!.apply(fontWeightDelta: 3),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          extendBodyBehindAppBar: true,
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
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Column(
                          children: [
                            Container(
                              color: Theme.of(context).primaryColorDark,
                              width: MediaQuery.of(context).size.width,
                              height: 175,
                            ),
                            Container(
                              color: Colors.white,
                              width: MediaQuery.of(context).size.width,
                              height: 75,
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                "/settings",
                              ).then((value) => checkLogin()),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            width: 150,
                            height: 150,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Image(
                                image: AssetImage(
                                  "assets/avatar_${avatar}.png",
                                ),
                                width: 140,
                                height: 140,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    (admin)
                        ? Padding(
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                          child: Text(
                            "Admin",
                            style:
                                Theme.of(context).typography.black.labelSmall,
                          ),
                        )
                        : Container(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                      child: Text(
                        name,
                        style: Theme.of(context).typography.black.labelMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
                      child: Text(
                        email,
                        style: Theme.of(context).typography.black.labelMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          profileButton(
                            "Notification Settings",
                            "/notifications",
                          ),
                          Divider(
                            color: Theme.of(context).primaryColor,
                            indent: 75,
                            endIndent: 75,
                          ),
                          profileButton("Profile Settings", "/settings"),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        setState(() {
                          submitted = true;
                        });

                        await NotificationsManager.unsubscribeAllNotifications(
                          user_id,
                          token,
                          reminders,
                        );

                        await SecureStorage.delete();
                        await Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil("/login", (route) => false);

                        setState(() {
                          submitted = false;
                        });
                      },
                      child: Text(
                        "LOG OUT",
                        style: Theme.of(context).typography.white.labelLarge!
                            .apply(fontSizeDelta: 2, fontWeightDelta: 3),
                      ),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          Theme.of(context).primaryColor,
                        ),
                        fixedSize: WidgetStatePropertyAll(
                          Size(0.6 * MediaQuery.of(context).size.width, 50),
                        ),
                        elevation: WidgetStatePropertyAll(10),
                      ),
                    ),
                  ],
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
