import 'package:flutter/material.dart';

import '../../core/parsers/types/module.dart';
import '../common/open.dart';

class AppCategoriesComments extends StatelessWidget {
  final List<StatsComment> comments;

  const AppCategoriesComments({Key key, this.comments = const []})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    int index = 0;
    return Column(children: <Widget>[
      ...comments.map((e) => _children(context, e, ++index))
    ]);
  }

  Widget _children(context, StatsComment comment, int index) {
    final boldTextStyle = const TextStyle(fontWeight: FontWeight.w500);
    return Material(
      child: InkWell(
        onTap: () =>
            openPostById(context, comment.postId, commentId: comment.id),
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
                child: Text('  +${comment.rating}', style: boldTextStyle),
              ),
              SizedBox(
                child: Text(' от ${comment.username}'),
              ),
              const Expanded(child: SizedBox()),
              SizedBox(
                height: 25,
                width: 100,
                child: OutlineButton(
                  highlightedBorderColor: Theme.of(context).accentColor,
                  onPressed: () {
                    if (comment.username != null) {
                      openUser(context, comment.username, comment.userLink);
                    }
                  },
                  child: Text(
                    comment.username,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
