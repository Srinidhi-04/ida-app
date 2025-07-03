import 'package:flutter/material.dart';
import 'package:src/widgets/navigation.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  Map<int, int> quantity = {};

  List<Map> items = [
    {
      "id": 0,
      "name": "Centennial Plaza Brick",
      "price": 250.0,
      "image": "https://i.imgur.com/UGnaS5X.jpeg",
    },
    {
      "id": 1,
      "name": "Centennial Plaza Brick",
      "price": 250.0,
      "image": "https://i.imgur.com/UGnaS5X.jpeg",
    },
  ];

  bool cart = false;
  bool initialized = false;

  Widget shopItem(int id, String name, double price, String image) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 170,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
        child: Card(
          elevation: 5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: Theme.of(
                                  context,
                                ).typography.white.labelMedium!.apply(
                                  color: Theme.of(context).primaryColorLight,
                                  fontSizeDelta: 2,
                                  fontWeightDelta: 3,
                                ),
                              ),
                              Text(
                                "\$${price}",
                                style: Theme.of(
                                  context,
                                ).typography.black.labelSmall!.apply(
                                  color: Theme.of(context).primaryColorDark,
                                  fontWeightDelta: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              (!quantity.containsKey(id) || quantity[id] == 0)
                                  ? TextButton(
                                    onPressed: () {
                                      setState(() {
                                        quantity[id] = 1;
                                      });
                                    },
                                    child: Text(
                                      "Add to cart",
                                      style: Theme.of(
                                        context,
                                      ).typography.black.labelSmall!.apply(
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        fontWeightDelta: 3,
                                      ),
                                    ),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(
                                        Theme.of(context).primaryColorLight,
                                      ),
                                      shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color:
                                            Theme.of(context).primaryColorLight,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          constraints: BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () {
                                            setState(() {
                                              quantity[id] = quantity[id]! - 1;
                                              if (quantity[id] == 0)
                                                quantity.remove(id);
                                            });
                                          },
                                          icon: Icon(Icons.remove, size: 15),
                                        ),
                                        Text(
                                          (quantity.containsKey(id))
                                              ? quantity[id]!.toString()
                                              : "0",
                                          style:
                                              Theme.of(
                                                context,
                                              ).typography.black.labelSmall,
                                        ),
                                        IconButton(
                                          constraints: BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () {
                                            setState(() {
                                              quantity[id] = quantity[id]! + 1;
                                            });
                                          },
                                          icon: Icon(Icons.add, size: 15),
                                        ),
                                      ],
                                    ),
                                  ),
                              (quantity.containsKey(id) && quantity[id]! > 0)
                                  ? Padding(
                                    padding: const EdgeInsets.only(top: 5.0),
                                    child: Text(
                                      "Total Price: \$${quantity[id]! * price}",
                                      style: Theme.of(
                                        context,
                                      ).typography.black.labelSmall!.apply(
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        fontWeightDelta: 3,
                                      ),
                                    ),
                                  )
                                  : Container(),
                            ],
                          ),
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
    );
  }

  double calculateTotal() {
    double total = 0;

    for (var item in items) {
      if (quantity.containsKey(item["id"])) {
        total += quantity[item["id"]]! * item["price"];
      }
    }

    return total;
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
          cart = true;
          quantity = args["quantity"];
          initialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (cart) ? "Cart" : "Shop",
          style: Theme.of(context).typography.black.headlineMedium!.apply(
            color: Theme.of(context).primaryColorDark,
          ),
        ),
      ),
      body:
          (cart && quantity.isEmpty)
              ? Center(
                child: Text(
                  "Cart is empty",
                  style: Theme.of(context).typography.black.headlineLarge,
                ),
              )
              : RefreshIndicator(
                onRefresh: () async {},
                color: Theme.of(context).primaryColorLight,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          kToolbarHeight -
                          kBottomNavigationBarHeight,
                      minWidth: MediaQuery.of(context).size.width,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 20.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Cart Total: ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: "\$${calculateTotal()}"),
                                  ],
                                ),
                                style: Theme.of(
                                  context,
                                ).typography.black.labelMedium!.apply(
                                  color: Theme.of(context).primaryColorDark,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                items
                                    .map(
                                      (e) =>
                                          (!cart ||
                                                  quantity.containsKey(e["id"]))
                                              ? shopItem(
                                                e["id"],
                                                e["name"],
                                                e["price"],
                                                e["image"],
                                              )
                                              : Container(),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      floatingActionButton:
          (!cart && quantity.isNotEmpty)
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    "/shop",
                    arguments: {"cart": true, "quantity": quantity},
                  );
                },
                child: Icon(Icons.shopping_cart_outlined),
                backgroundColor: Theme.of(context).primaryColorDark,
                foregroundColor: Theme.of(context).primaryColorLight,
                shape: CircleBorder(),
              )
              : null,
      bottomNavigationBar: Navigation(selected: 3),
    );
  }
}
