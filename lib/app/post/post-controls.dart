import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/api/types.dart';
import '../../core/auth/auth.dart';
import '../../core/parsers/types/module.dart';

class AppPostControls extends StatefulWidget {
  final Post post;
  final Function onCommentsClick;

  const AppPostControls({
    Key key,
    @required this.post,
    @required this.onCommentsClick,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AppPostControlsState();
  }
}

class _AppPostControlsState extends State<AppPostControls> {
  final _auth = Auth();
  var _loading = false;

  @override
  void initState() {
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

  _toggleFavorite() async {
    if (_loading) return;
    _setLoading();
    try {
      await Api().setFavorite(widget.post.id, !widget.post.favorite);
      widget.post.favorite = !widget.post.favorite;
    } catch (e) {
      Scaffold.of(context).showSnackBar(
        widget.post.favorite
            ? const SnackBar(content: Text('Не удалось удалить из закладок'))
            : const SnackBar(content: Text('Не удалось добавить в закладки')),
      );
    } finally {
      _setNotLoading();
    }
  }

  _vote(VoteType type) async {
    if (widget.post.votedUp || _loading) return;
    _loading = true;
    try {
      final value = await Api().votePost(widget.post.id, type);

      widget.post.votedDown = type == VoteType.DOWN;
      widget.post.votedUp = type == VoteType.UP;
      widget.post.rating = value.left;
      widget.post.canVote = value.right;
      _loading = false;
      if (mounted) setState(() {});
    } on Exception {
      Scaffold.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось проголосовать')),
      );
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(children: <Widget>[
            SizedBox(
              height: 30,
              child: ButtonTheme(
                height: 30.0,
                child: OutlineButton(
                  highlightedBorderColor: Theme.of(context).accentColor,
                  padding: EdgeInsets.only(left: 8, right: 8),
                  onPressed: widget.onCommentsClick,
                  child: Text('Комментарии ${widget.post.commentsCount}'),
                ),
              ),
            ),
            if (_auth.authorized)
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: InkWell(
                  onTap: _toggleFavorite,
                  child: widget.post.favorite
                      ? Icon(
                          Icons.star,
                          color: Theme.of(context).accentColor,
                          size: 22,
                        )
                      : Icon(Icons.star_border, size: 22),
                ),
              )
          ]),
          if (_auth.authorized)
            Row(children: <Widget>[
              if (widget.post.canVote)
                Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => _vote(VoteType.UP),
                    child: widget.post.votedUp
                        ? Icon(Icons.mood, color: Colors.green[600], size: 22)
                        : Icon(Icons.mood, size: 22),
                  ),
                ),
              Text(widget.post?.rating?.toString() ?? '––'),
              if (widget.post.canVote)
                Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: InkWell(
                    onTap: () => _vote(VoteType.DOWN),
                    child: widget.post.votedDown
                        ? Icon(Icons.mood_bad, color: Colors.red[600], size: 22)
                        : Icon(Icons.mood_bad, size: 22),
                  ),
                ),
            ])
          else
            Text(widget.post?.rating?.toString() ?? '––')
        ],
      ),
    );
  }
}
