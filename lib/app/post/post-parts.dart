import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/common/clipboard.dart';
import '../../core/common/menu.dart';
import '../../core/parsers/types/module.dart';
import '../comments/comments.dart';
import '../common/open.dart';
import '../user/user-short.dart';

class PostTopControls extends StatelessWidget {
  static InAppBrowser? browser;

  const PostTopControls({
    Key? key,
    required this.post,
    required this.isDark,
    required this.canOpenPost,
    required this.loadContent,
  }) : super(key: key);

  final Post post;
  final bool isDark;
  final bool canOpenPost;
  final Function? loadContent;

  @override
  Widget build(BuildContext context) {
    final menu = Menu(context, items: [
      MenuItem(
        text: 'Скопировать ссылку',
        onSelect: () => ClipboardHelper.setClipboardData(context, post.link),
      ),
      MenuItem(
        text: 'Открыть в браузере',
        onSelect: () {
          if (browser == null) {
            browser = InAppBrowser();
          }
          browser!.openUrlRequest(
              urlRequest: URLRequest(url: Uri.parse(post.link)));
        },
      ),
      MenuItem(
        text: 'Открыть в системном браузере',
        onSelect: () => launch(post.link),
      ),
    ]);

    return GestureDetector(
      onTap: () {
        if (canOpenPost) {
          openPost(context, post, loadContent);
        }
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(8),
        child: Row(children: <Widget>[
          if (post.user != null)
            AppPostUser(
              user: post.user!,
              dateTime: post.dateTime,
            ),
          PopupMenuButton<int>(
            offset: const Offset(0, 50),
            padding: EdgeInsets.zero,
            tooltip: 'Меню',
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.grey[300] : Colors.black38,
            ),
            itemBuilder: (context) => menu.rawItems,
            onSelected: (index) => menu.process(index),
          )
        ], mainAxisAlignment: MainAxisAlignment.spaceBetween),
      ),
    );
  }
}

class PostBestComment extends StatelessWidget {
  final bool isDark;
  final PostComment? bestComment;

  const PostBestComment({
    Key? key,
    required this.isDark,
    required this.bestComment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Container(
        color: isDark ? Colors.black26 : Colors.grey[300],
        height: 1,
      ),
      Container(
        padding: EdgeInsets.all(8).copyWith(bottom: 0),
        alignment: Alignment.centerLeft,
        child: const Text('Отличный комментарий!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
      SizedBox(
        child: AppComments(
          comments: [bestComment],
        ),
      ),
    ]);
  }
}

class PostUnavailable extends StatelessWidget {
  final bool isDark;
  final String text;

  const PostUnavailable({
    Key? key,
    required this.isDark,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(10),
      height: 100,
      color: isDark ? Colors.black26 : Colors.grey[200],
      child: Column(
        children: <Widget>[
          const Icon(Icons.pan_tool),
          const SizedBox(height: 10),
          Text(
            text,
            textScaleFactor: 1.2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class PostExpandCollapseButton extends StatelessWidget {
  final bool expanded;
  final bool isDark;
  final Function toggle;

  const PostExpandCollapseButton({
    Key? key,
    required this.expanded,
    required this.isDark,
    required this.toggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 35,
      child: DefaultTextStyle(
        style: TextStyle(
          color: isDark ? Colors.white : Colors.grey[100],
        ),
        child: TextButton(
          onPressed: toggle as void Function()?,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(expanded ? 'Свернуть' : 'Развернуть'),
              Icon(expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down)
            ],
          ),
        ),
      ),
    );
  }
}

class PostHiddenContent extends StatefulWidget {
  final Function loadContent;

  const PostHiddenContent({
    Key? key,
    required this.loadContent,
  }) : super(key: key);

  @override
  _PostHiddenContentState createState() => _PostHiddenContentState();
}

class _PostHiddenContentState extends State<PostHiddenContent> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Center(
        child: OutlinedButton(
          onPressed: () => setState(() {
            _loading = true;
            widget.loadContent();
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
    );
  }
}

class PostBottomGradient extends StatelessWidget {
  const PostBottomGradient({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return Container(
        height: 10,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black26,
              Colors.grey[900]!,
              Colors.grey[900]!,
              Colors.grey[900]!,
              Colors.grey[900]!,
              Colors.grey[900]!,
              Colors.grey[900]!,
              Colors.grey[900]!,
              Colors.grey[900]!,
            ],
          ),
          color: Colors.grey[1200],
        ),
      );
    }
    return Container(
      height: 10,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[400]!,
            Colors.grey[300]!,
            Colors.grey[200]!,
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
        ),
        color: Colors.grey[300],
      ),
    );
  }
}
