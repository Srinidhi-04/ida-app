import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
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

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});

  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  String email = "";
  String password = "";
  String code = "";
  String error = "";
  String top_text = "";
  bool submitted = false;
  bool sent = false;

  bool obscure = true;

  TextEditingController emailController = TextEditingController();

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  Future<void> sendCode() async {
    setState(() {
      submitted = true;
    });
    var response = await post(
      Uri.parse(baseUrl + "/send-code"),
      body: {"email": email, "forgot": "yes"},
    );
    Map info = jsonDecode(response.body);
    setState(() {
      submitted = false;
    });
    if (info.containsKey("error")) {
      setState(() {
        sent = false;
        error = info["error"];
      });
      return;
    }
    setState(() {
      error = "";
      sent = true;
      top_text = "We've sent a verification code to ${email}.";
    });
  }

  Future<bool> changePassword() async {
    setState(() {
      submitted = true;
    });
    var response = await post(
      Uri.parse(baseUrl + "/change-password"),
      body: {"email": email, "password": password, "code": code},
    );
    Map info = jsonDecode(response.body);
    if (info.containsKey("error")) {
      setState(() {
        error = info["error"];
        submitted = false;
      });
      return false;
    }
    await SecureStorage.writeMany({
      "user_id": info["user_id"].toString(),
      "last_login": DateTime.now().toString(),
      "email": info["email"].toString(),
      "name": info["name"].toString(),
      "avatar": info["avatar"].toString(),
      "role": info["role"].toString(),
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

    return true;
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
                            (sent)
                                ? Padding(
                                  padding: const EdgeInsets.only(bottom: 25.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.lightGreen,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    width:
                                        MediaQuery.of(context).size.width - 60,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Text(
                                        top_text,
                                        style:
                                            Theme.of(
                                              context,
                                            ).typography.white.bodyMedium,
                                      ),
                                    ),
                                  ),
                                )
                                : SizedBox.shrink(),
                            Text(
                              "Forgot Password",
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
                                keyboardType: TextInputType.emailAddress,
                                controller: emailController,
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
                                      email = value.trim();
                                    }),
                              ),
                            ),
                            (sent)
                                ? Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        30,
                                        10,
                                        30,
                                        10,
                                      ),
                                      child: TextFormField(
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        obscureText: obscure,
                                        decoration: InputDecoration(
                                          prefixIcon: Icon(
                                            (obscure)
                                                ? Icons.lock_outlined
                                                : Icons.lock_open_outlined,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          suffixIcon: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                obscure = !obscure;
                                              });
                                            },
                                            child: Icon(
                                              Icons.visibility_outlined,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
                                            ),
                                          ),
                                          hintText: "New Password",
                                        ),
                                        cursorColor:
                                            Theme.of(context).primaryColor,
                                        onChanged:
                                            (value) => setState(() {
                                              password = value;
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
                                        keyboardType: TextInputType.number,
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        decoration: InputDecoration(
                                          prefixIcon: Icon(
                                            Icons.vpn_key_outlined,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          hintText: "Verification Code",
                                        ),
                                        maxLength: 6,
                                        cursorColor:
                                            Theme.of(context).primaryColor,
                                        onChanged:
                                            (value) => setState(() {
                                              code = value.trim();
                                            }),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Didn't receive the code?",
                                          style: Theme.of(
                                            context,
                                          ).typography.black.bodyLarge!.apply(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).primaryColorDark,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await sendCode();

                                            setState(() {
                                              top_text =
                                                  "Verification code resent to ${email}";
                                            });
                                          },
                                          child: Text(
                                            "Resend",
                                            style: Theme.of(
                                              context,
                                            ).typography.black.bodyLarge!.apply(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColorDark,
                                              fontWeightDelta: 3,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                                : SizedBox.shrink(),
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
                                : SizedBox.shrink(),
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

                                if (!RegExp(
                                  r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
                                ).hasMatch(email)) {
                                  setState(() {
                                    error = "Invalid email format";
                                  });
                                  return;
                                }

                                if (sent) {
                                  if (password.isEmpty) {
                                    setState(() {
                                      error = "Password cannot be empty";
                                    });
                                    return;
                                  }

                                  if (code.isEmpty) {
                                    setState(() {
                                      error = "Password cannot be empty";
                                    });
                                    return;
                                  }

                                  if (code.length != 6) {
                                    setState(() {
                                      error =
                                          "The code needs to be 6 digits long";
                                    });
                                    return;
                                  }

                                  await changePassword();
                                  return;
                                }

                                await sendCode();
                              },
                              child: Text(
                                (sent) ? "CHANGE" : "SEND CODE",
                                style: Theme.of(
                                  context,
                                ).typography.white.labelMedium!.apply(
                                  fontSizeDelta: 2,
                                  fontWeightDelta: 3,
                                ),
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
                                    "Already have an account?",
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
                                      ).popAndPushNamed("/login");
                                    },
                                    child: Text(
                                      "Log In",
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
            : SizedBox.shrink(),
      ],
    );
  }
}
