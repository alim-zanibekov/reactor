import 'package:flutter/material.dart';

import '../../core/content/types/module.dart';
import '../common/open.dart';
import '../tag/tag.dart';

class AppCategoriesTags extends StatelessWidget {
  final List<ExtendedTag> tags;

  const AppCategoriesTags({Key key, this.tags}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      ...tags.map((e) => _children(context, e)),
    ]);
  }

  Widget _children(context, ExtendedTag tag) {
    return Material(
      child: InkWell(
        onTap: () {
          openTag(context, tag);
        },
        child: Container(
          padding: const EdgeInsets.only(left: 4, right: 8, top: 8, bottom: 8),
          height: 60,
          alignment: Alignment.center,
          child: Center(
            child: AppTag(tag: tag),
          ),
        ),
      ),
    );
  }
}
