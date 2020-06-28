import 'package:flutter/material.dart';

import '../../app/categories/comments.dart';
import '../../app/categories/users.dart';
import '../../core/api/api.dart';
import '../../core/content/types/module.dart';
import '../common/future-page.dart';
import 'main.dart';
import 'tags.dart';

class AppCategoriesPage extends StatefulWidget {
  const AppCategoriesPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppCategoriesPageState();
}

class _AppCategoriesPageState extends State<AppCategoriesPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _defaultPadding = EdgeInsets.only(left: 8, right: 8);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Разное'),
      ),
      body: AppFuturePage<Stats>(
        load: (_) => Api().loadSidebar(),
        builder: (context, stats, _) {
          return CustomScrollView(
            physics: ClampingScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Column(children: <Widget>[
                  ..._title('Основные разделы'),
                  const AppCategoriesMain()
                ]),
              ),
              SliverToBoxAdapter(child: _trends(stats)),
              SliverToBoxAdapter(child: _tags(stats)),
              SliverToBoxAdapter(child: _comments(stats)),
              SliverToBoxAdapter(child: _users(stats)),
            ],
          );
        },
      ),
    );
  }

  Widget _tags(Stats stats) {
    return DefaultTabController(
      length: 3,
      child: Column(children: <Widget>[
        ..._title('Наши любимые теги'),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: TabBar(
            labelPadding: EdgeInsets.symmetric(vertical: 10),
            tabs: <Widget>[Text('2 дня'), Text('Неделя'), Text('Все время')],
          ),
        ),
        SizedBox(
          height: stats.twoDayTags.length * 60.0,
          child: TabBarView(children: <Widget>[
            AppCategoriesTags(tags: stats.twoDayTags),
            AppCategoriesTags(tags: stats.weekTags),
            AppCategoriesTags(tags: stats.allTimeTags)
          ]),
        ),
      ]),
    );
  }

  Widget _comments(Stats stats) {
    return DefaultTabController(
      length: 2,
      child: Column(children: <Widget>[
        ..._title('Топ комментов'),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: TabBar(
            labelPadding: EdgeInsets.symmetric(vertical: 10),
            tabs: <Widget>[Text('2 дня'), Text('Неделя')],
          ),
        ),
        SizedBox(
          height: stats.twoDayComments.length * 40.0,
          child: TabBarView(children: <Widget>[
            AppCategoriesComments(comments: stats.twoDayComments),
            AppCategoriesComments(comments: stats.weekComments)
          ]),
        ),
      ]),
    );
  }

  Widget _trends(Stats stats) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          ..._title('Тренды'),
          SizedBox(
            height: stats.trends.length * 60.0,
            child: AppCategoriesTags(
              tags: stats.trends
                  .map((e) => ExtendedTag(e.value,
                      icon: e.icon,
                      link: e.link,
                      isMain: e.isMain,
                      prefix: e.prefix))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _users(Stats stats) {
    return DefaultTabController(
      length: 2,
      child: Column(children: <Widget>[
        ..._title('Топ пользователей'),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: TabBar(
            labelPadding: EdgeInsets.symmetric(vertical: 10),
            tabs: <Widget>[Text('Неделя'), Text('Месяц')],
          ),
        ),
        SizedBox(
          height: stats.weekUsers.length * 40.0,
          child: TabBarView(children: <Widget>[
            AppCategoriesUsers(users: stats.weekUsers),
            AppCategoriesUsers(users: stats.monthUsers)
          ]),
        ),
      ]),
    );
  }

  List<Widget> _title(String title) {
    return [
      Container(
        padding: _defaultPadding.copyWith(top: 10, bottom: 10),
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
      ),
      Padding(padding: _defaultPadding, child: Divider(height: 0))
    ];
  }

  @override
  bool get wantKeepAlive => true;
}
