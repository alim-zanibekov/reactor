import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:reactor/main.dart';
import 'package:uni_links/uni_links.dart';

import '../core/auth/auth.dart';
import '../core/common/reload-service.dart';
import '../core/preferences/preferences.dart';
import 'auth/auth.dart';
import 'categories/categories-page.dart';
import 'common/open.dart';
import 'common/page-wrapper.dart';
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

  final Widget? child;

  const AppPages({Key? key, this.child}) : super(key: key);

  @override
  _AppPagesState createState() => _AppPagesState();
}

class _AppPagesState extends State<AppPages> with TickerProviderStateMixin {
  static Future<String?> _initUniLink() =>
      getInitialLink().catchError((e, stack) => null);
  late StreamSubscription<bool> _reloadSubscription;
  final _auth = Auth();
  double _bottomBarHeight = 54.0;
  late List<StreamSubscription> _subscriptions;
  late AnimationController _animationController;
  late TabController _tabController;
  final double _bottomBarMaxHeight = 54.0;

  PageController _pageController =
      PageController(initialPage: 0, keepPage: true);
  bool _authorized = false;

  void _postFrameCallback(context, initLink) {
    goToLink(context, initLink);
  }

  @override
  void initState() {
    _initUniLink().then((link) {
      if (link != null) {
        SchedulerBinding.instance!.addPostFrameCallback(
          (_) => _postFrameCallback(context, link),
        );
      }
    });

    _tabController = TabController(length: 4, vsync: this)
      ..addListener(() {
        _pageController.jumpToPage(_tabController.index);
        _animationController.notifyListeners();
        if (_authorized != _auth.authorized) {
          setState(() {
            _authorized = _auth.authorized;
          });
        }
      });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _animationController.value = 1;
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
        _tabController.animateTo(event.index);
        if (_authorized != _auth.authorized) {
          setState(() {
            _authorized = _auth.authorized;
          });
        }
      }),
      linkStream.listen(
        (link) => goToLink(context, link!),
        onError: (err) {
          print(err);
        },
      )
    ];
    _reloadSubscription = ReloadService.onReload$.stream.listen((bool _) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _subscriptions.forEach((sub) => sub.cancel());
    _pageController.dispose();
    _animationController.dispose();
    _reloadSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final host = Preferences().host;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
          PageWrapper(
            child: AppPage(main: true, key: PageStorageKey('main' + host)),
          ),
          AppCategoriesPage(key: PageStorageKey('common' + host)),
          !_authorized || _auth.username == null
              ? const AppAuthPage()
              : PageWrapper(
                  child: AppUserPage(
                      username: _auth.username!,
                      link: _auth.username!.replaceAll(' ', '+'),
                      main: true,
                      key: PageStorageKey('user' + host)),
                ),
          const AppSettingsPage()
        ],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _animationController,
        builder: (BuildContext context, Widget? child) {
          return SizedBox(
            height: _bottomBarHeight * _animationController.value,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxHeight: _bottomBarMaxHeight,
              child: TabBar(
                controller: _tabController,
                indicatorWeight: 1,
                enableFeedback: false,
                labelColor: ThemeInfo.primaryColor,
                unselectedLabelColor: ThemeInfo.colors.shade200,
                indicatorColor: Colors.transparent,
                tabs: const <Tab>[
                  Tab(
                    icon: Icon(Icons.view_stream),
                  ),
                  Tab(
                    icon: Icon(Icons.category),
                  ),
                  Tab(
                    icon: Icon(Icons.portrait),
                  ),
                  Tab(
                    icon: Icon(Icons.settings),
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
