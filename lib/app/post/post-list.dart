import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/tag/tag-header.dart';
import '../../core/auth/auth.dart';
import '../../core/common/snack-bar.dart';
import '../../core/content/post-loader.dart';
import '../../core/parsers/types/module.dart';
import '../../core/widgets/onerror-reload.dart';
import '../common/future-page.dart';
import 'post.dart';

class AppPostList extends StatefulWidget {
  final void Function(double delta)? onScrollChange;
  final PageStorageKey? pageStorageKey;
  final PostLoader loader;
  final Listenable? reloadNotifier;

  AppPostList({
    Key? key,
    required this.loader,
    this.reloadNotifier,
    this.pageStorageKey,
    this.onScrollChange,
  }) : super(key: key);

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
  late AnimationController _animationController;
  late double _scrollPrevious;

  List<Post>? _posts;
  late List<Widget> _postWidgets;

  late bool _collapsing;
  late bool _showHeader;

  late StreamSubscription _subscription;

  late bool _isDark;

  int? _showCollapsePostId;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _animationController.value = 1;
    _scrollController.addListener(_onScrollChange);
    _subscription = Auth().authorized$.listen((event) {
      if (mounted) {
        _posts = null;
        widget.loader.reset();
        setState(() {});
      }
      Future.microtask(() {
        AppFuturePageState? appFuturePageState =
            _pageKey.currentState as AppFuturePageState<dynamic>?;
        appFuturePageState?.reload(hideContent: true);
      });
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
      AppFuturePageState? appFuturePageState =
          _pageKey.currentState as AppFuturePageState<dynamic>?;
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
          SnackBarHelper.show(context, 'Не удалось загрузить содержимое поста');
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

  void _onPostCollapse(bool state, double? diff) async {
    if (!state) {
      await Future.delayed(_collapseDuration);
      _onScrollChange();
      return;
    }
    if (diff == null) {
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
      widget.onScrollChange?.call(_scrollController.offset - _scrollPrevious);
    }
    bool isCollapseShow = _showCollapsePostId != null;
    int? postId;
    _mounted.forEach((element) {
      if (element.post.expanded) {
        final renderBoxTop =
            _pageKey.currentContext?.findRenderObject() as RenderBox?;
        final renderBox =
            element.key?.currentContext?.findRenderObject() as RenderBox?;
        final offset = (renderBox?.localToGlobal(Offset.zero) ?? Offset.zero) -
            (renderBoxTop?.localToGlobal(Offset.zero) ?? Offset.zero);
        final postSize = element.key?.currentContext?.size;
        final renderBoxWrapperSize = _pageKey.currentContext?.size;
        if (postSize != null &&
            renderBoxWrapperSize != null &&
            offset.dy + postSize.height - renderBoxWrapperSize.height - 60 >
                0 &&
            offset.dy < renderBoxWrapperSize.height / 1.5) {
          postId = element.post.id;
        }
      }
    });
    if (postId != null) {
      if (!isCollapseShow) {
        _animationController.reverse(from: 1);
      }
    } else if (isCollapseShow) {
      _animationController.forward(from: 0);
    }
    _showCollapsePostId = postId;
    _scrollPrevious = _scrollController.offset;
  }

  void _closePost() {
    _mounted.forEach((element) {
      if (element.post.expanded) {
        final renderBox =
            element.key?.currentContext?.findRenderObject() as RenderBox?;
        final offset = renderBox?.localToGlobal(Offset.zero);
        final renderBoxTop =
            _pageKey.currentContext?.findRenderObject() as RenderBox?;
        final offsetTop = renderBoxTop?.localToGlobal(Offset.zero);
        if (offset != null && offsetTop != null) {
          _onPostCollapse(true, -offset.dy + offsetTop.dy);
        }
        element.collapse();
      }
    });
    _showCollapsePostId = null;
    _animationController.forward(from: 0);
  }

  Widget _itemBuilder(context, index, hasError) {
    if (_showHeader && index == 0) {
      final pageInfo = widget.loader.firstPage.pageInfo;
      if (pageInfo == null) {
        return SizedBox();
      }
      return AppTagHeader(
        prefix: widget.loader.prefix,
        pageInfo: pageInfo,
        onBlock: () {
          _posts = null;
          AppFuturePageState? appFuturePageState =
              _pageKey.currentState as AppFuturePageState<dynamic>?;
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
            AppFuturePageState? appFuturePageState =
                _pageKey.currentState as AppFuturePageState<dynamic>?;
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

      AppFuturePageState? appFuturePageState =
          _pageKey.currentState as AppFuturePageState<dynamic>?;
      appFuturePageState?.reload(withoutIndicator: true);

      return const SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(
            child: CircularProgressIndicator(strokeWidth: 2),
            height: 20.0,
            width: 20.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(children: <Widget>[
      AppFuturePage<void>(
        customError: true,
        key: _pageKey,
        load: (fromUser) async {
          if (fromUser) {
            _posts = null;
            widget.loader.reset();
          }
          final isFirst = _posts == null || _posts?.isEmpty == true;

          final create =
              await (isFirst ? widget.loader.load() : widget.loader.loadNext());

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

          _posts = widget.loader.elements;
          _showHeader = widget.loader.firstPage.pageInfo != null;
        },
        builder: (context, _, bool hasError) {
          if ((_posts?.isEmpty ?? true) && hasError) {
            return AppOnErrorReloadExpanded(
              onReloadPressed: () {
                _posts = null;
                AppFuturePageState? appFuturePageState =
                    _pageKey.currentState as AppFuturePageState<dynamic>?;
                appFuturePageState?.reload(hideContent: true);
              },
            );
          }
          return ListView.builder(
            key: widget.pageStorageKey,
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
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
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(40),
          ),
          child: IconButton(
            onPressed: _closePost,
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
        ),
        builder: (BuildContext context, Widget? child) {
          return child != null
              ? Positioned(
                  bottom: 10 - 100 * _animationController.value,
                  right: 10,
                  child: child,
                )
              : SizedBox();
        },
      )
    ]);
  }

  @override
  bool wantKeepAlive = true;
}
