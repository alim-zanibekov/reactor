import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

import 'stats-parser.dart';
import 'types/module.dart';
import 'utils.dart';

class UserParser {
  UserFull parse(String content, String link) {
    final parsedPage = parser.parse(content);
    final sidebar = parsedPage.getElementById('sidebar');
    if (sidebar == null) throw Exception('Invalid page');

    final userBlock = sidebar.querySelector('.user');
    final avatar = userBlock?.querySelector('img')?.attributes['src'];
    final username = userBlock?.querySelector('span')?.text.trim();

    final awards = sidebar
        .querySelectorAll('.user-awards .award')
        .map((e) => Award(
            icon: e.attributes['src'],
            title: e.attributes['title']?.trim(),
            id: int.tryParse(e.attributes['src']?.split('/').last ?? '')))
        .toList();
    final stars = sidebar.querySelectorAll('.stars .star-0').length;

    final ratingBlock = sidebar.querySelector('#rating-text');
    final tag = ratingBlock?.querySelector('a')?.text.trim();

    final mainTag = tag != null ? Tag(tag) : null;
    final rating =
        Utils.getNumberDouble(ratingBlock?.querySelector('b')?.text ?? '0');

    final ratingWeekDelta =
        Utils.getNumberDouble(ratingBlock?.querySelector('div')?.text ?? '0');

    final sidebarBlocks = sidebar.querySelectorAll('.sidebar_block');
    final activeInBlock =
        StatsParser.getBlockByName(sidebarBlocks, 'Активный участник');

    final activeIn = activeInBlock?.querySelectorAll('.blogs tr').map((e) {
      final tagImg = e.querySelector('img');
      final infoBlock = e.querySelector('small');
      final rating = Utils.getNumberDouble(infoBlock?.nodes.first.text);
      final ratingWeekDelta =
          Utils.getNumberDouble(infoBlock?.querySelector('div')?.text);
      final link = e.querySelector('a');
      var icon = (tagImg?.attributes ?? {})['src'];
      if (link == null) throw Exception('Invalid tag');

      if (icon != null && icon.startsWith('//')) icon = Utils.fulfillUrl(icon);

      if (icon != null && icon.startsWith('/'))
        icon = 'https://joyreactor.cc$icon';

      return UserTag(
        link.text,
        isMain: Tag.parseIsMain(link.attributes['href']),
        prefix: Tag.parsePrefix(link.attributes['href']),
        link: Tag.parseLink(link.attributes['href']),
        icon: icon,
        rating: rating,
        ratingWeekDelta: ratingWeekDelta,
      );
    }).toList();

    final moderatingBlock =
        StatsParser.getBlockByName(sidebarBlocks, 'Модерирует');
    final moderating = _parseTags(moderatingBlock);

    final readingBlock = StatsParser.getBlockByName(sidebarBlocks, 'Читает');
    final subscriptions = _parseTags(readingBlock);

    final ignoreBlock = StatsParser.getBlockByName(sidebarBlocks, 'Не любит');
    final ignore = _parseTags(ignoreBlock);

    final tagCloud = _parseWeightedTags(sidebar.querySelector('#tagcloud'));
    final profileBlock = StatsParser.getBlockByName(sidebarBlocks, 'Профиль');
    final profileText = profileBlock?.text ?? '';
    final bestPostCount =
        int.tryParse(_bestCountRegex.firstMatch(profileText)?.group(1) ?? '');
    final goodPostCount =
        int.tryParse(_goodCountRegex.firstMatch(profileText)?.group(1) ?? '');
    final postCount =
        int.tryParse(_postsCountRegex.firstMatch(profileText)?.group(1) ?? '');
    final commentsCount = int.tryParse(
        _commentsCountRegex.firstMatch(profileText)?.group(1) ?? '');
    final daysCount =
        int.tryParse(_daysCountRegex.firstMatch(profileText)?.group(1) ?? '');
    final lastEnterArr = _lastEnterRegex.firstMatch(profileText)?.group(1);
    DateTime? lastEnter;
    if (lastEnterArr != null) {
      lastEnter = DateTime.parse(lastEnterArr);
    }

    if (username == null) {
      throw Exception('Couldn\'t parse username');
    }

    return UserFull(
      avatar: avatar,
      link: link,
      username: username,
      stars: stars,
      awards: awards,
      mainTag: mainTag,
      rating: rating,
      ratingWeekDelta: ratingWeekDelta,
      activeIn: activeIn,
      moderating: moderating,
      subscriptions: subscriptions,
      ignore: ignore,
      tagCloud: tagCloud,
      stats: UserStats(
        bestPostCount: bestPostCount,
        goodPostCount: goodPostCount,
        postCount: postCount,
        commentsCount: commentsCount,
        daysCount: daysCount,
        lastEnter: lastEnter,
      ),
    );
  }

  List<Tag> _parseTags(Element? element) =>
      (element?.querySelectorAll('a') ?? [])
          .map((e) => Tag(
                e.text.trim(),
                isMain: Tag.parseIsMain(e.attributes['href']),
                prefix: Tag.parsePrefix(e.attributes['href']),
                link: Tag.parseLink(e.attributes['href']),
              ))
          .toList();

  List<UserTag> _parseWeightedTags(Element? element) =>
      (element?.querySelectorAll('a') ?? [])
          .map((e) => UserTag(
                e.text.trim(),
                weight: Utils.getNumberDouble(e.attributes['style']),
                isMain: Tag.parseIsMain(e.attributes['href']),
                prefix: Tag.parsePrefix(e.attributes['href']),
                link: Tag.parseLink(e.attributes['href']),
              ))
          .toList();

  static final _postsCountRegex = RegExp(r'Постов:\s+([0-9]+)', unicode: true);
  static final _bestCountRegex = RegExp(r'лучших:\s+([0-9]+)', unicode: true);
  static final _goodCountRegex = RegExp(r'хороших:\s+([0-9]+)', unicode: true);
  static final _commentsCountRegex =
      RegExp(r'Комментариев:\s+([0-9]+)', unicode: true);
  static final _lastEnterRegex =
      RegExp(r'Последний раз заходил:\s+([0-9\-]+)', unicode: true);
  static final _daysCountRegex =
      RegExp(r'Дней подряд:\s+([0-9]+)', unicode: true);
}
