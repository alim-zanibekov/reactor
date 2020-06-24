import 'package:flutter/material.dart';

import '../../core/common/retry-network-image.dart';
import '../../core/content/types/module.dart';

class AppTag extends StatelessWidget {
  final ExtendedTag tag;
  final double size;

  const AppTag({Key key, this.tag, this.size = 50}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (tag.icon != null)
          SizedBox(
              width: size,
              height: size,
              child: ClipRRect(
                child: Image(
                  fit: BoxFit.cover,
                  image: AppNetworkImageWithRetry(tag.icon),
                ),
                borderRadius: BorderRadius.circular(4),
              )),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(left: 7),
            alignment: Alignment.centerLeft,
            child: RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                style:
                    DefaultTextStyle.of(context).style.copyWith(fontSize: 12),
                children: [
                  if (tag.value != null)
                    TextSpan(
                        text: '${tag.value}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 15)),
                  if (tag.subscribersCount != null) ...[
                    TextSpan(
                        text: '\nПодписчиков: ',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            height: tag.value != null ? 2 : 1)),
                    TextSpan(text: '${tag.subscribersCount}')
                  ],
                  if (tag.subscribersDeltaCount != null) ...[
                    TextSpan(
                        text: '\nПодписчиков: ',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            height: tag.value != null ? 2 : 1)),
                    TextSpan(text: '+${tag.subscribersDeltaCount}')
                  ],
                  if (tag.count != null) ...[
                    TextSpan(
                        text: '\nСообщений: ',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    TextSpan(text: '${tag.count}')
                  ],
                  if (tag.commonRating != null) ...[
                    TextSpan(
                        text: '\nРейтинг постов: ',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    TextSpan(text: '${tag.commonRating}')
                  ],
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
