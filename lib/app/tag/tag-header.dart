import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/common/retry-network-image.dart';
import '../../core/common/snack-bar.dart';
import '../../core/parsers/types/module.dart';
import 'tag.dart';

class AppTagHeader extends StatefulWidget {
  final PageInfo pageInfo;
  final Function? onBlock;
  final String? prefix;

  AppTagHeader({Key? key, required this.pageInfo, this.onBlock, this.prefix})
      : super(key: key);

  @override
  _AppTagHeaderState createState() => _AppTagHeaderState();
}

class _AppTagHeaderState extends State<AppTagHeader> {
  late PageInfo _pageInfo;
  bool _loading = false;

  @override
  void initState() {
    _pageInfo = widget.pageInfo;

    super.initState();
  }

  _setLoading() {
    _loading = true;
    if (mounted) setState(() {});
  }

  _setNotLoading() {
    _loading = false;
    if (mounted) setState(() {});
  }

  _toggleSubscribe() async {
    if (_loading) return;
    _setLoading();

    try {
      await Api().setTagFavorite(_pageInfo.tagId, !_pageInfo.subscribed);
      _pageInfo.subscribed = !_pageInfo.subscribed;
      _pageInfo.blocked = false;
    } on Exception {
      SnackBarHelper.show(
        context,
        _pageInfo.subscribed
            ? 'Не удалось отписаться'
            : 'Не удалось подписаться',
      );
    } finally {
      _setNotLoading();
    }
  }

  _toggleBlock() async {
    if (_loading) return;
    _setLoading();

    try {
      await Api().setTagBlock(_pageInfo.tagId, !_pageInfo.blocked);
      _pageInfo.blocked = !_pageInfo.blocked;
      _pageInfo.subscribed = false;
      if (widget.onBlock != null) {
        widget.onBlock!();
      }
    } on Exception {
      ScaffoldMessenger.of(context).showSnackBar(
        _pageInfo.blocked
            ? const SnackBar(content: Text('Не удалось разблокировать'))
            : const SnackBar(content: Text('Не удалось заблокировать')),
      );
      _setNotLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorBlockState =
        _pageInfo.blocked ? Colors.blue[300] : Colors.red[300];
    return Column(children: <Widget>[
      if (_pageInfo.bg != null)
        AspectRatio(
          aspectRatio: 846.0 / 179.0,
          child: Image(
            fit: BoxFit.cover,
            image: AppNetworkImageWithRetry(_pageInfo.bg!),
          ),
        ),
      Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.centerRight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: AppTag(tag: _pageInfo),
            ),
            if (_loading)
              const SizedBox(
                width: 70,
                height: 60,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 1),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  SizedBox(
                    height: 28,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.only(right: 8, left: 5),
                      ),
                      onPressed: _toggleSubscribe,
                      child: Row(children: <Widget>[
                        Icon(
                          _pageInfo.subscribed ? Icons.remove : Icons.add,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _pageInfo.subscribed ? 'Отписаться' : 'Подписаться',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ], mainAxisSize: MainAxisSize.min),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 28,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(right: 10, left: 10),
                      ),
                      onPressed: _toggleBlock,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(_pageInfo.blocked ? Icons.undo : Icons.block,
                              size: 12, color: colorBlockState),
                          const SizedBox(width: 2),
                          Text(
                            _pageInfo.blocked
                                ? 'Разблокировать'
                                : 'Заблокировать',
                            style:
                                TextStyle(fontSize: 10, color: colorBlockState),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
          ],
        ),
      )
    ]);
  }
}
