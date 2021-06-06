import 'package:flutter/material.dart';

import '../../core/content/comments-loader.dart';
import '../../core/parsers/types/module.dart';
import '../comments/comments.dart';
import '../common/loader-list.dart';

class AppUserCommentsPage extends StatefulWidget {
  final String username;

  final void Function(double delta)? onScrollChange;
  final ChangeNotifier? reloadNotifier;

  const AppUserCommentsPage({
    Key? key,
    required this.username,
    this.onScrollChange,
    this.reloadNotifier,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppUserCommentsPageState();
}

class _AppUserCommentsPageState extends State<AppUserCommentsPage> {
  late CommentsLoader loader;

  @override
  void initState() {
    loader = CommentsLoader(widget.username);
    super.initState();
  }

  @override
  void dispose() {
    loader.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLoaderList<PostComment>(
      loader: loader,
      pageStorageKey: PageStorageKey<String>(widget.username + '-comments'),
      onScrollChange: widget.onScrollChange,
      reloadNotifier: widget.reloadNotifier,
      builder: (BuildContext context, dynamic element) {
        return AppComment(
          comment: element,
          depth: 0,
          showGoToPost: true,
        );
      },
    );
  }
}
