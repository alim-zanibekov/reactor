import 'package:flutter/material.dart';

import '../../core/api/types.dart';
import '../../core/content/post-loader.dart';
import '../../core/content/tag-loader.dart';
import '../../core/parsers/types/module.dart';
import '../../core/preferences/preferences.dart';
import '../common/tabs-wrapper.dart';
import '../post/post-list.dart';
import '../tag/tag-list.dart';

class AppPage extends StatefulWidget {
  final Tag tag;
  final bool main;

  const AppPage({Key key, this.tag, this.main = false}) : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      tag?.isMain ?? false ? _AppPageTagsState() : _AppPagePostsState();
}

class _AppPagePostsState extends State<AppPage> {
  List<PostLoader> _postLoaders;
  String _title;
  Preferences _preferences = Preferences();

  @override
  void initState() {
    _postLoaders = [
      PostLoader(
        postListType: widget.main ? PostListType.ALL : PostListType.NEW,
        path: widget.tag?.link,
        prefix: widget.tag?.prefix,
      ),
      PostLoader(
        postListType: PostListType.GOOD,
        path: widget.tag?.link,
        prefix: widget.tag?.prefix,
      ),
      PostLoader(
        postListType: PostListType.BEST,
        path: widget.tag?.link,
        prefix: widget.tag?.prefix,
      ),
      PostLoader(
        postListType: widget.main ? PostListType.NEW : PostListType.ALL,
        path: widget.tag?.link,
        prefix: widget.tag?.prefix,
      ),
    ];
    _title = widget.tag?.value ?? 'Reactor';

    super.initState();
  }

  @override
  void dispose() {
    _postLoaders.forEach((e) => e.destroy());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTabsWrapper(
      initialIndex: _preferences?.postsType?.index,
      main: widget.main,
      tabs: ['Все', 'Хорошее', 'Лучшее', 'Бездна'],
      title: _title,
      builder:
          (BuildContext context, int index, onScrollChange, onReloadPress) {
        return AppPostList(
          pageStorageKey: PageStorageKey<String>(_title + index.toString()),
          onScrollChange: onScrollChange,
          reloadNotifier: onReloadPress,
          loader: _postLoaders[index],
        );
      },
    );
  }
}

class _AppPageTagsState extends State<AppPage> {
  List<TagLoader> _tagLoaders;
  String _title;

  @override
  void initState() {
    _tagLoaders = [
      TagLoader(
        path: widget.tag.link,
        prefix: widget.tag.prefix,
        tagListType: TagListType.BEST,
      ),
      TagLoader(
        path: widget.tag.link,
        prefix: widget.tag.prefix,
        tagListType: TagListType.NEW,
      ),
    ];
    _title = widget.tag?.value;
    super.initState();
  }

  @override
  void dispose() {
    _tagLoaders.forEach((e) => e.destroy());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTabsWrapper(
      main: widget.main,
      tabs: ['Лучшие', 'Новые'],
      title: _title,
      builder:
          (BuildContext context, int index, onScrollChange, onReloadPress) {
        return AppTagList(
          pageStorageKey: PageStorageKey<String>(_title + index.toString()),
          onScrollChange: onScrollChange,
          loader: _tagLoaders[index],
        );
      },
    );
  }
}
