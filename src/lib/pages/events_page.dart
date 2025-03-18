import 'package:flutter/material.dart';
import 'package:src/widgets/navigation.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  int selected = 0;
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
    "Dec"
  ];
  List<String> days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  Widget SwitchOption(int index, String text) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: TextButton(
        onPressed: () {
          setState(() {
            selected = index;
          });
        },
        child: Text(
          text,
          style: Theme.of(context).typography.black.labelLarge!.apply(
              color: (selected == index)
                  ? Theme.of(context).primaryColorLight
                  : Color(0xFF707372)),
        ),
        style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(
                (selected == index) ? Colors.white : Colors.transparent),
            foregroundColor: WidgetStatePropertyAll((selected == index)
                ? Theme.of(context).primaryColorLight
                : Color(0xFF707372)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            overlayColor: WidgetStatePropertyAll(Colors.transparent)),
      ),
    );
  }

  Widget EventCard(String name, String location, DateTime date, String image) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 170,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 20, 10),
        child: Card(
          elevation: 5,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: TextButton(
            onPressed: () {},
            style: ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.zero), tapTargetSize: MaterialTapTargetSize.shrinkWrap, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image(
                    width: MediaQuery.of(context).size.width / 5,
                    height: 170,
                    image: NetworkImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Container(
                    width: 0.6 * MediaQuery.of(context).size.width,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${days[date.weekday]}, ${months[date.month]} ${date.day} • ${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute} ${(date.hour >= 12) ? "PM" : "AM"}",
                            style: Theme.of(context)
                                .typography
                                .white
                                .bodyMedium!
                                .apply(
                                  color: Theme.of(context).primaryColorLight,
                                ),
                          ),
                          Text(
                            name,
                            style: Theme.of(context)
                                .typography
                                .black
                                .headlineSmall!
                                .apply(
                                    color: Theme.of(context).primaryColorDark,
                                    fontSizeDelta: -4),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  Container(
                                    constraints: BoxConstraints(
                                        maxWidth: 0.3 *
                                            MediaQuery.of(context).size.width),
                                    child: Text(
                                      location,
                                      style: Theme.of(context)
                                          .typography
                                          .black
                                          .bodyMedium!
                                          .apply(
                                              color:
                                                  Theme.of(context).primaryColor),
                                    ),
                                  )
                                ],
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  "View on map",
                                  style: Theme.of(context)
                                      .typography
                                      .white
                                      .bodyMedium,
                                ),
                                style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                        Theme.of(context).primaryColorDark),
                                    shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)))),
                              )
                            ],
                          )
                        ]),
                  ),
                )
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Events",
              style: Theme.of(context)
                  .typography
                  .black
                  .headlineMedium!
                  .apply(color: Theme.of(context).primaryColorDark)),
          actions: [IconButton(onPressed: () {}, icon: Icon(Icons.more_vert))],
        ),
        body: RefreshIndicator(
            onRefresh: () async {},
            color: Theme.of(context).primaryColorLight,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        kBottomNavigationBarHeight,
                    minWidth: MediaQuery.of(context).size.width),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Color(0xFFC8C6C7),
                            borderRadius: BorderRadius.circular(30)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SwitchOption(0, "UPCOMING"),
                            SwitchOption(1, "PAST EVENTS")
                          ],
                        ),
                      ),
                    ),
                    EventCard("Keep Calm and Ask A Dad", "CIF Room 3025",
                        DateTime.now(), "https://i.imgur.com/UGnaS5X.jpeg"),
                    EventCard("UIUC vs Purdue Basketball", "State Farm Center",
                        DateTime.now(), "https://i.imgur.com/UGnaS5X.jpeg"),
                  ],
                ),
              ),
            )
          ),
          bottomNavigationBar: Navigation(selected: 1),
        );
  }
}
