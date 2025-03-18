import 'package:flutter/material.dart';
import 'package:src/widgets/navigation.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {

  Widget ShopItem(String name, double price, String image) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 150,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Card(
          elevation: 5,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: TextButton(
            onPressed: () {},
            style: ButtonStyle(
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image(
                      width: MediaQuery.of(context).size.width / 5,
                      height: 150,
                      image: NetworkImage(image),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      width: 0.8*MediaQuery.of(context).size.width - 120,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).typography.white.headlineSmall!.apply(color: Theme.of(context).primaryColorLight),
                          ),
                          Text(
                            "\$${price}",
                            style: Theme.of(context).typography.black.labelMedium!.apply(color: Theme.of(context).primaryColorDark),
                          )
                        ]
                      ),
                    ),
                  )
                ]
              ),
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
        title: Text("Shop", style: Theme.of(context).typography.black.headlineMedium!.apply(color: Theme.of(context).primaryColorDark)),
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
                children: [
                  ShopItem("Centennial Plaza Brick", 250, "https://i.imgur.com/UGnaS5X.jpeg"),
                  ShopItem("Centennial Plaza Brick", 250, "https://i.imgur.com/UGnaS5X.jpeg"),
                ],
              ),
            ),
          ),
      ),
      bottomNavigationBar: Navigation(selected: 3),
    );
  }
}