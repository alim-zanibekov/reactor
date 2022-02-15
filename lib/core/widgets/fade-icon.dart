import 'package:flutter/material.dart';

class FadeIcon extends StatefulWidget {
  final Icon icon;
  final Color? color;

  const FadeIcon({Key? key, required this.icon, this.color}) : super(key: key);

  @override
  _FadeIconState createState() => _FadeIconState();
}

class _FadeIconState extends State<FadeIcon> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true, min: 0.5, max: 1);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  get isDark {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.color ?? (isDark ? Colors.black26 : Colors.grey[200]!),
      child: Center(
        child: FadeTransition(opacity: _animation, child: widget.icon),
      ),
    );
  }
}
