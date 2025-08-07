// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';

class CartButton extends StatefulWidget {
  late Map quantity;
  late Function callback;
  CartButton({super.key, required this.quantity, required this.callback});

  @override
  State<CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<CartButton> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.of(context)
            .pushNamed(
              "/shop",
              arguments: {"cart": true, "quantity": widget.quantity},
            )
            .then((value) {
              widget.callback();
            });
      },
      child: Stack(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: Theme.of(context).primaryColorDark,
            size: 32,
          ),
          (widget.quantity.length > 0)
              ? Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                  child: Center(
                    child: Text(
                      widget.quantity.length.toString(),
                      style: Theme.of(
                        context,
                      ).typography.white.labelSmall!.apply(fontSizeDelta: -2),
                    ),
                  ),
                ),
              )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
