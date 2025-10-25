import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:src/services/misc_service.dart';
import 'package:src/services/notifications_manager.dart';
import "package:src/services/secure_storage.dart";
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final app_version = 15.2;
  bool update = false;

  Future<void> checkUpdate() async {
    Map info = await MiscService.checkUpdate(
      params: {"version": app_version.toString()},
    );

    if (info["message"] == "Hard update") {
      setState(() {
        update = true;
      });
    }

    if (info["message"] != "Updated") {
      if (Platform.isIOS) {
        showCupertinoDialog(
          context: context,
          builder:
              (BuildContext dialogContext) => CupertinoTheme(
                data: CupertinoThemeData(),
                child: CupertinoAlertDialog(
                  title: Text("Update Available"),
                  content: Text(
                    "A new version is available. Please update to continue.",
                  ),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text("Ignore"),
                    ),
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text("Update"),
                    ),
                  ],
                ),
              ),
        ).then((value) {
          if (value != null && value) {
            launchUrl(
              Uri.parse(
                "https://apps.apple.com/us/app/illini-dads/id6749455509",
              ),
              mode: LaunchMode.externalNonBrowserApplication,
            );
            return;
          }
          if (info["message"] != "Hard update") {
            checkLogin();
          }
        });
      } else {
        showDialog(
          context: context,
          builder:
              (BuildContext dialogContext) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                actionsAlignment: MainAxisAlignment.end,
                title: Text(
                  "Update Available",
                  style: Theme.of(context).typography.black.headlineMedium,
                ),
                content: Text(
                  "A new version is available. Please update to continue.",
                  style: Theme.of(
                    context,
                  ).typography.black.bodyMedium!.apply(fontSizeDelta: 2),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    child: Text(
                      "Ignore",
                      style: Theme.of(
                        context,
                      ).typography.black.labelMedium!.apply(fontSizeDelta: 2),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    child: Text(
                      "Update",
                      style: Theme.of(context).typography.black.labelMedium!
                          .apply(fontSizeDelta: 2, fontWeightDelta: 3),
                    ),
                  ),
                ],
              ),
        ).then((value) {
          if (value != null && value) {
            launchUrl(
              Uri.parse(
                "https://play.google.com/store/apps/details?id=com.ida.src",
              ),
              mode: LaunchMode.externalNonBrowserApplication,
            );
            return;
          }
          if (info["message"] != "Hard update") {
            checkLogin();
          }
        });
      }
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
    if (info["user_id"] != null && info["reminders"] != null) {
      MiscService.refreshToken();
      FirebaseMessaging.instance.onTokenRefresh.listen((_) {
        MiscService.refreshToken();
      });
      await Navigator.popAndPushNamed(context, "/home");
    } else {
      await Navigator.popAndPushNamed(context, "/login");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkUpdate();
    });
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
