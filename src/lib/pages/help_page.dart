import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart";
import "package:loading_animation_widget/loading_animation_widget.dart";
import "package:src/services/notifications_manager.dart";
import "package:src/services/secure_storage.dart";
import "package:src/widgets/navigation.dart";

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  late int user_id;
  late String token;

  String query = "";

  bool submitted = false;
  bool sent = false;

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
              "Help",
              style: Theme.of(context).typography.black.headlineMedium!.apply(
                color: Theme.of(context).primaryColorDark,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(color: Theme.of(context).primaryColor),
                  (sent)
                      ? Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.lightGreen,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          width: MediaQuery.of(context).size.width - 60,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              "Your question has been sent successfully. You will receive an email with the response soon.",
                              style:
                                  Theme.of(context).typography.white.bodyMedium,
                            ),
                          ),
                        ),
                      )
                      : Container(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 5),
                    child: TextFormField(
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.description_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        hintText: "Question",
                      ),
                      maxLines: null,
                      cursorColor: Theme.of(context).primaryColor,
                      onChanged:
                          (value) => setState(() {
                            query = value;
                          }),
                    ),
                  ),
                  (query.isNotEmpty)
                      ? Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: TextButton(
                          onPressed: () async {
                            FocusScope.of(context).unfocus();

                            setState(() {
                              submitted = true;
                            });

                            var response = await post(
                              Uri.parse(baseUrl + "/send-query"),
                              headers: {"Authorization": "Bearer ${token}"},
                              body: {
                                "user_id": user_id.toString(),
                                "query": query,
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

                            setState(() {
                              submitted = false;
                              sent = true;
                              query = "";
                            });
                          },
                          child: Text(
                            "Send",
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
                              Size(0.6 * MediaQuery.of(context).size.width, 50),
                            ),
                            elevation: WidgetStatePropertyAll(10),
                          ),
                        ),
                      )
                      : Container(),
                ],
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
