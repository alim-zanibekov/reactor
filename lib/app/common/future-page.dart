import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/widgets/onerror-reload.dart';

class AppFuturePage<T> extends StatefulWidget {
  final Widget Function(BuildContext, T?, bool hasError) builder;
  final Future<T> Function(bool fromUser) load;
  final bool customError;

  const AppFuturePage(
      {Key? key,
      required this.builder,
      required this.load,
      this.customError = false})
      : super(key: key);

  @override
  State<AppFuturePage<T>> createState() => AppFuturePageState<T>();
}

class AppFuturePageState<T> extends State<AppFuturePage<T>> {
  final GlobalKey _refreshKey = GlobalKey();
  bool _error = false;
  bool _loading = true;
  bool _fromUser = true;
  bool _lock = false;

  bool get loading => _loading;

  T? _value;

  @override
  void initState() {
    SchedulerBinding.instance!.addPostFrameCallback((_) => reload());
    super.initState();
  }

  Future<dynamic> _load([fromUser = false]) async {
    if (_lock) return;

    _lock = true;
    _error = false;
    if (!widget.customError) _loading = true;
    return widget.load(fromUser).then((v) {
      _value = v;
      _lock = _loading = false;
      if (mounted) setState(() {});
    }).catchError((err, stack) {
      _error = true;
      _lock = _loading = false;
      if (mounted) setState(() {});
      print(err);
      print(stack);
    });
  }

  void reload({bool hideContent = false, bool withoutIndicator = false}) {
    if (withoutIndicator) {
      _load();
    } else {
      _fromUser = false;
      RefreshIndicatorState? refreshIndicatorState =
          _refreshKey.currentState as RefreshIndicatorState?;
      refreshIndicatorState?.show();
    }
    if (hideContent) {
      _loading = true;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (widget.customError) {
      child = _loading ? Container() : widget.builder(context, _value, _error);
    } else if (_error) {
      child = AppOnErrorReloadExpanded(
        onReloadPressed: () => reload(hideContent: true),
      );
    } else {
      child = _loading ? Container() : widget.builder(context, _value, false);
    }

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: () async {
        await _load(_fromUser);
        _fromUser = true;
      },
      child: child,
    );
  }
}
