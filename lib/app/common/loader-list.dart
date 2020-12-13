import 'package:flutter/material.dart';

import '../../core/content/loader.dart';
import '../../core/widgets/onerror-reload.dart';
import '../common/future-page.dart';
import '../tag/tag-header.dart';

class AppLoaderList<T> extends StatefulWidget {
  final void Function(double delta) onScrollChange;
  final PageStorageKey pageStorageKey;
  final Loader<T> loader;
  final ChangeNotifier reloadNotifier;
  final Widget Function(BuildContext context, T element) builder;

  const AppLoaderList({
    Key key,
    @required this.loader,
    this.pageStorageKey,
    this.onScrollChange,
    this.builder,
    this.reloadNotifier,
  }) : super(key: key);

  @override
  _AppLoaderListState createState() => _AppLoaderListState();
}

class _AppLoaderListState<T> extends State<AppLoaderList<T>>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _pageKey = GlobalKey();

  ScrollController _scrollController;
  double _scrollPrevious = 0;

  List<T> _elements;
  bool _showHeader = false;

  bool _isDark;

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_onScrollChange);
    widget.reloadNotifier?.addListener(_reload);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    widget.reloadNotifier?.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    _elements = null;
    _scrollController.jumpTo(0);
    Future.microtask(() {
      AppFuturePageState appFuturePageState = _pageKey.currentState;
      appFuturePageState?.reload();
    });
  }

  void _onScrollChange() {
    widget?.onScrollChange(_scrollController.offset - _scrollPrevious);
    _scrollPrevious = _scrollController.offset;
  }

  Widget _itemBuilder(context, index, error) {
    if (_showHeader && index == 0) {
      return AppTagHeader(
        pageInfo: widget.loader.firstPage.pageInfo,
        onBlock: () {
          _elements = null;
          AppFuturePageState appFuturePageState = _pageKey.currentState;
          appFuturePageState?.reload();
        },
      );
    }
    if (_showHeader) index = index - 1;
    if (index < _elements.length) {
      return widget.builder(context, _elements[index]);
    } else {
      if (error) {
        return AppOnErrorReloadExpanded(
          onReloadPressed: () {
            AppFuturePageState appFuturePageState = _pageKey.currentState;
            appFuturePageState?.reload(hideContent: true);
          },
        );
      }
      if (widget.loader.complete) {
        return Container(
          color: _isDark ? Colors.black26 : Colors.grey[200],
          padding: EdgeInsets.all(10),
          child: Center(
            child: Text(
              _elements.isNotEmpty ? 'Больше тут ничего нет' : 'Тут ничего нет',
            ),
          ),
        );
      }

      AppFuturePageState appFuturePageState = _pageKey.currentState;
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
    return AppFuturePage<void>(
      customError: true,
      key: _pageKey,
      load: (fromUser) async {
        if (fromUser) {
          _elements = null;
          widget.loader.reset();
        }
        final isFirst = _elements == null || _elements.isEmpty;

        await (isFirst ? widget.loader.load() : widget.loader.loadNext());

        if (isFirst && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }

        _elements = widget.loader.elements;
        _showHeader = widget.loader?.firstPage?.pageInfo != null;
      },
      builder: (context, _, bool hasError) {
        if (_elements == null && hasError) {
          return AppOnErrorReloadExpanded(
            onReloadPressed: () {
              _elements = null;
              AppFuturePageState appFuturePageState = _pageKey.currentState;
              appFuturePageState?.reload(hideContent: true);
            },
          );
        }
        return ListView.builder(
          key: widget.pageStorageKey,
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          itemBuilder: (ctx, i) => _itemBuilder(ctx, i, hasError),
          itemCount: _elements.length + (_showHeader ? 2 : 1),
        );
      },
    );
  }

  @override
  bool wantKeepAlive = true;
}
