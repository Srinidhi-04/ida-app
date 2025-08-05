import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:src/services/notifications_manager.dart';
import "package:src/services/secure_storage.dart";

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

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final app_version = 8.0;
  bool update = false;

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  Future<void> checkUpdate() async {
    var response = await get(
      Uri.parse(baseUrl + "/check-update?version=${app_version}"),
    );
    Map info = jsonDecode(response.body);
    if (info["message"] == "Hard update") {
      setState(() {
        update = true;
      });
      return;
    }
    checkLogin();
  }

  Future<void> checkLogin() async {
    Map<String, String> info = {};
    try {
      info = await SecureStorage.read();
    } catch (e) {
      await SecureStorage.delete();
    }
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
    if (info["user_id"] != null && info["reminders"] != null)
      await Navigator.popAndPushNamed(context, "/home");
    else
      await Navigator.popAndPushNamed(context, "/login");
  }

  @override
  void initState() {
    super.initState();
    checkUpdate();
  }

  @override
  Widget build(BuildContext context) {
    if (update) {
      return Material(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Text(
                "Please update the app to the latest version to continue",
                style: Theme.of(context).typography.black.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
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
            Container(
              color: Color(0x77FFFFFF),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Center(
                child: Image(
                  width: MediaQuery.of(context).size.width * 0.8,
                  image: AssetImage("assets/logo.png"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
