import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

import 'types/module.dart';
import 'utils.dart';

class StatsParser {
  Stats parse(String content) {
    final parsedPage = parser.parse(content);
    final sidebar = parsedPage.getElementById('sidebar');

    if (sidebar == null) throw Exception("Invalid page without sidebar");

    final tagsWeekBlock = sidebar.querySelector('#blogs_week_content');
    final tagsAllTimeBlock = sidebar.querySelector('#blogs_alltime_content');
    final tags2DayBlock = sidebar.querySelector('#blogs_2days_content');

    final weekTags =
        tagsWeekBlock?.querySelectorAll('tr').map(_parseTag).toList();
    final allTimeTags =
        tagsAllTimeBlock?.querySelectorAll('tr').map(_parseTag).toList();
    final twoDayTags =
        tags2DayBlock?.querySelectorAll('tr').map(_parseTag).toList();

    final comments2DayBlock = sidebar.querySelector('#comments_2days_content');
    final commentsWeekBlock = sidebar.querySelector('#comments_week_content');

    final twoDayComments =
        comments2DayBlock != null ? _parseComments(comments2DayBlock) : null;
    final weekComments =
        commentsWeekBlock != null ? _parseComments(commentsWeekBlock) : null;

    final weekUsersBlock = sidebar.querySelector('#usertop_week_content');
    final monthUsersBlock = sidebar.querySelector('#usertop_month_content');

    final weekUsers =
        weekUsersBlock?.querySelectorAll('.week_top').map(_parseUser).toList();
    final monthUsers =
        monthUsersBlock?.querySelectorAll('.week_top').map(_parseUser).toList();

    final sidebarBlocks = sidebar.querySelectorAll('.sidebar_block');
    final trendsBlock = StatsParser.getBlockByName(sidebarBlocks, 'Тренды');

    final trends =
        trendsBlock?.querySelectorAll('tr').map((e) => _parseTrend(e)).toList();

    return Stats(
      weekComments: weekComments,
      weekTags: weekTags,
      weekUsers: weekUsers?.whereType<StatsUser>().toList(),
      twoDayComments: twoDayComments,
      twoDayTags: twoDayTags,
      monthUsers: monthUsers?.whereType<StatsUser>().toList(),
      allTimeTags: allTimeTags,
      trends: trends,
    );
  }

  ExtendedTag _parseTag(Element element) {
    final tagImg = element.querySelector('img');
    final infoBlock = element.querySelector('small');
    final subscribersDeltaCount = Utils.getNumberInt(infoBlock?.text);
    final link = element.querySelector('a');
    final bool isDelta = infoBlock?.text.contains('+') ?? false;
    var icon = (tagImg?.attributes ?? {})['src'];

    if (icon != null && icon.startsWith('//')) icon = Utils.fulfillUrl(icon);

    if (icon != null && icon.startsWith('/'))
      icon = 'https://joyreactor.cc$icon';

    return ExtendedTag(
      (link?.attributes ?? {})['title'],
      isMain: Tag.parseIsMain((link?.attributes ?? {})['href']),
      prefix: Tag.parsePrefix((link?.attributes ?? {})['href']),
      link: Tag.parseLink((link?.attributes ?? {})['href']),
      icon: icon,
      subscribersCount: !isDelta ? subscribersDeltaCount : null,
      subscribersDeltaCount: isDelta ? subscribersDeltaCount : null,
    );
  }

  IconTag _parseTrend(Element element) {
    final block = element.querySelector('td')!;
    final tagImg = block.querySelector('img');
    final link = block.querySelector('a');
    var icon = (tagImg?.attributes ?? {})['src'];

    if (icon != null && icon.startsWith('//')) icon = Utils.fulfillUrl(icon);

    if (icon != null && icon.startsWith('/'))
      icon = 'https://joyreactor.cc$icon';

    return IconTag(
      (link?.attributes ?? {})['title'],
      isMain: Tag.parseIsMain((link?.attributes ?? {})['href']),
      prefix: Tag.parsePrefix((link?.attributes ?? {})['href']),
      link: Tag.parseLink((link?.attributes ?? {})['href']),
      icon: icon,
    );
  }

  List<StatsComment> _parseComments(Element element) {
    final List<StatsComment> comments = [];

    for (int i = 0; i < element.nodes.length; ++i) {
      final node = element.nodes[i];
      if (node.nodeType == Node.ELEMENT_NODE) {
        Element e = node as Element;
        if (e.localName == 'div') {
          final href =
              (e.querySelector('a')?.attributes ?? {})['href']?.split('#');
          final id = Utils.getNumberInt(href?.last);
          final postId = Utils.getNumberInt(href?.first);
          final rating = Utils.getNumberDouble(element.nodes[i + 1].text);
          final linkElement =
              (element.nodes[i + 2] as Element).querySelector('a');
          final username = linkElement?.text.trim();
          final link = linkElement?.attributes['href']?.split('/').last;
          if (username != null && link != null) {
            comments.add(StatsComment(
              username: username,
              userLink: link,
              rating: rating,
              postId: postId,
              id: id,
            ));
            i += 2;
          }
        }
      }
    }

    return comments;
  }

  StatsUser? _parseUser(Element element) {
    final linkElement = element.querySelector('a');
    final username = linkElement?.text.trim();
    final rating =
        Utils.getNumberDouble(element.querySelector('.weekrating')?.text);
    final link = linkElement?.attributes['href']?.split('/').last;

    if (username != null && link != null) {
      return StatsUser(
        username: username,
        link: link,
        ratingDelta: rating,
      );
    }
    return null;
  }

  static Element? getBlockByName(List<Element> elements, String header) {
    try {
      return elements.firstWhere((element) =>
          element.children.first.text.trim().toLowerCase() ==
          header.toLowerCase().trim());
    } on StateError {
      return null;
    }
  }

  static final numberRegex = RegExp(r'[^\-0-9\.]');
}
