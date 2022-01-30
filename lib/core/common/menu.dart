import 'package:flutter/material.dart';

class MenuItem {
  final String text;
  final Function() onSelect;

  MenuItem({required this.text, required this.onSelect});
}

class Menu {
  final BuildContext context;
  final List<MenuItem> items;

  Menu(this.context, {required this.items});

  List<PopupMenuItem<int>> get rawItems => [
        for (final it in items.asMap().entries)
          PopupMenuItem(
            child: Text(it.value.text),
            value: it.key,
          )
      ];

  void process(int? index) {
    if (index != null) {
      items[index].onSelect();
    }
  }

  void open(RelativeRect position) {
    showMenu<int>(
      position: position,
      context: context,
      items: rawItems,
      elevation: 8.0,
    ).then<void>((delta) {
      process(delta);
    });
  }

  void openUnderTap(Offset offset) {
    final RenderBox? overlay =
        Overlay.of(context)!.context.findRenderObject() as RenderBox?;
    open(RelativeRect.fromRect(
        offset & Size(40, 40),
        overlay != null
            ? Offset.zero & overlay.size
            : Rect.fromLTWH(0, 0, 100, 100)));
  }
}
