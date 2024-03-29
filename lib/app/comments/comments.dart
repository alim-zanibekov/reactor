import 'package:flutter/material.dart';

import '../../app/comments/comment-answer.dart';
import '../../core/api/api.dart';
import '../../core/api/types.dart';
import '../../core/auth/auth.dart';
import '../../core/common/snack-bar.dart';
import '../../core/parsers/types/module.dart';
import '../common/open.dart';
import '../content/content.dart';
import '../user/user-short.dart';

class AppComment extends StatefulWidget {
  final PostComment comment;
  final int depth;
  final Color? color;
  final bool showAnswer;
  final bool showGoToPost;
  final Function? onSend;
  final Function? onDelete;
  final Function? scrollToParent;

  AppComment({
    Key? key,
    required this.depth,
    required this.comment,
    this.onSend,
    this.showAnswer = false,
    this.showGoToPost = false,
    this.color,
    this.onDelete,
    this.scrollToParent,
  }) : super(key: key);

  @override
  _AppCommentState createState() => _AppCommentState();
}

class _AppCommentState extends State<AppComment>
    with SingleTickerProviderStateMixin {
  static final _auth = Auth();
  bool _loading = false;
  Widget? content;
  bool _showAnswer = false;
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late AppContentLoader _loader;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: Duration(milliseconds: 150), vsync: this);
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeIn));

    _loader = AppContentLoader(
        content: (!widget.comment.hidden && widget.comment.content != null)
            ? widget.comment.content!
            : []);
  }

  @override
  void dispose() {
    _controller.dispose();
    _loader.destroy();
    super.dispose();
  }

  _setLoading() {
    _loading = true;
    if (mounted) setState(() {});
  }

  _setNotLoading() {
    _loading = false;
    if (mounted) setState(() {});
  }

  _loadComment() async {
    if (_loading) return;
    _setLoading();

    try {
      final value = await Api().loadComment(widget.comment.id);
      widget.comment.content = value;
      widget.comment.hidden = false;
      _loader = AppContentLoader(content: value);
    } on Exception {
      SnackBarHelper.show(context, 'Не удалось загрузить комментарий');
    } finally {
      _setNotLoading();
    }
  }

  _vote(VoteType type) async {
    if (widget.comment.votedDown || _loading) return;
    _loading = true;
    try {
      final value = await Api().voteComment(widget.comment.id, type);

      widget.comment.votedDown = type == VoteType.DOWN;
      widget.comment.votedUp = type == VoteType.UP;
      widget.comment.rating = value;
      widget.comment.canVote = false;
      _loading = false;
      if (mounted) setState(() {});
    } on Exception {
      SnackBarHelper.show(context, 'Не удалось проголосовать');
      _loading = false;
    }
  }

  void _delete() async {
    if (_loading) return;
    _setLoading();
    try {
      await Api().deleteComment(widget.comment.id);
      widget.comment.deleted = true;
      _loading = false;
      if (widget.onDelete != null) {
        widget.onDelete!();
      }
    } on Exception {
      SnackBarHelper.show(context, 'Не удалось удалить комментарий');
      _setNotLoading();
    }
  }

  Widget _controls() {
    return Row(children: <Widget>[
      if (widget.showGoToPost)
        SizedBox(
          height: 25,
          width: 60,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
            ),
            onPressed: () {
              openPostById(context, widget.comment.postId,
                  commentId: widget.comment.id);
            },
            child: const Text(
              'Перейти',
              style: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            ),
          ),
        ),
      if (widget.onSend != null)
        SizedBox(
          height: 25,
          width: 70,
          child: TextButton(
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 3.0, horizontal: 5.0),
            ),
            onPressed: () {
              setState(() {
                _showAnswer = !_showAnswer;
              });
              if (_showAnswer) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            },
            child: const Text(
              'Ответить',
              style: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            ),
          ),
        ),
      if (widget.showAnswer && widget.comment.user?.username == _auth.username)
        SizedBox(
          height: 25,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(3.0),
            ),
            onPressed: _delete,
            child: const Text(
              'Удалить',
              style: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            ),
          ),
        ),
      const Expanded(child: SizedBox()),
      if (widget.comment.canVote)
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: InkWell(
            onTap: () => _vote(VoteType.UP),
            child: widget.comment.votedUp
                ? Icon(Icons.mood, color: Colors.green[600], size: 18)
                : Icon(Icons.mood, size: 18),
          ),
        ),
      Text(widget.comment.rating?.toString() ?? '––'),
      if (widget.comment.canVote)
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: InkWell(
            onTap: () => _vote(VoteType.DOWN),
            child: widget.comment.votedDown
                ? Icon(Icons.mood_bad, color: Colors.red[600], size: 18)
                : Icon(Icons.mood_bad, size: 18),
          ),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      content = const SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(
            child: CircularProgressIndicator(strokeWidth: 2),
            height: 20.0,
            width: 20.0,
          ),
        ),
      );
    } else {
      if (!widget.comment.hidden && widget.comment.content != null) {
        content = AppContent(
          key: ValueKey(widget.comment.id.toString() + 'content'),
          loader: _loader,
          noHorizontalPadding: true,
        );
      } else if (widget.comment.hidden) {
        content = Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: _loadComment,
            child: const Text('Показать комментарий'),
          ),
        );
      } else {
        content = SizedBox();
      }
    }
    String rating = widget.comment.rating?.toString() ?? '––';

    final comment = ColoredBox(
      color: widget.color ?? Colors.transparent,
      child: Column(children: <Widget>[
        Row(children: <Widget>[
          if (widget.comment.user != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 5, top: 4, left: 8),
              child: AppShortUser(user: widget.comment.user!),
            ),
          if (widget.depth != 0 && widget.scrollToParent != null)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: InkWell(
                onTap: () => widget.scrollToParent?.call(),
                child: const Icon(Icons.keyboard_arrow_up),
              ),
            )
        ], mainAxisAlignment: MainAxisAlignment.spaceBetween),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: content,
        ),
        Padding(
          key: ValueKey(widget.comment.id.toString() + 'bottom'),
          padding: const EdgeInsets.only(top: 5, left: 4, right: 8, bottom: 4),
          child: _auth.authorized
              ? _controls()
              : Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    rating,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.black45,
                    ),
                  ),
                ),
        ),
      ]),
    );

    final depth = widget.depth > 10 ? 10 : widget.depth;

    return Column(
      key: ValueKey(widget.comment.id.toString() + 'comment'),
      children: <Widget>[
        if (depth == 0)
          comment
        else
          Stack(children: <Widget>[
            for (int i = 1; i <= depth; ++i)
              Positioned(
                top: 0,
                bottom: 0,
                left: 15.0 * i,
                child: VerticalDivider(
                  width: 1,
                  color: isDark ? Colors.white38 : Colors.black12,
                ),
              ),
            Padding(
              child: comment,
              padding: EdgeInsets.only(left: 15.0 * depth),
            )
          ]),
        if (_auth.authorized && widget.showAnswer)
          AnimatedBuilder(
            animation: _controller.view,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _heightFactor.value,
                  child: child,
                ),
              );
            },
            child: AppCommentAnswer(
              key: ValueKey(widget.comment.id.toString() + 'answer'),
              onSend: () {
                _showAnswer = false;
                if (widget.onSend != null) {
                  widget.onSend!();
                } else {
                  setState(() {});
                }
              },
              comment: widget.comment,
            ),
          )
      ],
    );
  }
}

