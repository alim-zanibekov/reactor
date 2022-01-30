import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/parsers/types/module.dart';
import '../common/open.dart';

class AppUserRating extends StatelessWidget {
  final UserFull? user;

  const AppUserRating({Key? key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 2,
            runSpacing: 2,
            children: <Widget>[
              for (int i = 0; i < 10; i++)
                Icon(Icons.star,
                    color: i < user!.stars! ? color : Colors.grey[200],
                    size: 20),
              if (user!.stars! >= 10) ...[
                SizedBox(width: double.infinity),
                for (int i = 10; i < 20; i++)
                  Icon(
                    Icons.star,
                    color: i < user!.stars! ? color : Colors.grey[300],
                    size: 20,
                  )
              ]
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: <InlineSpan>[
                const TextSpan(text: 'Рейтинг - '),
                if (user!.mainTag?.value != null)
                  TextSpan(
                    text: user!.mainTag!.value + '\n\n',
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => openTag(context, user!.mainTag),
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                  ),
                TextSpan(
                  text: user?.rating?.toString() ?? '––',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (user!.ratingWeekDelta != null)
                  TextSpan(
                    text: ' (за неделю ${_toRating(user?.ratingWeekDelta)})',
                  )
              ],
            ),
          ),
        )
      ],
    );
  }

  String _toRating(double? rating) => rating == null
      ? '––'
      : rating > 0
          ? '+$rating'
          : '$rating';
}
