import 'package:flutter/material.dart';
import 'package:src/widgets/navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> months = [
    "JAN",
    "FEB",
    "MAR",
    "APR",
    "MAY",
    "JUN",
    "JUL",
    "AUG",
    "SEP",
    "OCT",
    "NOV",
    "DEC"
  ];

  List<Map> events = [{"date": DateTime.now(), "title": "Keep Calm and Ask A Dad", "location": "CIF Room 3025"}, {"date": DateTime.now(), "title": "UIUC vs Purdue Basketball", "location": "State Farm Center"}];

  Widget MainButton(Color color, String text, String route) {
    return TextButton(
      onPressed: () {},
      child: Text(text, style: Theme.of(context).typography.white.labelMedium),
      style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(color),
          foregroundColor: WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
          minimumSize: WidgetStatePropertyAll(Size(100, 40))),
    );
  }

  Widget EventCard(DateTime date, String title, String location) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Container(
        width: 240,
        height: 300,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    Container(
                      width: 220,
                      height: 160,
                      decoration: BoxDecoration(
                          color: Color(0xFFFFCD6C),
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                            color: Color(0xBBFFFFFF),
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              date.day.toString(),
                              style: Theme.of(context)
                                  .typography
                                  .white
                                  .bodyLarge!
                                  .apply(color: Color(0xFFFF6007)),
                            ),
                            Text(
                              months[date.month - 1],
                              style: Theme.of(context)
                                  .typography
                                  .white
                                  .bodySmall!
                                  .apply(color: Color(0xFFFF6007)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).typography.black.headlineSmall,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Theme.of(context).primaryColor,
                            ),
                            Text(
                              location,
                              style: Theme.of(context)
                                  .typography
                                  .black
                                  .bodyMedium!
                                  .apply(color: Theme.of(context).primaryColor),
                            )
                          ],
                        )
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.search,
              size: 28,
            )),
        title: Image(
            image: NetworkImage("https://i.imgur.com/0FHQKN4.png"),
            height: 40),
        actions: [
          IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.shopping_cart_outlined,
                size: 28,
              ))
        ],
        centerTitle: true,
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
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Column(
                      children: [
                        Image(
                            width: MediaQuery.of(context).size.width,
                            image: NetworkImage(
                                "https://i.imgur.com/JE2eR3M.png")),
                        SizedBox(
                          height: 20,
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        MainButton(Theme.of(context).primaryColorDark,
                            "Subscribe", "/subscribe"),
                        MainButton(Theme.of(context).primaryColorLight,
                            "Donate", "/donate"),
                        MainButton(Theme.of(context).primaryColorDark, "Shop",
                            "/shop"),
                      ],
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Upcoming Events",
                        style: Theme.of(context).typography.black.headlineMedium,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, "/events");
                        },
                        label: Text(
                          "See All",
                          style: Theme.of(context)
                              .typography
                              .black
                              .labelLarge!
                              .apply(color: Theme.of(context).primaryColor),
                        ),
                        icon: Icon(Icons.arrow_right_rounded),
                        iconAlignment: IconAlignment.end,
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(Colors.transparent),
                          foregroundColor: WidgetStatePropertyAll(
                              Theme.of(context).primaryColor),
                        ),
                      )
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: events.map((e) => EventCard(e["date"], e["title"], e["location"])).toList()
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image(
                            image: NetworkImage("https://i.imgur.com/UGnaS5X.jpeg"),
                            color: Color(0x88000000),
                            colorBlendMode: BlendMode.darken,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  "DADS PLAZA",
                                  style: Theme.of(context).typography.white.headlineMedium!.apply(color: Theme.of(context).primaryColorLight),
                                ),
                                SizedBox(height: 20,),
                                TextButton(
                                  onPressed: () {}, 
                                  child: Text("Learn More", style: Theme.of(context).typography.white.bodyMedium,),
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(Theme.of(context).primaryColorLight),
                                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
                                  ),
                                )
                              ]
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width/2.5,
                              child: Text(
                                "Illini Dads Centennial Plaza honors the role and impact that father figures have in the lives of their Illini students",
                                style: Theme.of(context).typography.white.bodyLarge,
                                textAlign: TextAlign.justify,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Navigation(selected: 0),
    );
  }
}
