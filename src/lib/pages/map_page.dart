import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late int user_id;
  late String token;

  bool initialized = false;

  LatLng? center;
  LatLng? myLoc;
  Set<Marker> markers = {};

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
  List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  List<Map> events = [];
  TextEditingController autocompleteController = TextEditingController();
  GoogleMapController? mapController;
  String? mapKey;

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  Widget eventCard(
    String name,
    String location,
    DateTime date,
    String image,
    LatLng coordinates,
  ) {
    return Container(
      width: 0.8 * MediaQuery.of(context).size.width,
      height: 200,
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Card(
          elevation: 5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextButton(
            onPressed: () {
              CameraUpdate cameraUpdate = CameraUpdate.newLatLngZoom(
                coordinates,
                14,
              );

              setState(() {
                center = coordinates;
                markers = {
                  Marker(markerId: MarkerId("My location"), position: myLoc!),
                  Marker(
                    markerId: MarkerId("Event location"),
                    position: coordinates,
                  ),
                };
                mapController!.animateCamera(cameraUpdate);
              });
            },
            style: ButtonStyle(
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image(
                      width: MediaQuery.of(context).size.width * 0.2,
                      height: 200,
                      image: NetworkImage(image),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      width: 0.4 * MediaQuery.of(context).size.width,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${days[date.weekday - 1]}, ${months[date.month - 1]} ${(date.day < 10) ? 0 : ""}${date.day} • ${(date.hour % 12 < 10 && date.hour % 12 != 0) ? 0 : ""}${(date.hour % 12 == 0) ? 12 : date.hour % 12}:${(date.minute < 10) ? 0 : ""}${date.minute} ${(date.hour >= 12) ? "PM" : "AM"}",
                            style: Theme.of(
                              context,
                            ).typography.white.labelSmall!.apply(
                              color: Theme.of(context).primaryColorLight,
                            ),
                          ),
                          Text(
                            name,
                            style: Theme.of(
                              context,
                            ).typography.black.labelMedium!.apply(
                              color: Theme.of(context).primaryColorDark,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          0.3 *
                                          MediaQuery.of(context).size.width,
                                    ),
                                    child: Text(
                                      location,
                                      style: Theme.of(
                                        context,
                                      ).typography.black.labelSmall!.apply(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }

  Widget generateAutocomplete(String text) {
    if (text == "") return Container();

    return Container(
      color: Colors.white,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:
              events
                  .where((e) => e["name"].toLowerCase().contains(text))
                  .map(
                    (e) => TextButton(
                      onPressed: () {
                        CameraUpdate cameraUpdate = CameraUpdate.newLatLngZoom(
                          e["coordinates"],
                          14,
                        );

                        setState(() {
                          center = e["coordinates"];
                          markers = {
                            Marker(
                              markerId: MarkerId("My location"),
                              position: myLoc!,
                            ),
                            Marker(
                              markerId: MarkerId("Event location"),
                              position: e["coordinates"],
                            ),
                          };
                          autocompleteController.text = "";
                          mapController!.animateCamera(cameraUpdate);
                        });
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          e["name"],
                          style: Theme.of(context).typography.black.labelMedium,
                        ),
                      ),
                      style: ButtonStyle(
                        shape: WidgetStatePropertyAll(
                          LinearBorder.top(side: BorderSide()),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  void getPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position? posit;
    try {
      posit = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(timeLimit: Duration(seconds: 10)),
      );
    } catch (e) {
      print("Couldn't get location: ${e}");
      posit = await Geolocator.getLastKnownPosition();
    }

    setState(() {
      myLoc =
          (posit != null)
              ? LatLng(posit.latitude, posit.longitude)
              : LatLng(40.105833, -88.227222);
      if (center == null) center = myLoc;
      markers.add(Marker(markerId: MarkerId("My location"), position: myLoc!));
    });
  }

  Future<void> getEvents() async {
    var response = await get(
      Uri.parse(baseUrl + "/get-events?completed=no&user_id=${user_id}"),
      headers: {"Authorization": "Bearer ${token}"},
    );
    Map info = jsonDecode(response.body);
    if (info.containsKey("error") &&
        info["error"] == "Invalid authorization token") {
      await SecureStorage.delete();
      await Navigator.of(
        context,
      ).pushNamedAndRemoveUntil("/login", (route) => false);
      return;
    }

    List all_events = info["data"];

    List<Map> new_events = [];
    for (var event in all_events) {
      new_events.add({
        "date": DateTime.parse(event["date"]).toLocal(),
        "name": event["name"],
        "location": event["location"],
        "image": event["image"],
        "coordinates": LatLng(event["latitude"], event["longitude"]),
      });
    }

    setState(() {
      events = new_events;
    });
  }

  Widget mapsButton(String name, String link) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: TextButton.icon(
        onPressed: () async {
          await launchUrl(
            Uri.parse(link),
            mode: LaunchMode.externalApplication,
          );
        },
        label: Text(
          name,
          style: Theme.of(context).typography.white.labelMedium!.apply(
            color: Theme.of(context).primaryColorLight,
          ),
        ),
        icon: Icon(Icons.location_on_outlined),
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            Theme.of(context).primaryColorDark,
          ),
          foregroundColor: WidgetStatePropertyAll(
            Theme.of(context).primaryColorLight,
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
    });
    await getEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!initialized) {
      Map args = {};
      if (ModalRoute.of(context)!.settings.arguments != null) {
        args = ModalRoute.of(context)!.settings.arguments as Map;
      }

      if (args.isNotEmpty) {
        setState(() {
          markers.add(
            Marker(
              markerId: MarkerId("Event location"),
              position: args["coordinates"],
            ),
          );
          center = args["coordinates"];
        });
      }

      setState(() {
        initialized = true;
        mapKey = "map-${DateTime.now().millisecondsSinceEpoch}";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    checkLogin();
    getPosition();
  }

  @override
  Widget build(BuildContext context) {
    if (center == null || myLoc == null)
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.inkDrop(
            color: Theme.of(context).primaryColorLight,
            size: 100,
          ),
        ),
      );

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          GoogleMap(
            key: ValueKey(mapKey),
            onMapCreated: (controller) {
              setState(() {
                mapController = controller;
              });
            },
            initialCameraPosition: CameraPosition(target: center!, zoom: 14),
            markers: markers,
            zoomControlsEnabled: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: Colors.white,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.keyboard_arrow_left),
                          color: Colors.black,
                        ),
                      ),
                      Expanded(
                        child: Card(
                          color: Colors.white,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: TextFormField(
                                  controller: autocompleteController,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: "Search for events",
                                    hintStyle: Theme.of(context)
                                        .typography
                                        .black
                                        .labelLarge!
                                        .apply(color: Color(0xFF9C9A9D)),
                                  ),
                                  cursorColor: Theme.of(context).primaryColor,
                                  onChanged: (value) => setState(() {}),
                                ),
                              ),
                              generateAutocomplete(
                                autocompleteController.text.toLowerCase(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  (markers.length == 2)
                      ? Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: mapsButton(
                                  "Open in Google Maps",
                                  "https://www.google.com/maps/dir/?api=1&origin=${myLoc!.latitude},${myLoc!.longitude}&destination=${center!.latitude},${center!.longitude}",
                                ),
                              ),
                              (Platform.isIOS)
                                  ? Align(
                                    alignment: Alignment.centerRight,
                                    child: mapsButton(
                                      "Open in Apple Maps",
                                      "http://maps.apple.com/?saddr=${myLoc!.latitude},${myLoc!.longitude}&daddr=${center!.latitude},${center!.longitude}",
                                    ),
                                  )
                                  : Container(),
                            ],
                          ),
                        ),
                      )
                      : Container(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Row(
            children:
                events
                    .map(
                      (e) => eventCard(
                        e["name"],
                        e["location"],
                        e["date"],
                        e["image"],
                        e["coordinates"],
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }
}
