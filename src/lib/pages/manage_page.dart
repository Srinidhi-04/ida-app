import "package:flutter/material.dart";
import "package:http/http.dart";
import "package:loading_animation_widget/loading_animation_widget.dart";
import "package:src/services/secure_storage.dart";

class ManagePage extends StatefulWidget {
  const ManagePage({super.key});

  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  late int user_id;
  late String token;

  int? event_id;

  String name = "";
  DateTime? event_date;
  TimeOfDay? event_time;
  String location = "";
  List<double?> latlng = [null, null];
  String image = "";
  String body = "";
  bool featured = false;
  List<String?> errors = [null, null, null, null, null, null, null];
  bool initialized = false;
  late Function callback;

  bool submitted = false;

  TextEditingController name_controller = TextEditingController();
  TextEditingController location_controller = TextEditingController();
  TextEditingController lat_controller = TextEditingController();
  TextEditingController long_controller = TextEditingController();
  TextEditingController image_controller = TextEditingController();
  TextEditingController body_controller = TextEditingController();

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!initialized) {
      Map args = ModalRoute.of(context)!.settings.arguments as Map;

      if (args.containsKey("event_id")) {
        setState(() {
          event_id = args["event_id"];

          name = args["name"];
          name_controller.text = name;

          DateTime date = args["date"];

          event_date = date;
          event_time = TimeOfDay(hour: date.hour, minute: date.minute);

          location = args["location"];
          location_controller.text = location;

          latlng = [args["latitude"], args["longitude"]];
          lat_controller.text = latlng[0].toString();
          long_controller.text = latlng[1].toString();

          image = args["image"];
          image_controller.text = image;

          body = args["body"];
          body_controller.text = body;

          featured = args["featured"];
        });
      }

      setState(() {
        initialized = true;
        callback = args["callback"];
      });
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
          appBar: AppBar(
            title: Text(
              (event_id == null) ? "Create Event" : "Edit Event",
              style: Theme.of(context).typography.black.headlineMedium!.apply(
                color: Theme.of(context).primaryColorDark,
              ),
            ),
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
                        controller: name_controller,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            color: Theme.of(context).primaryColor,
                          ),
                          hintText: "Name",
                          errorText: errors[0],
                        ),
                        cursorColor: Theme.of(context).primaryColor,
                        onChanged:
                            (value) => setState(() {
                              name = value;
                            }),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: TextButton.icon(
                                  onPressed: () {
                                    showDatePicker(
                                      context: context,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        Duration(days: 365),
                                      ),
                                      initialDate: DateTime.now(),
                                    ).then(
                                      (value) => setState(() {
                                        event_date = value;
                                      }),
                                    );
                                  },
                                  label: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      (event_date != null)
                                          ? event_date!
                                              .toIso8601String()
                                              .substring(0, 10)
                                          : "Date",
                                      style: Theme.of(context)
                                          .typography
                                          .white
                                          .labelLarge!
                                          .apply(fontWeightDelta: 3),
                                    ),
                                  ),
                                  icon: Icon(Icons.calendar_month, size: 22),
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
                              ((errors[1] != null)
                                  ? Text(
                                    errors[1]!,
                                    style: Theme.of(context)
                                        .typography
                                        .white
                                        .bodyMedium!
                                        .apply(color: Colors.red),
                                  )
                                  : Container()),
                            ],
                          ),
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: TextButton.icon(
                                  onPressed: () {
                                    showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    ).then(
                                      (value) => setState(() {
                                        event_time = value;
                                      }),
                                    );
                                  },
                                  label: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text(
                                      (event_time != null)
                                          ? event_time!.format(context)
                                          : "Time",
                                      style: Theme.of(context)
                                          .typography
                                          .white
                                          .labelLarge!
                                          .apply(fontWeightDelta: 3),
                                    ),
                                  ),
                                  icon: Icon(Icons.alarm_outlined, size: 22),
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
                              ((errors[2] != null)
                                  ? Text(
                                    errors[2]!,
                                    style: Theme.of(context)
                                        .typography
                                        .white
                                        .bodyMedium!
                                        .apply(color: Colors.red),
                                  )
                                  : Container()),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextFormField(
                        controller: location_controller,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: Theme.of(context).primaryColor,
                          ),
                          hintText: "Location",
                          errorText: errors[3],
                        ),
                        cursorColor: Theme.of(context).primaryColor,
                        onChanged:
                            (value) => setState(() {
                              location = value;
                            }),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: TextFormField(
                                keyboardType: TextInputType.numberWithOptions(
                                  signed: true,
                                  decimal: true,
                                ),
                                controller: lat_controller,
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.grid_3x3_outlined,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  hintText: "Latitude",
                                  errorText: errors[4],
                                ),
                                cursorColor: Theme.of(context).primaryColor,
                                onChanged:
                                    (value) => setState(() {
                                      try {
                                        if (value != "")
                                          latlng[0] = double.parse(value);
                                        else
                                          latlng[0] = null;
                                        errors[4] = null;
                                      } catch (e) {
                                        setState(() {
                                          errors[4] =
                                              "Latitude must be a float";
                                        });
                                      }
                                    }),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: TextFormField(
                                keyboardType: TextInputType.numberWithOptions(
                                  signed: true,
                                  decimal: true,
                                ),
                                controller: long_controller,
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.grid_3x3_outlined,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  hintText: "Longitude",
                                  errorText: errors[5],
                                ),
                                cursorColor: Theme.of(context).primaryColor,
                                onChanged:
                                    (value) => setState(() {
                                      try {
                                        if (value != "")
                                          latlng[1] = double.parse(value);
                                        else
                                          latlng[1] = null;
                                        errors[5] = null;
                                      } catch (e) {
                                        setState(() {
                                          errors[5] =
                                              "Longitude must be a float";
                                        });
                                      }
                                    }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextFormField(
                        controller: image_controller,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.image_outlined,
                            color: Theme.of(context).primaryColor,
                          ),
                          hintText: "Thumbnail",
                        ),
                        cursorColor: Theme.of(context).primaryColor,
                        onChanged:
                            (value) => setState(() {
                              image = value;
                            }),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextFormField(
                        controller: body_controller,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.description_outlined,
                            color: Theme.of(context).primaryColor,
                          ),
                          hintText: "Body",
                          errorText: errors[6],
                        ),
                        maxLines: null,
                        cursorColor: Theme.of(context).primaryColor,
                        onChanged:
                            (value) => setState(() {
                              body = value;
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
                              "Featured",
                              style:
                                  Theme.of(context).typography.black.labelLarge,
                            ),
                          ),
                          Switch(
                            thumbColor: WidgetStatePropertyAll(Colors.white),
                            activeTrackColor: Colors.green,
                            inactiveTrackColor: Theme.of(context).primaryColor,
                            value: featured,
                            onChanged:
                                (value) => setState(() {
                                  featured = value;
                                }),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: TextButton(
                        onPressed: () async {
                          FocusScope.of(context).unfocus();

                          if (name == "")
                            errors[0] = "Name is a required field";
                          else
                            errors[0] = null;

                          if (event_date == null)
                            errors[1] = "Date is a required field";
                          else
                            errors[1] = null;

                          if (event_time == null)
                            errors[2] = "Time is a required field";
                          else
                            errors[2] = null;

                          if (location == "")
                            errors[3] = "Location is a required field";
                          else
                            errors[3] = null;

                          if (latlng[0] == null)
                            errors[4] = "Latitude is a required field";
                          else
                            errors[4] = null;

                          if (latlng[1] == null)
                            errors[5] = "Longitude is a required field";
                          else
                            errors[5] = null;

                          if (body == "")
                            errors[6] = "Body is a required field";
                          else
                            errors[6] = null;

                          if (errors[0] == null &&
                              errors[1] == null &&
                              errors[2] == null &&
                              errors[3] == null &&
                              errors[4] == null &&
                              errors[5] == null &&
                              errors[6] == null) {
                            setState(() {
                              submitted = true;
                            });

                            DateTime final_date = DateTime(
                              event_date!.year,
                              event_date!.month,
                              event_date!.day,
                              event_time!.hour,
                              event_time!.minute,
                            );

                            if (event_id == null) {
                              await post(
                                Uri.parse(baseUrl + "/add-event/"),
                                headers: {"Authorization": "Bearer ${token}"},
                                body: {
                                  "user_id": user_id.toString(),
                                  "name": name,
                                  "date": final_date.toString().split(".")[0],
                                  "timezone":
                                      final_date.timeZoneOffset
                                          .toString()
                                          .split(".")[0],
                                  "location": location,
                                  "latitude": latlng[0].toString(),
                                  "longitude": latlng[1].toString(),
                                  "image": image,
                                  "body": body,
                                  "essential": (featured ? "yes" : "no"),
                                },
                              );
                              Navigator.pop(context);
                              callback();
                            } else {
                              await post(
                                Uri.parse(baseUrl + "/edit-event/"),
                                headers: {"Authorization": "Bearer ${token}"},
                                body: {
                                  "user_id": user_id.toString(),
                                  "event_id": event_id.toString(),
                                  "name": name,
                                  "date": final_date.toString().split(".")[0],
                                  "timezone":
                                      final_date.timeZoneOffset
                                          .toString()
                                          .split(".")[0],
                                  "location": location,
                                  "latitude": latlng[0].toString(),
                                  "longitude": latlng[1].toString(),
                                  "image": image,
                                  "body": body,
                                  "essential": (featured ? "yes" : "no"),
                                },
                              );
                              Navigator.pop(context);
                              callback(
                                name,
                                final_date,
                                location,
                                latlng[0],
                                latlng[1],
                                (image != "")
                                    ? image
                                    : "https://i.imgur.com/Mw85Kfp.png",
                                body,
                                featured,
                              );
                            }
                          }

                          setState(() {
                            errors = errors;
                            submitted = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            (event_id == null) ? "Create" : "Save",
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
