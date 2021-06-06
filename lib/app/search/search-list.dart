import 'package:flutter/material.dart';

import '../../core/content/post-loader.dart';
import '../common/page-wrapper.dart';
import '../post/post-list.dart';

class _ReloadNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

class AppSearchList extends StatefulWidget {
  final String? query;
  final String? author;
  final List<String?>? tags;

  const AppSearchList({Key? key, this.query, this.author, this.tags})
      : super(key: key);

  @override
  _AppSearchListState createState() => _AppSearchListState();
}

class _AppSearchListState extends State<AppSearchList> {
  final _reloadNotifier = _ReloadNotifier();
  late PostLoader _loader;

  @override
  void initState() {
    _loader = PostLoader(
      search: true,
      query: widget.query,
      author: widget.author,
      tags: widget.tags,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: Scaffold(
        primary: false,
        appBar: AppBar(
          primary: false,
          title: Text('Поиск'),
        ),
        body: AppPostList(
          loader: _loader,
          reloadNotifier: _reloadNotifier,
        ),
      ),
    );
  }
}
