import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:uni_links/uni_links.dart';

import '../core/auth/auth.dart';
import 'auth/auth.dart';
import 'categories/categories-page.dart';
import 'common/open.dart';
import 'page/posts-page.dart';
import 'settings/settings-page.dart';
import 'user/user-page.dart';

enum AppBottomBarState { VISIBLE, HIDDEN }
enum AppBottomBarPage { MAIN, CATEGORIES, PROFILE, SETTINGS }

final StreamController<AppBottomBarState> _appBottomBarState =
    StreamController<AppBottomBarState>();
final StreamController<AppBottomBarPage> _appBottomBarPage =
    StreamController<AppBottomBarPage>();

class AppPages extends StatefulWidget {
  static StreamSink<AppBottomBarState> get appBottomBarState =>
      _appBottomBarState;

  static StreamSink<AppBottomBarPage> get appBottomBarPage => _appBottomBarPage;

  final Widget child;

  const AppPages({Key key, this.child}) : super(key: key);

  @override
  _AppPagesState createState() => _AppPagesState();
}

class _AppPagesState extends State<AppPages> with TickerProviderStateMixin {
  static Future<String> _initUniLink() =>
      getInitialLink().catchError((e, stack) => null);

  final double _bottomBarMaxHeight = 54.0;
  final _auth = Auth();

  double _bottomBarHeight = 54.0;
  List<StreamSubscription> _subscriptions;
  int _currentIndex = 0;
  AnimationController _animationController;
  PageController pageController;
  bool _authorized = false;

  void _postFrameCallback(context, initLink) {
    goToLink(context, initLink);
  }

  @override
  void initState() {
    _initUniLink().then((link) {
      if (link != null) {
        SchedulerBinding.instance.addPostFrameCallback(
          (_) => _postFrameCallback(context, link),
        );
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _animationController.value = 1;
    pageController = PageController(
      initialPage: 0,
      keepPage: true,
    );
    _authorized = _auth.authorized;
    _subscriptions = [
      _appBottomBarState.stream.listen((event) {
        if (event == AppBottomBarState.VISIBLE) {
          _animationController.animateTo(1, curve: Curves.easeInOut);
        } else {
          _animationController.animateTo(0, curve: Curves.easeInOut);
        }
      }),
      _appBottomBarPage.stream.listen((event) {
        _currentIndex = event.index;
        pageController.jumpToPage(_currentIndex);
        if (_authorized != _auth.authorized) {
          setState(() {
            _authorized = _auth.authorized;
          });
        }
      }),
      getLinksStream().listen((link) => goToLink(context, link),
          onError: (err) {
        print(err);
      })
    ];
    super.initState();
  }

  @override
  void dispose() {
    _subscriptions.forEach((sub) => sub.cancel());
    pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
          const AppPage(main: true),
          const AppCategoriesPage(key: PageStorageKey('common')),
          !_authorized || _auth.username == null
              ? const AppAuthPage()
              : AppUserPage(
                  username: _auth.username,
                  link: null,
                  main: true,
                ),
          const AppSettingsPage()
        ],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _animationController,
        builder: (BuildContext context, Widget child) {
          return SizedBox(
            height: _bottomBarHeight * _animationController.value,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxHeight: _bottomBarMaxHeight,
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                onTap: (index) {
                  if (_currentIndex != index) {
                    pageController.jumpToPage(index);
                    _currentIndex = index;
                    _animationController.notifyListeners();
                    if (_authorized != _auth.authorized) {
                      setState(() {
                        _authorized = _auth.authorized;
                      });
                    }
                  }
                },
                type: BottomNavigationBarType.fixed,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.view_stream),
                    label: 'Лента',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.category),
                    label: 'Разное',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.portrait),
                    label: 'Аккаунт',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Настройки',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
