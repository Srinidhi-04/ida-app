import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/notifications_manager.dart';
import 'package:src/services/secure_storage.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  late int user_id;
  late String token;

  bool submitted = false;
  String title = "";
  String body = "";
  bool everyone = false;

  List<String?> errors = [null, null];

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

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
          appBar: AppBar(
            title: Text(
              "Send Announcement",
              style: Theme.of(context).typography.black.headlineMedium!.apply(
                color: Theme.of(context).primaryColorDark,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                      child: TextFormField(
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.drive_file_rename_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                          hintText: "Title",
                          errorText: errors[0],
                        ),
                        cursorColor: Theme.of(context).primaryColor,
                        onChanged:
                            (value) => setState(() {
                              title = value.trim();
                            }),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextFormField(
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.description_outlined,
                            color: Theme.of(context).primaryColor,
                          ),
                          hintText: "Body",
                          errorText: errors[1],
                        ),
                        maxLines: null,
                        cursorColor: Theme.of(context).primaryColor,
                        onChanged:
                            (value) => setState(() {
                              body = value.trim();
                            }),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 20.0),
                            child: Text(
                              "Send to everyone?",
                              style:
                                  Theme.of(context).typography.black.labelLarge,
                            ),
                          ),
                          Switch(
                            thumbColor: WidgetStatePropertyAll(Colors.white),
                            activeTrackColor: Colors.green,
                            inactiveTrackColor: Theme.of(context).primaryColor,
                            value: everyone,
                            onChanged:
                                (value) => setState(() {
                                  everyone = value;
                                }),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: TextButton(
                        onPressed: () async {
                          FocusScope.of(context).unfocus();

                          if (title == "")
                            errors[0] = "Title is a required field";
                          else
                            errors[0] = null;

                          if (body == "")
                            errors[1] = "Body is a required field";
                          else
                            errors[1] = null;

                          if (errors[0] == null && errors[1] == null) {
                            setState(() {
                              submitted = true;
                            });

                            var response = await post(
                              Uri.parse(baseUrl + "/send-announcement/"),
                              headers: {"Authorization": "Bearer ${token}"},
                              body: {
                                "user_id": user_id.toString(),
                                "title": title,
                                "body": body,
                                "everyone": (everyone) ? "yes" : "no",
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

                            Navigator.pop(context);
                          }

                          setState(() {
                            errors = errors;
                            submitted = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            "Send",
                            style: Theme.of(context)
                                .typography
                                .white
                                .labelLarge!
                                .apply(fontWeightDelta: 3),
                          ),
                        ),
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            Theme.of(context).primaryColorLight,
                          ),
                          foregroundColor: WidgetStatePropertyAll(Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
