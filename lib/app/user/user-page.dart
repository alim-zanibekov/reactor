import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactor/core/widgets/onerror-reload.dart';

import '../../core/api/api.dart';
import '../../core/auth/auth.dart';
import '../../core/content/post-loader.dart';
import '../../core/parsers/types/module.dart';
import '../common/future-page.dart';
import '../common/tabs-wrapper.dart';
import '../home.dart';
import '../post/post-list.dart';
import 'user-awards.dart';
import 'user-comments-page.dart';
import 'user-main-tags.dart';
import 'user-rating.dart';
import 'user-short.dart';
import 'user-stats.dart';
import 'user-tags.dart';

class AppUserPage extends StatefulWidget {
  final String username;
  final String link;
  final bool main;

  const AppUserPage({
    Key? key,
    required this.username,
    required this.link,
    this.main = false,
  }) : super(key: key);

  @override
  _AppUserPageState createState() => _AppUserPageState();
}

class _AppUserPageState extends State<AppUserPage>
    with AutomaticKeepAliveClientMixin {
  late PostLoader _loaderUserPosts;
  late PostLoader _loaderUserFavorite;
  PostLoader? _loaderUserSubs;

  @override
  void initState() {
    _loaderUserPosts = PostLoader(path: widget.link, user: true);
    _loaderUserFavorite = PostLoader(favorite: widget.link);
    if (widget.main) {
      _loaderUserSubs = PostLoader(subscriptions: true);
    }
    super.initState();
  }

  @override
  void dispose() {
    _loaderUserPosts.destroy();
    _loaderUserPosts.destroy();
    _loaderUserSubs?.destroy();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => widget.main;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AppTabsWrapper(
      tabs: [
        'Профиль',
        'Комментарии',
        'Посты',
        'Закладки',
        if (widget.main) 'Подписки'
      ],
      title: widget.username,
      actions: <Widget>[
        Builder(
          builder: (context) => PopupMenuButton(
            offset: const Offset(0, 100),
            icon: const Icon(Icons.more_vert),
            tooltip: 'Меню профиля',
            onSelected: (dynamic selected) {
              if (selected == 0) {
                Clipboard.setData(
                  ClipboardData(
                      text: 'http://joyreactor.cc/user/${widget.link}'),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Скопировано')),
                );
              } else {
                Auth().logout();
                AppPages.appBottomBarPage.add(AppBottomBarPage.PROFILE);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(child: Text('Скопировать ссылку'), value: 0),
              if (widget.main)
                const PopupMenuItem(child: Text('Выход'), value: 1),
            ],
          ),
        )
      ],
      builder:
          (BuildContext context, int index, onScrollChange, onReloadPress) {
        if (index == 0)
          return _AppUserLoader(
              key: PageStorageKey<String>(widget.username + index.toString()),
              username: widget.username,
              link: widget.link,
              reloadNotifier: onReloadPress,
              onScrollChange: onScrollChange);
        if (index == 1)
          return AppUserCommentsPage(
              key: PageStorageKey<String>(widget.username + index.toString()),
              username: widget.username,
              reloadNotifier: onReloadPress,
              onScrollChange: onScrollChange);
        if (index == 2)
          return AppPostList(
            pageStorageKey:
                PageStorageKey<String>(widget.username + index.toString()),
            onScrollChange: onScrollChange,
            reloadNotifier: onReloadPress,
            loader: _loaderUserPosts,
          );

        if (index == 3)
          return AppPostList(
            pageStorageKey:
                PageStorageKey<String>(widget.username + index.toString()),
            onScrollChange: onScrollChange,
            reloadNotifier: onReloadPress,
            loader: _loaderUserFavorite,
          );

        return AppPostList(
          pageStorageKey:
              PageStorageKey<String>(widget.username + index.toString()),
          onScrollChange: onScrollChange,
          reloadNotifier: onReloadPress,
          loader: _loaderUserSubs!,
        );
      },
    );
  }
}

class _AppUserLoader extends StatefulWidget {
  final String username;
  final String link;
  final void Function(double delta)? onScrollChange;
  final ChangeNotifier? reloadNotifier;

  _AppUserLoader(
      {Key? key,
      required this.username,
      required this.link,
      this.onScrollChange,
      this.reloadNotifier})
      : super(key: key);

  @override
  _AppUserLoaderState createState() => _AppUserLoaderState();
}

class _AppUserLoaderState extends State<_AppUserLoader>
    with AutomaticKeepAliveClientMixin {
  final _pageKey = GlobalKey();
  ScrollController? _scrollController;
  double _scrollPrevious = 0;

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController!.addListener(() {
      if (widget.onScrollChange != null) {
        widget.onScrollChange!(_scrollController!.offset - _scrollPrevious);
      }
      _scrollPrevious = _scrollController!.offset;
    });
    widget.reloadNotifier?.addListener(_reload);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController!.dispose();
    widget.reloadNotifier?.removeListener(_reload);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _reload() {
    _scrollController!.jumpTo(0);
    Future.microtask(() {
      AppFuturePageState? appFuturePageState =
          _pageKey.currentState as AppFuturePageState<dynamic>?;
      appFuturePageState?.reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AppFuturePage<UserFull>(
      key: _pageKey,
      load: (_) => Api().loadUserPage(widget.link),
      builder: (context, user, _) {
        return OrientationBuilder(
          builder: (context, orientation) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              controller: _scrollController,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: user != null
                    ? AppUser(
                        user: user,
                        onScrollChange: widget.onScrollChange,
                      )
                    : AppOnErrorReload(
                        text: 'Не удалось загрузить страницу',
                        onReloadPressed: () {
                          _reload();
                        },
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class AppUser extends StatefulWidget {
  final UserFull user;
  final void Function(double delta)? onScrollChange;

  const AppUser({Key? key, required this.user, this.onScrollChange})
      : super(key: key);

  @override
  _AppUserState createState() => _AppUserState();
}

class _AppUserState extends State<AppUser> {
  final _defaultPadding = EdgeInsets.only(left: 8, right: 8);
  late TextStyle _textStyle;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    _textStyle = DefaultTextStyle.of(context).style;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: _defaultPadding,
            child: AppShortUser(user: user.toShort(), size: 50),
          ),
          const Divider(),
          Padding(
            padding: _defaultPadding,
            child: AppUserAwards(
              awards: user.awards,
            ),
          ),
          Padding(padding: _defaultPadding, child: AppUserRating(user: user)),
          if (user.activeIn != null && user.activeIn!.isNotEmpty)
            _wrapWithTitle(
              'Активный участник',
              AppUserMainTags(
                tags: user.activeIn,
                defaultPadding: _defaultPadding,
              ),
              childPadding: false,
            ),
          if (user.moderating != null && user.moderating!.isNotEmpty)
            _wrapWithTitle('Модерирует', AppUserTags(tags: user.moderating)),
          if (user.subscriptions != null && user.subscriptions!.isNotEmpty)
            _wrapWithTitle('Читает', AppUserTags(tags: user.subscriptions)),
          if (user.ignore != null && user.ignore!.isNotEmpty)
            _wrapWithTitle('Не читает', AppUserTags(tags: user.ignore)),
          if (user.subscriptions != null && user.subscriptions!.isNotEmpty)
            _wrapWithTitle(
              'Темы постов',
              AppUserTags(
                tags: user.tagCloud,
                canHide: false,
              ),
            ),
          _wrapWithTitle('Статистика', AppUserStats(stats: user.stats)),
          const SizedBox(height: 20)
        ],
      ),
    );
  }

  Widget _wrapWithTitle(String title, Widget child, {childPadding = true}) =>
      Column(children: <Widget>[
        Padding(
          padding: _defaultPadding.copyWith(top: 10),
          child: Text(
            title,
            style: _textStyle.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
        ),
        Padding(
          padding: _defaultPadding,
          child: Divider(height: 15),
        ),
        Padding(
          padding: childPadding ? _defaultPadding : EdgeInsets.zero,
          child: child,
        ),
      ], crossAxisAlignment: CrossAxisAlignment.start);
}
