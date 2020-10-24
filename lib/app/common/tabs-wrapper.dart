import 'package:flutter/material.dart';

import '../home.dart';

class _ReloadNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

class AppTabsWrapper extends StatefulWidget {
  final String title;
  final bool main;
  final List<String> tabs;
  final List<Widget> actions;
  final int initialIndex;
  final Widget Function(
      BuildContext context,
      int index,
      void Function(double delta) onScrollChange,
      ChangeNotifier onReload) builder;

  const AppTabsWrapper({
    Key key,
    @required this.title,
    @required this.tabs,
    @required this.builder,
    this.main = false,
    this.actions,
    this.initialIndex,
  })  : assert(tabs != null),
        assert(builder != null),
        assert(title != null),
        super(key: key);

  @override
  _AppTabsWrapperState createState() => _AppTabsWrapperState();
}

class _AppTabsWrapperState extends State<AppTabsWrapper>
    with TickerProviderStateMixin {
  double _appBarHeight = 100;
  double _minAppBarHeight = 48;
  double _maxAppBarHeight = 100;
  double _statusBarHeight = 0;
  TabController _tabController;
  List<_ReloadNotifier> _reloadNotifiers;

  @override
  void initState() {
    _reloadNotifiers = widget.tabs.map((_) => _ReloadNotifier()).toList();
    _tabController = TabController(
        initialIndex: widget.initialIndex ?? 0,
        length: widget.tabs.length,
        vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    if (widget.main) {
      AppPages.appBottomBarState.add(AppBottomBarState.VISIBLE);
    }
    _reloadNotifiers.forEach((e) => e.dispose());
    _tabController.dispose();
    super.dispose();
  }

  void _scrollUpdate(double scrollDelta) {
    if (_appBarHeight > _minAppBarHeight &&
        _appBarHeight <= _maxAppBarHeight &&
        scrollDelta > 0) {
      setState(() {
        _appBarHeight -= scrollDelta;
        if (_appBarHeight < _minAppBarHeight) {
          _appBarHeight = _minAppBarHeight;
          if (widget.main)
            AppPages.appBottomBarState.add(AppBottomBarState.HIDDEN);
        }
      });
    } else if (_appBarHeight >= _minAppBarHeight &&
        _appBarHeight < _maxAppBarHeight &&
        scrollDelta < 0) {
      setState(() {
        _appBarHeight -= scrollDelta;
        if (_appBarHeight > _maxAppBarHeight) {
          _appBarHeight = _maxAppBarHeight;
          if (widget.main)
            AppPages.appBottomBarState.add(AppBottomBarState.VISIBLE);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_statusBarHeight == 0) {
      final double statusBarHeight = MediaQuery.of(context).padding.top;
      _statusBarHeight = statusBarHeight;
    }

    return new Container(
        padding: new EdgeInsets.only(top: _statusBarHeight),
        color: Theme.of(context).primaryColor,
        child: DefaultTabController(
          initialIndex: widget.initialIndex ?? 0,
          length: widget.tabs.length,
          child: Scaffold(
            primary: false,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(_appBarHeight),
              child: buildAppBar(context),
            ),
            body: TabBarView(
              controller: _tabController,
              children: widget.tabs
                  .asMap()
                  .map((index, e) => MapEntry(
                        index,
                        widget.builder(context, index, _scrollUpdate,
                            _reloadNotifiers[index]),
                      ))
                  .values
                  .toList(),
            ),
          ),
        ));

//    return ;
  }

  AppBar buildAppBar(BuildContext context) {
    final reloadButton = Padding(
      padding: EdgeInsets.all(10),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          _reloadNotifiers[_tabController.index].notify();
        },
        icon: const Icon(Icons.refresh, size: 22),
      ),
    );

    Widget leading;
    final offset = Offset(0, (_appBarHeight - _maxAppBarHeight) * 1.5);

    if (Navigator.canPop(context) && !widget.main) {
      leading = Transform.translate(
        offset: offset,
        child: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    }

    return AppBar(
      primary: false,
      automaticallyImplyLeading: false,
      leading: leading,
      title: Transform.translate(
        offset: offset,
        child: Text(widget.title ?? ''),
      ),
      actions: <Widget>[
        Transform.translate(
          offset: offset,
          child: Row(children: <Widget>[
            reloadButton,
            if (widget.actions != null) ...widget.actions.map((e) => e)
          ]),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: widget.tabs.map((e) => Tab(text: e ?? '')).toList(),
          ),
        ),
      ),
    );
  }
}
