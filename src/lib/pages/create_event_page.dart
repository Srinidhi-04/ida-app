import "package:flutter/material.dart";
import "package:http/http.dart";

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  Color grey = Color(0xFF9C9A9D);
  String name = "";
  DateTime? event_date;
  TimeOfDay? event_time;
  String location = "";
  List<double?> latlng = [null, null];
  String image = "";
  String body = "";
  bool featured = false;
  List<String?> errors = [null, null, null, null, null, null, null];

  String baseUrl = "https://0112-223-185-130-192.ngrok-free.app/ida-app";

  @override
  Widget build(BuildContext context) {
    Map args = ModalRoute.of(context)!.settings.arguments as Map;
    Function callback = args["callback"];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create Event",
          style: Theme.of(context).typography.black.headlineMedium!.apply(
            color: Theme.of(context).primaryColorDark,
          ),
        ),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.more_vert))],
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
                      prefixIcon: Icon(Icons.badge_outlined, color: grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(color: grey, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(color: grey, width: 2),
                      ),
                      hintText: "Name",
                      hintStyle: Theme.of(
                        context,
                      ).typography.black.labelLarge!.apply(color: grey),
                      errorStyle: Theme.of(
                        context,
                      ).typography.white.bodyMedium!.apply(color: Colors.red),
                      errorText: errors[0],
                    ),
                    cursorColor: grey,
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
                                      ? event_date!.toIso8601String().substring(
                                        0,
                                        10,
                                      )
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
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.location_on_outlined, color: grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(color: grey, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(color: grey, width: 2),
                      ),
                      hintText: "Location",
                      hintStyle: Theme.of(
                        context,
                      ).typography.black.labelLarge!.apply(color: grey),
                      errorStyle: Theme.of(
                        context,
                      ).typography.white.bodyMedium!.apply(color: Colors.red),
                      errorText: errors[3],
                    ),
                    cursorColor: grey,
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
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.grid_3x3_outlined,
                                color: grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: BorderSide(color: grey, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: BorderSide(color: grey, width: 2),
                              ),
                              hintText: "Latitude",
                              hintStyle: Theme.of(
                                context,
                              ).typography.black.labelLarge!.apply(color: grey),
                              errorStyle: Theme.of(context)
                                  .typography
                                  .white
                                  .bodyMedium!
                                  .apply(color: Colors.red),
                              errorText: errors[4],
                            ),
                            cursorColor: grey,
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
                                      errors[4] = "Latitude must be a float";
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
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.grid_3x3_outlined,
                                color: grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: BorderSide(color: grey, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: BorderSide(color: grey, width: 2),
                              ),
                              hintText: "Longitude",
                              hintStyle: Theme.of(
                                context,
                              ).typography.black.labelLarge!.apply(color: grey),
                              errorStyle: Theme.of(context)
                                  .typography
                                  .white
                                  .bodyMedium!
                                  .apply(color: Colors.red),
                              errorText: errors[5],
                            ),
                            cursorColor: grey,
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
                                      errors[5] = "Longitude must be a float";
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
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.image_outlined, color: grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(color: grey, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(color: grey, width: 2),
                      ),
                      hintText: "Thumbnail",
                      hintStyle: Theme.of(
                        context,
                      ).typography.black.labelLarge!.apply(color: grey),
                    ),
                    cursorColor: grey,
                    onChanged:
                        (value) => setState(() {
                          image = value;
                        }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextFormField(
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.description_outlined, color: grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(color: grey, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(color: grey, width: 2),
                      ),
                      hintText: "Body",
                      hintStyle: Theme.of(
                        context,
                      ).typography.black.labelLarge!.apply(color: grey),
                      errorStyle: Theme.of(
                        context,
                      ).typography.white.bodyMedium!.apply(color: Colors.red),
                      errorText: errors[6],
                    ),
                    maxLines: null,
                    cursorColor: grey,
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
                          style: Theme.of(context).typography.black.labelLarge,
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
                Align(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: TextButton(
                      onPressed: () async {
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
                          DateTime final_date = DateTime(
                            event_date!.year,
                            event_date!.month,
                            event_date!.day,
                            event_time!.hour,
                            event_time!.minute,
                          );
                          await post(
                            Uri.parse(baseUrl + "/add-event/"),
                            body: {
                              "name": name,
                              "date": final_date.toString().split(".")[0],
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
                        }

                        setState(() {
                          errors = errors;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text(
                          "Create",
                          style: Theme.of(context).typography.white.labelLarge!
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
