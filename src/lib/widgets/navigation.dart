// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';

class Navigation extends StatefulWidget {
  int selected;
  Navigation({super.key, required this.selected});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  Widget NavigationButton(int index, Icon icon, String route) {
    return IconButton(
      onPressed: () {
        if (index == 0)
          Navigator.popAndPushNamed(context, route);
        else
          Navigator.pushNamed(context, route);
      },
      icon: icon,
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(
          (widget.selected != index)
              ? Color(0xFFC8C6C7)
              : Theme.of(context).primaryColorDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: BoxBorder.fromLTRB(
          top: BorderSide(color: Theme.of(context).primaryColor),
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(128),
            offset: Offset(0, -1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          NavigationButton(0, Icon(Icons.home_outlined, size: 28), "/home"),
          NavigationButton(1, Icon(Icons.event_outlined, size: 28), "/events"),
          NavigationButton(2, Icon(Icons.explore_outlined, size: 28), "/map"),
          NavigationButton(
            3,
            Icon(Icons.shopping_bag_outlined, size: 28),
            "/shop",
          ),
          NavigationButton(
            4,
            Icon(Icons.account_circle_outlined, size: 28),
            "/profile",
          ),
        ],
      ),
    );
  }
}
