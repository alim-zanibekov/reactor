import 'package:flutter/material.dart';

import '../../core/content/types/module.dart';

class AppUserStats extends StatelessWidget {
  final UserStats stats;

  const AppUserStats({Key key, this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(height: 1.5),
        children: <InlineSpan>[
          const TextSpan(
            text: 'Постов: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(text: '${stats.postCount}\n'),
          const TextSpan(
            text: 'Хороших постов: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(text: '${stats.goodPostCount}\n'),
          const TextSpan(
            text: 'Лучших постов: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(text: '${stats.bestPostCount}\n\n'),
          const TextSpan(
            text: 'Комментариев: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(text: '${stats.commentsCount}\n\n'),
          const TextSpan(
            text: 'Последний раз заходил: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          if (stats.lastEnter != null)
            TextSpan(
              text:
                  '${stats.lastEnter.toUtc().toString().split(' ').first}\n\n',
            ),
          const TextSpan(
            text: 'Дней подряд: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(text: '${stats.daysCount}'),
        ],
      ),
    );
  }
}
