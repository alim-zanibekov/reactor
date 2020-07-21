import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../core/api/api.dart';
import '../../core/auth/auth.dart';
import '../../core/common/pair.dart';
import '../../core/parsers/types/module.dart';
import '../../core/widgets/fade-icon.dart';
import '../comments/comment-answer.dart';
import '../comments/comments.dart';
import '../common/future-page.dart';
import '../common/open.dart';
import '../content/content.dart';
import '../extensions/quiz/quiz.dart';
import '../user/user-short.dart';
import 'post-controls.dart';
import 'post-tags.dart';

class AppOnePostPage extends StatefulWidget {
  final Post post;
  final int postId;
  final Function loadContent;
  final bool scrollToComments;
  final int commentId;

  AppOnePostPage({
    Key key,
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
  Post _post;
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

  Color _getColor(int commentId) {
    if (commentId == widget.commentId) {
      return Theme.of(context).accentColor.withOpacity(0.2);
    }
    return null;
  }

  void _loadComments() {
    _post.comments = null;
    AppFuturePageState appFuturePageState = _pageKey.currentState;
    appFuturePageState?.reload(withoutIndicator: true);
  }

  Widget _list() {
    List<Widget> children = [];
    List<AppComment> comments;
    if (_post?.comments == null) {
      children.add(SizedBox(
        height: MediaQuery
            .of(context)
            .size
            .height,
        child: FadeIcon(
          key: ObjectKey(_post.dateTime),
          icon: Icon(Icons.speaker_notes, color: Colors.grey[500], size: 44),
        ),
      ));
    } else {
      comments = AppComments.getCommentsList(
        comments: _post.comments,
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
      _post.commentsCount = comments.length;

      children = [
        ...comments,
        if (_auth.authorized)
          AppCommentAnswer(
            comment: PostComment(postId: _post.id, id: 0),
            onSend: _loadComments,
          )
      ];
    }

    int initialScrollIndex;

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
            post: _post,
            onPage: true,
            loadContent: () async {
              try {
                if (widget.loadContent != null) widget.loadContent();

                final post = await Api().loadPostContent(_post.id);
                _post = post;
                if (mounted) setState(() {});
              } on Exception {
                Scaffold.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Не удалось загрзить содержимое поста'),
                  ),
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
      appBar: AppBar(
        title: const Text('Пост'),
      ),
      body: AppFuturePage(
        key: _pageKey,
        load: (fromUser) async {
          if (fromUser) {
            _post = await Api().loadPost(widget.postId ?? widget.post.id);
            return;
          }
          if (_post == null) {
            if (widget.postId == null) {
              _post = widget.post;
            } else {
              _post = await Api().loadPost(widget.postId ?? widget.post.id);
            }
          }
          if (_post.comments == null) {
            _post.comments = await Api().loadComments(_post.id);
          }
        },
        builder: (context, value, hasError) => _list(),
      ),
    );
  }
}

class MountInfo {
  final bool state;
  final GlobalKey key;
  final Post post;
  final Function collapse;

  MountInfo({this.state, this.key, this.post, this.collapse});
}

class AppPostContent extends StatefulWidget {
  final Post post;
  final bool onPage;
  final Duration collapseDuration;
  final Curve collapseCurve;
  final Function(bool state, double diff) onCollapse;
  final Function loadContent;
  final Function(MountInfo) onMountInfo;

  AppPostContent({
    Key key,
    this.post,
    this.loadContent,
    this.onPage = false,
    this.onCollapse,
    this.collapseDuration = Duration.zero,
    this.onMountInfo,
    this.collapseCurve = Curves.easeInOut,
  }) : super(key: key);

  @override
  _AppPostContentState createState() => _AppPostContentState();
}

class _AppPostContentState extends State<AppPostContent>
    with SingleTickerProviderStateMixin {
  final _postKey = GlobalKey();
  final _wrapKey = GlobalKey();
  Post _post;
  double _postMaxHeight = 500;
  double _realPostHeight;
  double _currentMaxHeight;
  double _width;
  bool _loading = false;
  bool _isDark = false;

  @override
  void initState() {
    _realPostHeight = null;
    _post = widget.post;
    if (!_post.censored) {
      if (_post.height != null) {
        _realPostHeight = _post.height;
        if (!_post.expanded) {
          _setPostHeight();
        }
        if (widget.onPage) {
          SchedulerBinding.instance.addPostFrameCallback(_postFrameCallback);
        }
      } else {
        SchedulerBinding.instance.addPostFrameCallback(_postFrameCallback);
      }
    }
    if (widget.onMountInfo != null) {
      widget.onMountInfo(MountInfo(
          state: true, key: _wrapKey, post: _post, collapse: collapse));
    }
    super.initState();
  }

  @override
  void dispose() {
    if (widget.onMountInfo != null) {
      widget.onMountInfo(MountInfo(state: false, post: _post));
    }
    super.dispose();
  }

  void collapse() {
    _post.expanded = false;
    _currentMaxHeight = _postMaxHeight;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _width = MediaQuery
        .of(context)
        .size
        .width;
    _isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return Column(children: <Widget>[
      Column(
        key: _wrapKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          getPostTopControls(),
          getPostTags(),
          if (!_post.censored && !_post.hidden && !_post.unsafe)
            AnimatedContainer(
              duration: widget.collapseDuration,
              curve: widget.collapseCurve,
              key: _postKey,
              height: _currentMaxHeight,
              child: AppContent(
                key: ObjectKey(_post),
                content: _post.content,
                onLoad: _onLoad,
                children: _post.quiz != null
                    ? <Widget>[
                  Container(
                    color: _isDark ? Colors.black26 : Colors.grey[300],
                    height: 1,
                  ),
                  AppQuiz(
                    quiz: _post.quiz,
                    quizUpdated: (quiz) {
                      _post.quiz = quiz;
                      if (mounted) setState(() => null);
                    },
                  )
                ]
                    : null,
              ),
            )
          else
            if (_post.censored || _post.unsafe)
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                height: 100,
                color: _isDark ? Colors.black26 : Colors.grey[200],
                child: Column(
                  children: <Widget>[
                    const Icon(Icons.pan_tool),
                    const SizedBox(height: 10),
                    Text(
                      _post.censored
                          ? 'Контент запрещен на территории РФ'
                          : 'Контент только для авторизованных пользователей',
                      textScaleFactor: 1.2,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(10),
                child: Center(
                  child: OutlineButton(
                    highlightedBorderColor: Theme
                        .of(context)
                        .accentColor,
                    onPressed: () =>
                        setState(() {
                          if (widget.loadContent != null) {
                            _loading = true;
                            widget.loadContent();
                          }
                        }),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: IndexedStack(
                        key: ValueKey<int>(_loading ? 1 : 0),
                        index: _loading ? 1 : 0,
                        children: const <Widget>[
                          Center(child: Text('Показать сдержимое поста')),
                          Center(
                            child: SizedBox(
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                              ),
                              height: 16,
                              width: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          if (_currentMaxHeight != null) getExpandCollapse(),
          if (_post.bestComment != null) getBestComment(),
          getPostControls(),
          getBottomGradient()
        ],
      ),
    ]);
  }

  void _setPostHeight() {
    if (widget.onPage) {
      return;
    }

    bool hasUndefinedSizeImages = _post.content.any(
            (e) =>
        e is ContentUnitImage && (e.width == null || e.height == null));

    if (_realPostHeight - _postMaxHeight > 300 || hasUndefinedSizeImages) {
      _currentMaxHeight = _postMaxHeight;
    } else {
      _currentMaxHeight = null;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _postFrameCallback(duration) {
    if (!mounted) {
      return;
    }
    if (_postKey.currentContext != null) {
      _realPostHeight = _postKey.currentContext.size.height;
      _post.height = _realPostHeight;

      if (!_post.expanded) {
        _setPostHeight();
      } else {
        _currentMaxHeight = _realPostHeight;
      }
    }
  }

  void _onLoad(List<Pair<double, Size>> value) {
    if (value.isEmpty || _realPostHeight == null) {
      return;
    }
    var heightDiff = 0.0;
    value.forEach((e) {
      final oldHeight = _width / e.left;
      final newHeight = _width / (e.right.width / e.right.height);
      heightDiff += oldHeight - newHeight;
    });
    _realPostHeight -= heightDiff;
    _post.height = _realPostHeight;

    if (!_post.expanded) {
      _setPostHeight();
    } else {
      _currentMaxHeight = _realPostHeight;
    }
  }

  void _toggle() {
    setState(() {
      _post.expanded = !_post.expanded;
      if (_currentMaxHeight.toInt() != _realPostHeight.toInt()) {
        _currentMaxHeight = _realPostHeight;
        widget.onCollapse(false, null);
      } else {
        _currentMaxHeight = _postMaxHeight;
        widget.onCollapse(true, _realPostHeight - _postMaxHeight);
      }
    });
  }

  Widget getExpandCollapse() {
    return SizedBox(
      key: ValueKey(_post.id.toString() + 'expand'),
      width: double.infinity,
      height: 35,
      child: FlatButton(
        color: _isDark ? Colors.grey[900] : Colors.grey[100],
        onPressed: _toggle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(_post.expanded ? 'Свернуть' : 'Развернуть'),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(_post.expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down),
            )
          ],
        ),
      ),
    );
  }

  Widget getBottomGradientDark() {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black26,
            Colors.grey[900],
            Colors.grey[900],
            Colors.grey[900],
            Colors.grey[900],
            Colors.grey[900],
            Colors.grey[900],
            Colors.grey[900],
            Colors.grey[900],
          ],
        ),
        color: Colors.grey[1200],
      ),
    );
  }

  Widget getBottomGradient() {
    if (_isDark) {
      return getBottomGradientDark();
    }
    return Container(
      height: 10,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[400],
            Colors.grey[300],
            Colors.grey[200],
            Colors.grey[100],
            Colors.grey[200],
          ],
        ),
        color: Colors.grey[300],
      ),
    );
  }

  Widget getPostControls() {
    return Column(children: <Widget>[
      Container(
        color: _isDark ? Colors.black26 : Colors.grey[300],
        height: 1,
      ),
      AppPostControls(
        key: ValueKey(
            _post.id.toString() + 'controls' + _post.content.length.toString()),
        onCommentsClick: () {
          if (!widget.onPage) {
            openPost(context, _post, widget.loadContent,
                scrollToComments: true);
          }
        },
        post: _post,
      )
    ]);
  }

  Widget getPostTags() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      child: AppPostTags(
        key: ObjectKey(_post.tags),
        openTag: (tag) {
          openTag(context, tag);
        },
        tags: _post.tags,
      ),
    );
  }

