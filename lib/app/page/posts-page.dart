import 'package:flutter/material.dart';

import '../../core/api/types.dart';
import '../../core/common/menu.dart';
import '../../core/content/post-loader.dart';
import '../../core/content/tag-loader.dart';
import '../../core/parsers/types/module.dart';
import '../../core/preferences/preferences.dart';
import '../common/reload-notifier.dart';
import '../common/tabs-wrapper.dart';
import '../post/post-list.dart';
import '../tag/tag-list.dart';

class AppPage extends StatefulWidget {
  final Tag? tag;
  final bool main;

  const AppPage({Key? key, this.tag, this.main = false}) : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      tag?.isMain ?? false ? _AppPageTagsState() : _AppPagePostsState();
}

class _AppPagePostsState extends State<AppPage> {
  late List<PostLoader> _postLoaders;
  late String _title;
  Preferences _preferences = Preferences();
  bool _reversed = false;
  final _reloadNotifier = ReloadNotifier();

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
    final menu = Menu(context, items: [
      SimpleMenuItem(
          text: _reversed ? 'В прямом порядке' : 'В обратном порядке',
          onSelect: () {
            _postLoaders.forEach((it) {
              it.toggleReverse(startPageId: _reversed ? null : 1);
            });
            _reversed = !_reversed;
            _reloadNotifier.notify();
          })
    ]);
    return AppTabsWrapper(
      initialIndex: _preferences.postsType.index,
      main: widget.main,
      tabs: ['Все', 'Хорошее', 'Лучшее', 'Бездна'],
      title: _title,
      actions: <Widget>[
        Builder(
          builder: (context) => PopupMenuButton<int>(
            offset: const Offset(0, 50),
            icon: const Icon(Icons.more_vert),
            tooltip: 'Настройки',
            onSelected: (int? index) => menu.process(index),
            itemBuilder: (context) => menu.rawItems,
          ),
        )
      ],
      builder:
          (BuildContext context, int index, onScrollChange, onReloadPress) {
        return AppPostList(
          pageStorageKey: PageStorageKey<String>(_title + index.toString()),
          onScrollChange: onScrollChange,
          reloadNotifier: Listenable.merge([onReloadPress, _reloadNotifier]),
          loader: _postLoaders[index],
        );
      },
    );
  }
}

class _AppPageTagsState extends State<AppPage> {
  late List<TagLoader> _tagLoaders;
  late String _title;
  late Tag tag = widget.tag as Tag;

  @override
  void initState() {
    _tagLoaders = [
      TagLoader(
        path: tag.link!,
        prefix: tag.prefix,
        tagListType: TagListType.BEST,
      ),
      TagLoader(
        path: tag.link!,
        prefix: tag.prefix,
        tagListType: TagListType.NEW,
      ),
    ];
    _title = tag.value;
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
      builder: (BuildContext _, int index, onScrollChange, onReloadPress) {
        return AppTagList(
          pageStorageKey:
              PageStorageKey<String>('tag-' + _title + index.toString()),
          onScrollChange: onScrollChange,
          reloadNotifier: onReloadPress,
          loader: _tagLoaders[index],
        );
      },
    );
  }
}
