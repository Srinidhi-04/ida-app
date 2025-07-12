import 'package:flutter/material.dart';
import 'package:src/widgets/navigation.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  int? pressed;

  List board = [
    {
      "name": "Ferdinand Belga",
      "position": "President",
      "image": "assets/board/ferdinand.jpg",
    },
    {
      "name": "Brodie Bertrand",
      "position": "Vice President",
      "image": "assets/board/brodie.jpg",
    },
    {
      "name": "Jim Golemba",
      "position": "Treasurer",
      "image": "assets/board/jim.png",
    },
    {
      "name": "Scott Burns",
      "position": "Secretary",
      "image": "assets/board/scott.jpg",
    },
    {
      "name": "Adam Crane",
      "position": "MHA Driver",
      "image": "assets/board/adam.jpg",
    },
    {
      "name": "David Mann",
      "position": "BBQ/Brunch Lead",
      "image": "assets/board/david.jpg",
    },
    {
      "name": "DeMaso Skip",
      "position": "A Cappella Lead",
      "image": "assets/board/demaso.jpg",
    },
    {
      "name": "Sean Widener",
      "position": "5K & Strategic Engagement",
      "image": "assets/board/sean.jpg",
    },
    {
      "name": "Phil Lengle",
      "position": "Philanthropy Lead",
      "image": "assets/board/phil.jpg",
    },
    {
      "name": "Greg Hull",
      "position": "Apparel Lead",
      "image": "assets/board/greg.png",
    },
    {
      "name": "Ryan Jones",
      "position": "King Dad Committee",
      "image": "assets/board/ryan.png",
    },
    {
      "name": "Kerry Dunaway",
      "position": "Communications Lead",
      "image": "assets/board/kerry.jpg",
    },
    {
      "name": "Kevin Ficek",
      "position": "Career Starts Lead",
      "image": "assets/board/kevin_1.jpg",
    },
    {
      "name": "Matt Randazzo",
      "position": "Finance Lead",
      "image": "assets/board/matt.jpg",
    },
    {
      "name": "Jeff Gallenbeck",
      "position": "Plaza Lead",
      "image": "assets/board/jeff.jpg",
    },
    {
      "name": "Rice Nathan",
      "position": "Communications",
      "image": "assets/board/rice.jpg",
    },
    {
      "name": "Erik Rankin",
      "position": "Strategic Engagement Lead",
      "image": "assets/board/erik.jpg",
    },
    {
      "name": "Kevin Counts",
      "position": "Plaza Lead",
      "image": "assets/board/kevin_2.jpg",
    },
    {
      "name": "Raju Vusirikala",
      "position": "Interns/App Lead",
      "image": "assets/board/raju.jpg",
    },
    {
      "name": "Ashish Khurana",
      "position": "Finance",
      "image": "assets/board/ashish.jpg",
    },
  ];

  Widget memberCard(int index, String name, String position, String image) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Card(
        color:
            (pressed != index)
                ? Colors.white
                : Theme.of(context).primaryColorLight,
        child: TextButton(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            fixedSize: WidgetStatePropertyAll(
              Size(
                MediaQuery.of(context).size.width * 0.5 - 30,
                MediaQuery.of(context).size.height * 0.3,
              ),
            ),
          ),
          onPressed: () {
            setState(() {
              if (pressed == index) {
                pressed = null;
              } else {
                pressed = index;
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        image: DecorationImage(image: AssetImage(image)),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                  child: Text(
                    name,
                    style:
                        (pressed != index)
                            ? Theme.of(context).typography.black.labelMedium
                            : Theme.of(context).typography.white.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  position,
                  style:
                      (pressed != index)
                          ? Theme.of(context).typography.black.labelSmall
                          : Theme.of(context).typography.white.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget generateGrid(List<Widget> widgets) {
    List<Widget> rows = [];
    bool flag = true;
    List<Widget> row = [];
    for (var widget in widgets) {
      row.add(widget);
      flag = !flag;
      if (flag) {
        rows.add(
          Row(mainAxisAlignment: MainAxisAlignment.center, children: row),
        );
        row = [];
      }
    }
    if (row.isNotEmpty) {
      rows.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: row));
    }
    return Column(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image(image: AssetImage("assets/logo.png"), height: 40),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                "Presenting the Illini Dads Association Board for 2025!",
                style: Theme.of(
                  context,
                ).typography.black.headlineSmall!.apply(fontSizeDelta: -1),
                textAlign: TextAlign.center,
              ),
            ),
            generateGrid(
              board
                  .map(
                    (e) => memberCard(
                      board.indexOf(e),
                      e["name"],
                      e["position"],
                      e["image"],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Navigation(selected: 0),
    );
  }
}
