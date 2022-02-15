import 'dart:io';

import 'package:flutter/material.dart';

class PageWrapper extends StatefulWidget {
  final Widget child;

  const PageWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _PageWrapperState createState() => _PageWrapperState();
}

class _PageWrapperState extends State<PageWrapper> {
  double _statusBarHeight = 0;

  @override
  Widget build(BuildContext context) {
    if (_statusBarHeight == 0) {
      final double statusBarHeight = MediaQuery.of(context).padding.top;
      _statusBarHeight = statusBarHeight;
    }
    if (Platform.isIOS) {
      return widget.child;
    } else {
      final theme = Theme.of(context);
      return Container(
        color: theme.brightness == Brightness.dark
            ? theme.bottomAppBarColor
            : theme.primaryColor,
        padding: EdgeInsets.only(top: _statusBarHeight),
        child: widget.child,
      );
    }
  }
}