class AppComments extends StatefulWidget {
  final List<PostComment?> comments;

  AppComments({
    Key? key,
    required this.comments,
  }) : super(key: key);

  @override
  _AppCommentsState createState() => _AppCommentsState();

  static List<AppComment> getCommentsList({
    required List<PostComment> comments,
    bool showAnswer = false,
    required void Function(int) goTo,
    required Function reload,
    Color? Function(int)? getColor,
  }) {
    final stack = List.of(comments.reversed);
    final depthStack = List.filled(stack.length, 0, growable: true);
    final parentStack = List.filled(stack.length, 0, growable: true);
    final List<AppComment> children = [];

    while (stack.isNotEmpty) {
      final comment = stack.removeLast();
      if (comment.deleted) {
        continue;
      }
      final depth = depthStack.removeLast();
      final parentId = parentStack.removeLast();
      Color? color = getColor != null ? getColor(comment.id) : null;

      children.add(AppComment(
        depth: depth,
        comment: comment,
        color: color,
        showAnswer: showAnswer,
        onSend: reload,
        scrollToParent: () {
          goTo(parentId);
        },
        onDelete: reload,
      ));

      depthStack.addAll(List.filled(comment.children.length, depth + 1));
      parentStack.addAll(List.filled(comment.children.length, comment.id));
      stack.addAll(comment.children.reversed);
    }
    return children.toList();
  }
}

class _AppCommentsState extends State<AppComments> {
  List<Widget> _children = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stack = List.of(widget.comments.reversed);
    final depthStack = List.filled(stack.length, 0, growable: true);
    _children = [];

    while (stack.isNotEmpty) {
      final comment = stack.removeLast()!;
      if (comment.deleted) {
        continue;
      }
      final depth = depthStack.removeLast();

      _children.add(AppComment(
        depth: depth,
        comment: comment,
        showAnswer: false,
      ));

      depthStack.addAll(List.filled(comment.children.length, depth + 1));
      stack.addAll(comment.children.reversed);
    }

    return Container(
      child: Column(children: _children),
    );
  }
}
