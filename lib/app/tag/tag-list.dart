import 'package:flutter/material.dart';
import 'package:reactor/app/common/open.dart';

import '../../core/content/tag-loader.dart';
import '../../core/parsers/types/module.dart';
import '../common/loader-list.dart';
import '../tag/tag.dart';

class AppTagList extends StatelessWidget {
  final void Function(double delta) onScrollChange;
  final PageStorageKey pageStorageKey;
  final TagLoader loader;
  final ChangeNotifier reloadNotifier;

  const AppTagList(
      {Key key,
      @required this.loader,
      this.pageStorageKey,
      this.onScrollChange,
      this.reloadNotifier})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppLoaderList<ExtendedTag>(
      loader: loader,
      pageStorageKey: pageStorageKey,
      onScrollChange: onScrollChange,
      reloadNotifier: reloadNotifier,
      builder: (BuildContext context, dynamic element) {
        return Material(
          child: InkWell(
            onTap: () {
              openTag(context, element);
            },
            child: Padding(
              padding:
              const EdgeInsets.only(top: 5, bottom: 5, left: 8, right: 8),
              child: AppTag(size: 70, tag: element),
            ),
          ),
        );
      },
    );
  }
}
