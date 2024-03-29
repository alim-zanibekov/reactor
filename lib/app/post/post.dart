import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/common/pair.dart';
import '../../core/parsers/types/module.dart';
import '../common/open.dart';
import '../content/content.dart';
import '../extensions/quiz/quiz.dart';
import 'post-controls.dart';
import 'post-parts.dart';
import 'post-tags.dart';

class MountInfo {
  final bool state;
  final Post post;
  final GlobalKey? key;
  final Function collapse;

  MountInfo({
    required this.state,
    required this.post,
    this.key,
    Function? collapse,
  }) : this.collapse = collapse ?? (() {});
}

class AppPostContent extends StatefulWidget {
  final Post post;
  final bool onPage;
  final Duration collapseDuration;
  final Curve collapseCurve;
  final Function loadContent;
  final Function(bool state, double? diff)? onCollapse;
  final Function(MountInfo)? onMountInfo;

  AppPostContent({
    Key? key,
    required this.post,
    required this.loadContent,
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
  late Post _post;
  late AppContentLoader _loader;

  double _postMaxHeight = 500;
  double? _realPostHeight;
  double? _currentMaxHeight;
  late double _width;
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
        } else {
          _currentMaxHeight = _post.height;
        }
        if (widget.onPage) {
          SchedulerBinding.instance.addPostFrameCallback(_postFrameCallback);
        }
      } else {
        SchedulerBinding.instance.addPostFrameCallback(_postFrameCallback);
      }
    }
    widget.onMountInfo?.call(
        MountInfo(state: true, key: _wrapKey, post: _post, collapse: collapse));

    _loader = AppContentLoader(
      content: (!_post.censored && !_post.hidden && !_post.unsafe)
          ? _post.content
          : [],
      onLoad: _onLoad,
    );
    super.initState();
  }

  @override
  void dispose() {
    widget.onMountInfo?.call(MountInfo(state: false, post: _post));

    _loader.destroy();
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
    _width = MediaQuery.of(context).size.width;
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(children: <Widget>[
      Column(
        key: _wrapKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PostTopControls(
            post: _post,
            isDark: _isDark,
            canOpenPost: !widget.onPage,
            loadContent: widget.loadContent,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: AppPostTags(
              key: ObjectKey(_post.tags),
              openTag: (tag) {
                openTag(context, tag);
              },
              tags: _post.tags,
            ),
          ),
          if (!_post.censored && !_post.hidden && !_post.unsafe)
            AnimatedContainer(
              duration: widget.collapseDuration,
              curve: widget.collapseCurve,
              key: _postKey,
              height: _currentMaxHeight,
              child: ClipRect(
                child: AppContent(
                  key: ObjectKey(_post),
                  loader: _loader,
                  children: _post.quiz != null
                      ? <Widget>[
                          Container(
                            color: _isDark ? Colors.black26 : Colors.grey[300],
                            height: 1,
                          ),
                          AppQuiz(
                            quiz: _post.quiz!,
                            quizUpdated: (quiz) {
                              _post.quiz = quiz;
                              if (mounted) setState(() => null);
                            },
                          )
                        ]
                      : null,
                ),
              ),
            )
          else if (_post.censored || _post.unsafe)
            PostUnavailable(
              isDark: _isDark,
              text: _post.censored
                  ? 'Контент запрещен на территории РФ'
                  : 'Контент только для авторизованных пользователей',
            )
          else
            PostHiddenContent(loadContent: widget.loadContent),
          if (_currentMaxHeight != null || _post.expanded)
            PostExpandCollapseButton(
              key: ObjectKey(_post.expanded),
              expanded: _post.expanded,
              isDark: _isDark,
              toggle: _toggle,
            ),
          if (_post.bestComment != null)
            PostBestComment(
              key: ObjectKey(_post.bestComment),
              isDark: _isDark,
              bestComment: _post.bestComment,
            ),
          getPostControls(),
          PostBottomGradient()
        ],
      ),
    ]);
  }

  void _setPostHeight() {
    if (widget.onPage) {
      return;
    }

    bool hasUndefinedSizeImages = _post.content.any(
      (e) => e is ContentUnitImage && (e.width == null || e.height == null),
    );

    if (_realPostHeight! - _postMaxHeight > 300 || hasUndefinedSizeImages) {
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
      _realPostHeight = _postKey.currentContext!.size!.height;
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
    _realPostHeight = _realPostHeight! - heightDiff;
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
      if (_currentMaxHeight!.toInt() != _realPostHeight!.toInt()) {
        _currentMaxHeight = _realPostHeight;
        if (widget.onCollapse != null) {
          widget.onCollapse!(false, null);
        }
      } else {
        _currentMaxHeight = _postMaxHeight;
        if (widget.onCollapse != null && _realPostHeight != null) {
          widget.onCollapse!(true, _realPostHeight! - _postMaxHeight);
        }
      }
    });
  }

  Widget getPostControls() {
    return Column(children: <Widget>[
      Container(
        color: _isDark ? Colors.black26 : Colors.grey[300],
        height: 1,
      ),
      AppPostControls(
        key: ValueKey(
          _post.id.toString() + 'controls' + _post.content.length.toString(),
        ),
        onCommentsClick: () {
          if (!widget.onPage) {
            openPost(
              context,
              _post,
              widget.loadContent,
              scrollToComments: true,
            );
          }
        },
        post: _post,
      )
    ]);
  }
}
