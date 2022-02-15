import 'dart:io';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../core/api/api.dart';
import '../../core/auth/auth.dart';
import '../../core/common/snack-bar.dart';
import '../../core/parsers/types/module.dart';
import '../../core/widgets/fade-icon.dart';
import '../comments/comment-answer.dart';
import '../comments/comments.dart';
import '../common/future-page.dart';
import 'post.dart';

class AppOnePostPage extends StatefulWidget {
  final Post? post;
  final int? postId;
  final Function? loadContent;
  final bool scrollToComments;
  final int? commentId;

  AppOnePostPage({
    Key? key,
    this.post,
    this.postId,
    this.loadContent,
    this.scrollToComments = false,
    this.commentId,
  }) : super(key: key) {
    assert(postId == null && post != null || postId != null && post == null);
  }

  @override
  _AppOnePostPageState createState() => _AppOnePostPageState();
}

class _AppOnePostPageState extends State<AppOnePostPage> {
  static final _auth = Auth();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final ScrollController _controller = ScrollController();
  GlobalKey _pageKey = GlobalKey();
  Post? _post;
  bool needScroll = false;

  @override
  void initState() {
    needScroll = widget.commentId != null;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color? _getColor(int commentId) {
    if (commentId == widget.commentId) {
      return Theme.of(context).colorScheme.secondary.withOpacity(0.2);
    }
    return null;
  }

  void _loadComments() {
    _post!.comments = null;
    AppFuturePageState? appFuturePageState =
        _pageKey.currentState as AppFuturePageState<dynamic>?;
    appFuturePageState?.reload(withoutIndicator: true);
  }

  Widget _list() {
    List<Widget> children = [];
    late List<AppComment> comments;
    if (_post?.comments == null) {
      children.add(SizedBox(
        height: MediaQuery.of(context).size.height,
        child: FadeIcon(
          key: ObjectKey(_post!.dateTime),
          icon: Icon(Icons.speaker_notes, color: Colors.grey[500], size: 44),
        ),
      ));
    } else {
      comments = AppComments.getCommentsList(
        comments: _post?.comments ?? [],
        showAnswer: true,
        goTo: (e) {
          int i = comments.indexWhere((element) => element.comment.id == e);
          _itemScrollController.scrollTo(
              index: i + 1,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut);
        },
        reload: _loadComments,
        getColor: _getColor,
      );
      _post!.commentsCount = comments.length;

      children = [
        ...comments,
        if (_auth.authorized)
          AppCommentAnswer(
            comment: PostComment(postId: _post!.id, id: 0, depth: 0),
            onSend: _loadComments,
          )
      ];
    }

    int? initialScrollIndex;

    if (needScroll) {
      needScroll = false;
      int i = comments
          .indexWhere((element) => element.comment.id == widget.commentId);
      initialScrollIndex = i + 1;
    }

    return ScrollablePositionedList.builder(
      physics: const ClampingScrollPhysics(),
      itemCount: children.length + 1,
      initialScrollIndex:
          initialScrollIndex ?? (widget.scrollToComments ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return AppPostContent(
            key: ObjectKey(_post),
            post: _post!,
            onPage: true,
            loadContent: () async {
              try {
                widget.loadContent?.call();
                final post = await Api().loadPostContent(_post!.id);
                _post = post;
                if (mounted) setState(() {});
              } on Exception {
                SnackBarHelper.show(
                  context,
                  'Не удалось загрузить содержимое поста',
                );
              }
            },
          );
        }
        return children[index - 1];
      },
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppBar(
            primary: Platform.isIOS,
            // https://github.com/flutter/flutter/issues/70165
            title: const Text('Пост'),
          ),
          Expanded(
            child: AppFuturePage(
              key: _pageKey,
              load: (fromUser) async {
                if (fromUser) {
                  _post =
                      await Api().loadPost(widget.postId ?? widget.post!.id);
                  return;
                }
                if (_post == null) {
                  if (widget.postId == null) {
                    _post = widget.post;
                  } else {
                    _post =
                        await Api().loadPost(widget.postId ?? widget.post!.id);
                  }
                }
                if (_post?.comments == null) {
                  _post!.comments = await Api().loadComments(_post!.id);
                }
              },
              builder: (context, dynamic value, hasError) => _list(),
            ),
          ),
        ],
      ),
    );
  }
}
