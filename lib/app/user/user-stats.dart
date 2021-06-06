import 'package:flutter/material.dart';

import '../../core/parsers/types/module.dart';

class AppUserStats extends StatelessWidget {
  final UserStats? stats;

  const AppUserStats({Key? key, this.stats}) : super(key: key);

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
          TextSpan(text: '${stats!.postCount ?? '0'}\n'),
          const TextSpan(
            text: 'Хороших постов: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(text: '${stats!.goodPostCount ?? '0'}\n'),
          const TextSpan(
            text: 'Лучших постов: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(text: '${stats!.bestPostCount ?? '0'}\n\n'),
          const TextSpan(
            text: 'Комментариев: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(text: '${stats!.commentsCount ?? '0'}\n\n'),
          if (stats!.lastEnter != null)
            const TextSpan(
              text: 'Последний раз заходил: ',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          if (stats!.lastEnter != null)
            TextSpan(
              text:
                  '${stats!.lastEnter!.toUtc().toString().split(' ').first}\n\n',
            ),
          if (stats!.daysCount != null)
            const TextSpan(
              text: 'Дней подряд: ',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          if (stats!.daysCount != null) TextSpan(text: '${stats!.daysCount}'),
        ],
      ),
    );
  }
}
