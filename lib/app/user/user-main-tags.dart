import 'package:flutter/material.dart';

import '../../core/common/retry-network-image.dart';
import '../../core/content/types/module.dart';
import '../common/open.dart';

class AppUserMainTags extends StatelessWidget {
  final List<UserTag> tags;
  final EdgeInsets defaultPadding;

  const AppUserMainTags({Key key, this.tags, this.defaultPadding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      ...tags.map((e) => Material(
              child: InkWell(
            onTap: () {
              openTag(context, e);
            },
            child: Padding(
              padding: defaultPadding.copyWith(top: 5, bottom: 5),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      child: Image(
                        fit: BoxFit.cover,
                        image: AppNetworkImageWithRetry(e.icon),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          e.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        if (e.rating != null)
                          Text(
                            'Рейтинг в сообществе ${e.rating.toString()}',
                            style: const TextStyle(fontSize: 12, height: 1.5),
                          ),
                        if (e.ratingWeekDelta != null)
                          Text(
                            'За неделю ${_toRating(e.ratingWeekDelta)}',
                            style: const TextStyle(fontSize: 12),
                          )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )))
    ]);
  }

  String _toRating(double rating) =>
      rating == null ? '––' : rating > 0 ? '+$rating' : '$rating';
}
