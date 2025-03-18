import 'dart:math';

import 'package:flutter/material.dart';
import 'package:src/widgets/navigation.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  Map<int, int> quantity = {};

  Widget ShopItem(int id, String name, double price, String image) {
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  name,
                                  style: Theme.of(context)
                                      .typography
                                      .white
                                      .headlineSmall!
                                      .apply(
                                          color: Theme.of(context)
                                              .primaryColorLight,
                                          fontSizeDelta: -4),
                                ),
                                Text(
                                  "\$${price}",
                                  style: Theme.of(context)
                                      .typography
                                      .black
                                      .bodyMedium!
                                      .apply(
                                          color: Theme.of(context)
                                              .primaryColorDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                                onPressed: () {
                                  quantity.update(id, (v) => max(v - 1, 0),
                                      ifAbsent: () => 0);
                                  setState(() {
                                    quantity = quantity;
                                  });
                                },
                                icon: Icon(Icons.remove)),
                            Text(
                              (quantity.containsKey(id))
                                  ? quantity[id]!.toString()
                                  : "0",
                              style:
                                  Theme.of(context).typography.black.bodyMedium,
                            ),
                            IconButton(
                                onPressed: () {
                                  quantity.update(id, (v) => v + 1,
                                      ifAbsent: () => 1);
                                  setState(() {
                                    quantity = quantity;
                                  });
                                },
                                icon: Icon(Icons.add)),
                          ],
                        )
                      ]),
                ),
              )
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Shop",
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
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShopItem(0, "Centennial Plaza Brick", 250,
                      "https://i.imgur.com/UGnaS5X.jpeg"),
                  ShopItem(1, "Centennial Plaza Brick", 250,
                      "https://i.imgur.com/UGnaS5X.jpeg"),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Navigation(selected: 3),
    );
  }
}
