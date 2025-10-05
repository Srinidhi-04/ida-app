import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:src/services/auth_service.dart';
import 'package:src/services/notifications_manager.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/widgets/navigation.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late int user_id;
  late String role;

  List<String> admin_roles = ["admin", "merch"];
  bool admin_access = false;

  bool loaded = false;
  bool torch = false;

  Map qr_data = {};

  MobileScannerController controller = MobileScannerController(
    detectionTimeoutMs: 1000,
  );

  Future<void> getPermissions() async {
    Map info = await AuthService.getPermissions(
      params: {"category": "shop", "user_id": user_id.toString()},
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

    await SecureStorage.writeOne("role", info["data"]["role"]);

    setState(() {
      admin_roles = info["data"]["roles"].cast<String>();
      admin_access = info["data"]["access"];
      role = info["data"]["role"];
      loaded = true;
    });

    if (!admin_roles.contains(role) && !admin_access) {
      Navigator.of(context).pop();
    }
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
      role = info["role"]!;
    });
    await getPermissions();
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
    Rect scan_window = Rect.fromCenter(
      center: Offset(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2 - 100,
      ),
      width: MediaQuery.of(context).size.width * 0.7,
      height: MediaQuery.of(context).size.width * 0.7,
    );

    if (!loaded)
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.inkDrop(
            color: Theme.of(context).primaryColorLight,
            size: 100,
          ),
        ),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Scan Order",
          style: Theme.of(context).typography.black.headlineMedium!.apply(
            color: Theme.of(context).primaryColorDark,
          ),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (result) {
              try {
                Map data = jsonDecode(result.barcodes.first.rawValue!) as Map;
                if (data == qr_data) {
                  return;
                }

                setState(() {
                  qr_data = data;
                });

                if ((DateTime.now().millisecondsSinceEpoch -
                        qr_data["timestamp"]) >=
                    600000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "QR code has expired",
                        style: Theme.of(context).typography.white.bodyMedium!
                            .apply(color: Theme.of(context).primaryColorLight),
                      ),
                      backgroundColor: Theme.of(context).primaryColorDark,
                      showCloseIcon: true,
                      closeIconColor: Theme.of(context).primaryColorLight,
                    ),
                  );
                  return;
                }

                controller.stop();

                Navigator.of(context)
                    .pushNamed(
                      "/order",
                      arguments: {
                        "user_id": qr_data["user_id"],
                        "order_id": qr_data["order_id"],
                      },
                    )
                    .then((_) {
                      controller.start();
                    });
              } catch (e) {}
            },
            scanWindow: scan_window,
          ),
          IgnorePointer(
            child: ScanWindowOverlay(
              borderStrokeCap: StrokeCap.round,
              borderStrokeJoin: StrokeJoin.round,
              borderRadius: BorderRadius.circular(20),
              controller: controller,
              scanWindow: scan_window,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      controller.toggleTorch();
                      setState(() {
                        torch = !torch;
                      });
                    },
                    icon:
                        (torch)
                            ? Icon(Icons.flash_on_outlined)
                            : Icon(Icons.flash_off_outlined),
                    color: Theme.of(context).primaryColorLight,
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Theme.of(context).primaryColorDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.switchCamera();
                    },
                    icon: Icon(Icons.flip_camera_ios_outlined),
                    color: Theme.of(context).primaryColorLight,
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Theme.of(context).primaryColorDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Navigation(selected: 4),
    );
  }
}