  Widget getPostTopControls() {
    return GestureDetector(
      onTap: () {
        if (!widget.onPage) {
          openPost(context, _post, widget.loadContent);
        }
      },
      child: Container(
        key: ObjectKey(_post.user),
        color: Colors.transparent,
        padding: const EdgeInsets.all(8),
        child: Row(children: <Widget>[
          AppPostUser(user: _post.user, dateTime: _post.dateTime),
          copyLinkPopup()
        ], mainAxisAlignment: MainAxisAlignment.spaceBetween),
      ),
    );
  }

  Widget copyLinkPopup() {
    return PopupMenuButton<int>(
      offset: Offset(0, 100),
      padding: EdgeInsets.zero,
      tooltip: 'Меню',
      icon: Icon(
        Icons.more_vert,
        color: _isDark ? Colors.grey[300] : Colors.black38,
      ),
      itemBuilder: (context) =>
      const [
        PopupMenuItem(
          value: 0,
          child: Text('Скопировать ссылку'),
        ),
        PopupMenuItem(
          value: 1,
          child: Text('Открыть в браузере'),
        ),
      ],
      onSelected: (selected) {
        if (selected == 0) {
          Clipboard.setData(ClipboardData(text: _post.link));
          Scaffold.of(context).showSnackBar(
            const SnackBar(content: Text('Скопировано')),
          );
        } else {
          ChromeSafariBrowser().open(url: _post.link);
        }
      },
    );
  }

  Widget getBestComment() {
    return Column(children: <Widget>[
      Container(
        height: 1,
        color: _isDark ? Colors.black26 : Colors.grey[300],
      ),
      Container(
        padding: EdgeInsets.all(8).copyWith(bottom: 0),
        alignment: Alignment.centerLeft,
        child: const Text('Отличный комментарий!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
      SizedBox(
        child: AppComments(
          key: ObjectKey(_post.bestComment),
          comments: [_post.bestComment],
        ),
      ),
    ]);
  }
}
