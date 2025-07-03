import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  late int user_id;
  late String email;
  String code = "";
  String error = "";
  String top_text = "";
  bool submitted = false;

  String baseUrl = "https://0112-223-185-130-192.ngrok-free.app/ida-app";

  Future<bool> verify() async {
    setState(() {
      submitted = true;
    });
    var response = await post(
      Uri.parse(baseUrl + "/verify-code/"),
      body: {"user_id": user_id.toString(), "code": code},
    );
    Map info = jsonDecode(response.body);
    setState(() {
      submitted = false;
    });
    if (info.containsKey("error")) {
      setState(() {
        error = info["error"];
      });
      return false;
    }
    await SecureStorage.writeMany({
      "user_id": info["user_id"].toString(),
      "last_login": DateTime.now().toString(),
      "email": info["email"].toString(),
      "name": info["name"].toString(),
      "admin": info["admin"].toString(),
      "reminders": info["reminders"].toString(),
    });
    Navigator.popAndPushNamed(context, "/home");
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
    if (info["user_id"] == null) {
      await Navigator.popAndPushNamed(context, "/login");
      return;
    }
    setState(() {
      user_id = int.parse(info["user_id"]!);
      email = info["email"]!;
      top_text = "We've sent a verification code to ${email}.";
    });
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
                          image: NetworkImage(
                            "https://i.imgur.com/0FHQKN4.png",
                          ),
                          width: MediaQuery.of(context).size.width * 0.6,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 25.0),
                              child: Container(
                                color: Colors.lightGreen,
                                width: MediaQuery.of(context).size.width - 60,
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
                            ),
                            Text(
                              "Verify Code",
                              style: Theme.of(
                                context,
                              ).typography.black.headlineLarge!.apply(
                                color: Theme.of(context).primaryColorDark,
                                fontWeightDelta: 7,
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
                                keyboardType: TextInputType.number,
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.vpn_key_outlined,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  hintText: "Verification Code",
                                ),
                                maxLength: 6,
                                cursorColor: Theme.of(context).primaryColor,
                                onChanged:
                                    (value) => setState(() {
                                      code = value;
                                    }),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Didn't receive the code?",
                                  style: Theme.of(
                                    context,
                                  ).typography.black.bodyLarge!.apply(
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await post(
                                      Uri.parse(baseUrl + "/send-code/"),
                                      body: {"email": email},
                                    );
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
                                      color: Theme.of(context).primaryColorDark,
                                      fontWeightDelta: 7,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
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
                                if (code.length != 6) {
                                  setState(() {
                                    error =
                                        "The code needs to be 6 digits long";
                                  });
                                  return;
                                }

                                await verify();
                              },
                              child: Text(
                                "VERIFY",
                                style: Theme.of(context)
                                    .typography
                                    .white
                                    .labelMedium!
                                    .apply(fontWeightDelta: 7),
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
