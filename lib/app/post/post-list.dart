import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/tag/tag-header.dart';
import '../../core/auth/auth.dart';
import '../../core/content/types/module.dart';
import '../../core/widgets/onerror-reload.dart';
import '../common/future-page.dart';
import 'post-loader.dart';
import 'post.dart';

class AppPostList extends StatefulWidget {
  final void Function(double delta) onScrollChange;
  final PageStorageKey pageStorageKey;
  final PostLoader loader;
  final ChangeNotifier reloadNotifier;

  AppPostList(
      {Key key,
      @required this.loader,
      this.reloadNotifier,
      this.pageStorageKey,
      this.onScrollChange})
      : super(key: key);

  @override
  _AppPostListState createState() => _AppPostListState();
}

class _AppPostListState extends State<AppPostList>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final Duration _collapseDuration = const Duration(milliseconds: 250);
  final Curve _collapseCurve = Curves.easeInOut;
  final List<MountInfo> _mounted = [];
  ScrollController _scrollController = ScrollController();
  GlobalKey _pageKey = GlobalKey();
  AnimationController _animationController;
  double _scrollPrevious;

  List<Post> _posts;
  List<Widget> _postWidgets;

  bool _collapsing;
  bool _showHeader;

  StreamSubscription _subscription;

  bool _isDark;

  int _showCollapsePostId;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 150));
    _animationController.value = 1;
    _scrollController.addListener(_onScrollChange);
    _subscription = Auth().authorized$.listen((event) {
      AppFuturePageState appFuturePageState = _pageKey.currentState;
      appFuturePageState?.reload(hideContent: true);
    });

    widget.reloadNotifier?.addListener(_reload);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _subscription.cancel();
    widget.reloadNotifier?.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    _posts = null;
    _scrollController.jumpTo(0);
    Future.microtask(() {
      AppFuturePageState appFuturePageState = _pageKey.currentState;
      appFuturePageState?.reload();
    });
  }

  AppPostContent _getAppPostContent(int index, Post e) => AppPostContent(
      key: ObjectKey(e),
      post: e,
      onCollapse: _onPostCollapse,
      collapseCurve: _collapseCurve,
      onMountInfo: _onMountInfo,
      loadContent: () async {
        try {
          final post = await widget.loader.loadContent(e.id);
          _postWidgets[index] = _getAppPostContent(index, post);
          _postWidgets = List.from(_postWidgets);
          if (mounted) setState(() {});
        } on Exception {
          Scaffold.of(context).showSnackBar(
            const SnackBar(
                content: Text('Не удалось загрзить содержимое поста')),
          );
        }
      },
      collapseDuration: _collapseDuration);

  void _onMountInfo(MountInfo mountInfo) async {
    if (mountInfo.state) {
      _mounted.add(mountInfo);
    } else {
      _mounted
          .removeAt(_mounted.indexWhere((e) => e.post.id == mountInfo.post.id));
      if (_showCollapsePostId != null &&
          _showCollapsePostId == mountInfo.post.id) {
        _animationController.forward(from: 0);
        _showCollapsePostId = null;
      }
    }
  }

  void _onPostCollapse(bool state, double diff) async {
    if (!state) {
      await Future.delayed(_collapseDuration);
      _onScrollChange();
      return;
    }
    _collapsing = true;
    await _scrollController.animateTo(_scrollController.offset - diff,
        duration: _collapseDuration, curve: _collapseCurve);
    _collapsing = false;
    _onScrollChange();
    if (_showCollapsePostId != null) {
      _animationController.forward(from: 0);
      _showCollapsePostId = null;
    }
  }

  void _onScrollChange() {
    if (!_collapsing) {
      widget.onScrollChange(_scrollController.offset - _scrollPrevious);
    }
    _mounted.forEach((element) {
      if (element.post.expanded) {
        RenderBox renderBoxTop = _pageKey.currentContext.findRenderObject();
        RenderBox renderBox = element.key.currentContext.findRenderObject();
        final offset = renderBox.localToGlobal(Offset.zero) -
            renderBoxTop.localToGlobal(Offset.zero);
        Size postSize = element.key.currentContext.size;
        Size renderBoxWrapperSize = _pageKey.currentContext.size;
        if (offset.dy + postSize.height - renderBoxWrapperSize.height - 60 >
                0 &&
            offset.dy < renderBoxWrapperSize.height / 1.5) {
          if (_showCollapsePostId == null) {
            _animationController.reverse(from: 1);
          }
          _showCollapsePostId = element.post.id;
        } else {
          if (_showCollapsePostId != null) {
            _animationController.forward(from: 0);
          }
          _showCollapsePostId = null;
        }
      }
    });
    _scrollPrevious = _scrollController.offset;
  }

  void _closePost() {
    _mounted.forEach((element) {
      if (element.post.expanded) {
        RenderBox renderBox = element.key.currentContext.findRenderObject();
        final offset = renderBox.localToGlobal(Offset.zero);
        RenderBox renderBoxTop = _pageKey.currentContext.findRenderObject();
        final offsetTop = renderBoxTop.localToGlobal(Offset.zero);
        _onPostCollapse(true, -offset.dy + offsetTop.dy);
        element.collapse();
      }
    });
    _showCollapsePostId = null;
    _animationController.forward(from: 0);
  }

  Widget _itemBuilder(context, index, hasError) {
    if (_showHeader && index == 0) {
      return AppTagHeader(
        prefix: widget.loader.prefix,
        pageInfo: widget.loader.firstPage.pageInfo,
        onBlock: () {
          _posts = null;
          AppFuturePageState appFuturePageState = _pageKey.currentState;
          appFuturePageState?.reload();
        },
      );
    }
    if (_showHeader) index = index - 1;
    if (index < _postWidgets.length) {
      return _postWidgets[index];
    } else {
      if (hasError) {
        return AppOnErrorReloadExpanded(
          onReloadPressed: () {
            AppFuturePageState appFuturePageState = _pageKey.currentState;
            appFuturePageState?.reload();
          },
        );
      }
      if (widget.loader.complete) {
        return Container(
          color: _isDark ? Colors.black26 : Colors.grey[200],
          padding: const EdgeInsets.all(10),
          child: Center(
            child: Text(_postWidgets.isNotEmpty
                ? 'Больше постов нет'
                : 'Тут ничего нет'),
          ),
        );
      }

      AppFuturePageState appFuturePageState = _pageKey.currentState;
      if (!(appFuturePageState?.loading ?? true)) {
        appFuturePageState?.reload(withoutIndicator: true);
      }

      return const SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(
              child: CircularProgressIndicator(strokeWidth: 2),
              height: 20.0,
              width: 20.0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: <Widget>[
        AppFuturePage<void>(
          customError: true,
          key: _pageKey,
          load: (fromUser) async {
            if (fromUser) {
              _posts = null;
              widget.loader.reset();
            }
            final isFirst = _posts == null || _posts.isEmpty;

            final create = await (isFirst
                ? widget.loader.load()
                : widget.loader.loadNext());

            if (isFirst) {
              _postWidgets = [];
              _showHeader = false;
              _collapsing = false;
              _scrollPrevious = 0;
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(0);
              }
            }

            int index = _postWidgets.length;
            _postWidgets.addAll(
                create.map((e) => _getAppPostContent(index++, e)).toList());

            _posts = widget.loader.posts;
            _showHeader = widget.loader?.firstPage?.pageInfo != null;
          },
          builder: (context, _, bool hasError) {
            if ((_posts?.isEmpty ?? true) && hasError) {
              return AppOnErrorReloadExpanded(
                onReloadPressed: () {
                  _posts = null;
                  AppFuturePageState appFuturePageState = _pageKey.currentState;
                  appFuturePageState?.reload(hideContent: true);
                },
              );
            }
            return ListView.builder(
              key: widget.pageStorageKey,
              controller: _scrollController,
              itemBuilder: (ctx, i) => _itemBuilder(ctx, i, hasError),
              itemCount: _postWidgets.length + (_showHeader ? 2 : 1),
            );
          },
        ),
        AnimatedBuilder(
          animation: _animationController,
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
                color: Theme.of(context).accentColor,
                borderRadius: BorderRadius.circular(40)),
            child: IconButton(
              onPressed: _closePost,
              icon: const Icon(Icons.keyboard_arrow_up),
            ),
          ),
          builder: (BuildContext context, Widget child) {
            return Positioned(
              bottom: 10 - 100 * _animationController.value,
              right: 10,
              child: child,
            );
          },
        )
      ],
    );
  }

  @override
  bool wantKeepAlive = true;
}
