import 'package:flutter/material.dart';

import '../../core/parsers/types/module.dart';
import '../common/open.dart';

class AppCategoriesUsers extends StatelessWidget {
  final List<StatsUser> users;

  const AppCategoriesUsers({Key key, this.users}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int index = 0;
    return Column(children: <Widget>[
      ...users.map((e) => _children(context, e, ++index))
    ]);
  }

  Widget _children(context, StatsUser user, int index) {
    final boldTextStyle = const TextStyle(fontWeight: FontWeight.w500);
    return Material(
      child: InkWell(
        onTap: () {
          if (user.username != null) {
            openUser(context, user.username, user.link);
          }
        },
        child: Container(
          padding: const EdgeInsets.only(left: 4, right: 8, top: 8, bottom: 8),
          height: 40,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              SizedBox(
                child: Text('#' + index.toString(), style: boldTextStyle),
              ),
              SizedBox(
                child: Text('  ${user.username}', style: boldTextStyle),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 5, right: 10),
                  child: CustomPaint(painter: DashedLinePainter()),
                ),
              ),
              SizedBox(child: Text('+${user.ratingDelta}')),
            ],
          ),
        ),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  const DashedLinePainter() : super();

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 4, dashSpace = 2, startX = 0;
    final paint = Paint()
      ..color = Colors.grey[500]
      ..strokeWidth = 0.5;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
