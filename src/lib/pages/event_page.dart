// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/widgets/navigation.dart';

class EventPage extends StatefulWidget {
  EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  late bool admin;
  bool loaded = false;

  List<String> months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  bool action_pressed = false;

  String baseUrl = "https://0112-223-185-130-192.ngrok-free.app/ida-app";

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
      admin = bool.parse(info["admin"]!);
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

    Map args = ModalRoute.of(context)!.settings.arguments as Map;
    int event_id = args["event_id"];
    String image = args["image"];
    DateTime date = args["date"];
    String location = args["location"];
    String title = args["title"];
    String body = args["body"];
    Function callback = args["callback"];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Event Details",
          style: Theme.of(context).typography.white.headlineMedium!,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions:
            (admin)
                ? [
                  (action_pressed)
                      ? TapRegion(
                        onTapOutside:
                            (event) => setState(() {
                              action_pressed = false;
                            }),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: TextButton.icon(
                            onPressed: () async {
                              await post(
                                Uri.parse(baseUrl + "/delete-event/"),
                                body: {"event_id": event_id.toString()},
                              );
                              callback();
                              Navigator.pop(context);
                            },
                            label: Text(
                              "Delete",
                              style:
                                  Theme.of(
                                    context,
                                  ).typography.white.labelMedium,
                            ),
                            icon: Icon(Icons.delete_outline),
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                Theme.of(context).primaryColorLight,
                              ),
                              foregroundColor: WidgetStatePropertyAll(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                      : IconButton(
                        onPressed: () {
                          setState(() {
                            action_pressed = true;
                          });
                        },
                        icon: Icon(Icons.more_vert),
                      ),
                ]
                : [],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        color: Theme.of(context).primaryColorLight,
        backgroundColor: Colors.white,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      kBottomNavigationBarHeight,
                  minWidth: MediaQuery.of(context).size.width,
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          height: 0.3 * MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                          color: Theme.of(context).primaryColorDark,
                          child: Image(
                            image: NetworkImage(image),
                            fit: BoxFit.contain,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.3,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 5,
                                          ),
                                          child: Icon(
                                            Icons.event_available_outlined,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "${date.day} ${months[date.month - 1]}, ${date.year}",
                                          style: Theme.of(context)
                                              .typography
                                              .white
                                              .labelMedium!
                                              .apply(fontWeightDelta: 3),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 5,
                                          ),
                                          child: Icon(
                                            Icons.alarm_outlined,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "${(date.hour % 12 < 10 && date.hour % 12 > 0) ? "0" : ""}${(date.hour % 12 == 0) ? "12" : date.hour % 12}:${(date.minute < 10 ? "0" : "")}${date.minute} ${(date.hour < 12) ? "AM" : "PM"}",
                                          style: Theme.of(context)
                                              .typography
                                              .white
                                              .labelMedium!
                                              .apply(fontWeightDelta: 3),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: Icon(
                                      Icons.location_on_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    "${location}",
                                    style: Theme.of(context)
                                        .typography
                                        .white
                                        .labelMedium!
                                        .apply(fontWeightDelta: 3),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context)
                                  .typography
                                  .black
                                  .headlineLarge!
                                  .apply(fontWeightDelta: 3),
                            ),
                            SizedBox(height: 30),
                            Text(
                              "About the event",
                              style: Theme.of(context)
                                  .typography
                                  .black
                                  .labelLarge!
                                  .apply(fontWeightDelta: 3),
                            ),
                            SizedBox(height: 20),
                            Text(
                              body,
                              style:
                                  Theme.of(context).typography.black.bodyLarge,
                            ),
                            SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextButton(
                onPressed: () {},
                child: Text(
                  "RSVP",
                  style: Theme.of(context).typography.white.labelLarge!.apply(
                    fontSizeDelta: 2,
                    fontWeightDelta: 3,
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    Theme.of(context).primaryColorLight,
                  ),
                  fixedSize: WidgetStatePropertyAll(
                    Size(0.6 * MediaQuery.of(context).size.width, 50),
                  ),
                  elevation: WidgetStatePropertyAll(10),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Navigation(selected: 1),
    );
  }
}
