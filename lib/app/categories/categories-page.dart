import 'package:flutter/material.dart';

import '../../app/categories/comments.dart';
import '../../app/categories/users.dart';
import '../../core/api/api.dart';
import '../../core/parsers/types/module.dart';
import '../common/future-page.dart';
import 'main.dart';
import 'tags.dart';

class AppCategoriesPage extends StatefulWidget {
  const AppCategoriesPage({Key? key}) : super(key: key);

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
      appBar: AppBar(title: const Text('Разное')),
      body: AppFuturePage<Stats>(
        load: (_) => Api().loadSidebar(),
        builder: (context, stats, _) {
          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Column(children: <Widget>[
                  ..._title('Основные разделы'),
                  const AppCategoriesMain(),
                ]),
              ),
              if (stats?.trends != null)
                SliverToBoxAdapter(child: _trends(stats!.trends!)),
              if (stats?.twoDayTags != null)
                SliverToBoxAdapter(child: _tags(stats!, stats.twoDayTags!)),
              if (stats?.twoDayComments != null)
                SliverToBoxAdapter(
                    child: _comments(stats!, stats.twoDayComments!)),
              if (stats?.weekUsers != null)
                SliverToBoxAdapter(child: _users(stats!, stats.weekUsers!)),
            ],
          );
        },
      ),
    );
  }

  Widget _tags(Stats stats, List<ExtendedTag> twoDayTags) {
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
          height: twoDayTags.length * 60.0,
          child: TabBarView(
            children: <Widget>[
              AppCategoriesTags(tags: twoDayTags),
              if (stats.weekTags != null)
                AppCategoriesTags(tags: stats.weekTags ?? const []),
              if (stats.weekTags != null)
                AppCategoriesTags(tags: stats.allTimeTags ?? const []),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _comments(Stats stats, List<StatsComment> twoDayComments) {
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
          height: twoDayComments.length * 40.0,
          child: TabBarView(
            children: <Widget>[
              AppCategoriesComments(comments: twoDayComments),
              if (stats.weekComments != null)
                AppCategoriesComments(comments: stats.weekComments ?? const []),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _trends(List<IconTag> trends) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          ..._title('Тренды'),
          SizedBox(
            height: trends.length * 60.0,
            child: AppCategoriesTags(
              tags: trends
                  .map((e) => ExtendedTag(
                        e.value,
                        icon: e.icon,
                        link: e.link,
                        isMain: e.isMain,
                        prefix: e.prefix,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _users(Stats stats, List<StatsUser> weekUsers) {
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
          height: weekUsers.length * 40.0,
          child: TabBarView(
            children: <Widget>[
              AppCategoriesUsers(users: weekUsers),
              if (stats.monthUsers != null)
                AppCategoriesUsers(users: stats.monthUsers ?? const []),
            ],
          ),
        ),
      ]),
    );
  }

  List<Widget> _title(String title) {
    return [
      Container(
        padding: _defaultPadding.copyWith(top: 10, bottom: 10),
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
        ),
      ),
      Padding(padding: _defaultPadding, child: Divider(height: 0)),
    ];
  }

  @override
  bool get wantKeepAlive => true;
}
