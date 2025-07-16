import 'dart:convert';

import 'package:flutter/material.dart';
import "package:http/http.dart";
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/notifications_manager.dart';
import 'package:src/services/secure_storage.dart';

class CirclePainter extends CustomPainter {
  Color color;
  Offset location;
  CirclePainter({required this.color, required this.location});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.strokeWidth = 2;
    paint.color = color;
    paint.shader = RadialGradient(
      colors: [color, Colors.white],
    ).createShader(Rect.fromCircle(center: location, radius: size.width / 2));
    canvas.drawCircle(location, size.width / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = "";
  String password = "";
  String error = "";
  bool submitted = false;

  List<String> alerts = [
    "Off",
    "30 minutes before",
    "2 hours before",
    "6 hours before",
  ];

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  Future<bool> login() async {
    setState(() {
      submitted = true;
    });
    var response = await post(
      Uri.parse(baseUrl + "/login/"),
      body: {"email": email, "password": password},
    );
    Map info = jsonDecode(response.body);
    if (info.containsKey("error")) {
      setState(() {
        error = info["error"];
        submitted = false;
      });
      return false;
    }

    if (info["reminders"] == null) {
      await SecureStorage.writeMany({
        "user_id": info["user_id"].toString(),
        "email": info["email"],
      });
      Navigator.popAndPushNamed(context, "/verify");
      setState(() {
        submitted = false;
      });
      return true;
    }

    await SecureStorage.writeMany({
      "user_id": info["user_id"].toString(),
      "last_login": DateTime.now().toString(),
      "email": info["email"].toString(),
      "name": info["name"].toString(),
      "avatar": info["avatar"].toString(),
      "admin": info["admin"].toString(),
      "reminders": info["reminders"].toString(),
      "announcements": info["announcements"].toString(),
      "token": info["token"].toString(),
    });

    await NotificationsManager.subscribeAllNotifications(
      info["user_id"],
      info["token"],
      info["reminders"],
      info["announcements"],
    );

    Navigator.popAndPushNamed(context, "/home");

    setState(() {
      submitted = false;
    });
    return true;
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
  }

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(350, 350),
                  painter: CirclePainter(
                    color: Theme.of(context).primaryColorDark,
                    location: Offset(0, MediaQuery.of(context).size.height),
                  ),
                ),
                CustomPaint(
                  size: Size(350, 350),
                  painter: CirclePainter(
                    color: Theme.of(context).primaryColorLight,
                    location: Offset(MediaQuery.of(context).size.width, 0),
                  ),
                ),
                SingleChildScrollView(
                  child: Container(
                    color: Color(0x77FFFFFF),
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Image(
                          image: AssetImage("assets/logo.png"),
                          width: MediaQuery.of(context).size.width * 0.6,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Log In",
                              style: Theme.of(
                                context,
                              ).typography.black.headlineLarge!.apply(
                                color: Theme.of(context).primaryColorDark,
                                fontWeightDelta: 3,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                30,
                                20,
                                30,
                                10,
                              ),
                              child: TextFormField(
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
                                      email = value;
                                    }),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                30,
                                10,
                                30,
                                10,
                              ),
                              child: TextFormField(
                                textAlignVertical: TextAlignVertical.center,
                                obscureText: true,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.lock_outlined,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  hintText: "Password",
                                ),
                                cursorColor: Theme.of(context).primaryColor,
                                onChanged:
                                    (value) => setState(() {
                                      password = value;
                                    }),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  30,
                                  10,
                                ),
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.popAndPushNamed(
                                      context,
                                      "/forgot",
                                    );
                                  },
                                  child: Text(
                                    "Forgot Password",
                                    style: Theme.of(
                                      context,
                                    ).typography.black.labelMedium!.apply(
                                      color: Theme.of(context).primaryColorDark,
                                      fontWeightDelta: 3,
                                    ),
                                  ),
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                      Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            (error.isNotEmpty)
                                ? Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    10,
                                    20,
                                    10,
                                    0,
                                  ),
                                  child: Text(
                                    error,
                                    style: Theme.of(context)
                                        .typography
                                        .white
                                        .bodyLarge!
                                        .apply(color: Colors.red),
                                  ),
                                )
                                : Container(),
                          ],
                        ),
                        Column(
                          children: [
                            TextButton(
                              onPressed: () async {
                                FocusScope.of(context).unfocus();

                                if (email.isEmpty) {
                                  setState(() {
                                    error = "Email cannot be empty";
                                  });
                                  return;
                                }
                                if (password.isEmpty) {
                                  setState(() {
                                    error = "Password cannot be empty";
                                  });
                                  return;
                                }

                                await login();
                              },
                              child: Text(
                                "LOGIN",
                                style: Theme.of(context)
                                    .typography
                                    .white
                                    .labelMedium!
                                    .apply(fontWeightDelta: 3),
                              ),
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                  Theme.of(context).primaryColorLight,
                                ),
                                foregroundColor: WidgetStatePropertyAll(
                                  Colors.white,
                                ),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                fixedSize: WidgetStatePropertyAll(
                                  Size(
                                    MediaQuery.of(context).size.width * 0.75,
                                    50,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account yet?",
                                    style: Theme.of(
                                      context,
                                    ).typography.black.bodyLarge!.apply(
                                      color: Theme.of(context).primaryColorDark,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                      ).popAndPushNamed("/signup");
                                    },
                                    child: Text(
                                      "Sign Up",
                                      style: Theme.of(
                                        context,
                                      ).typography.black.bodyLarge!.apply(
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        fontWeightDelta: 3,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
