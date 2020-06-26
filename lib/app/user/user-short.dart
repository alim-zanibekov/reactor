import 'package:flutter/material.dart';

import '../../core/common/datetime-formatter.dart';
import '../../core/common/retry-network-image.dart';
import '../../core/content/types/module.dart';
import '../common/open.dart';

class AppShortUser extends StatelessWidget {
  final UserShort user;
  final double size;

  const AppShortUser({@required this.user, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openUser(context, user.username, user.link);
      },
      child: Row(children: <Widget>[
        if (user.avatar != null)
          CircleAvatar(
            radius: size / 2.0,
            backgroundImage: AppNetworkImageWithRetry(user.avatar),
          ),
        Container(
          height: size,
          color: Colors.transparent,
          padding: const EdgeInsets.only(left: 5),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              user.username,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        )
      ], crossAxisAlignment: CrossAxisAlignment.start),
    );
  }
}

class AppPostUser extends StatelessWidget {
  final UserShort user;
  final double size;
  final DateTime dateTime;

  const AppPostUser({@required this.user, this.dateTime, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        openUser(context, user.username, user.link);
      },
      child: Row(children: <Widget>[
        CircleAvatar(
          radius: size / 2.0,
          backgroundImage: AppNetworkImageWithRetry(user.avatar),
        ),
        Container(
          height: size,
          padding: const EdgeInsets.only(left: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                DateTimeFormatter(dateTime: dateTime).withHourPrecision(),
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[400] : Colors.black38,
                ),
              )
            ],
          ),
        )
      ], crossAxisAlignment: CrossAxisAlignment.start),
    );
  }
}
