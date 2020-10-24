import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

import 'types/module.dart';
import 'utils.dart';

class TagParser {
  ContentPage<ExtendedTag> parsePage(String c) {
    final parsedPage = parser.parse(c);
    final current = parsedPage.querySelector('.pagination_expanded .current');
    final pageId = current != null
        ? int.tryParse(parsedPage
                .querySelector('.pagination_expanded .current')
                ?.text) ??
            0
        : 0;

    final pageInfo = parsePageInfo(parsedPage.getElementById('tagArticle'));

    return ContentPage<ExtendedTag>(
      authorized: parsedPage.querySelector('#topbar .login #settings') != null,
      pageInfo: pageInfo,
      isLast: current == null ||
          pageId == 0 ||
          parsedPage.querySelector('.pagination_main.pLeft') != null,
      content: parsedPage
          .getElementsByClassName('blog_list_item')
          .map(_parse)
          .where((element) => element != null)
          .toList(),
      id: pageId,
    );
  }

  ExtendedTag _parse(Element element) {
    final image = (element.querySelector('img')?.attributes ?? {})['src'];
    final tagLink = element.querySelector('.blog_list_name a');

    final nameSplit = tagLink?.text?.split('(') ?? [];
    final name = nameSplit[0]?.trim();
    final count = Utils.getNumberInt(nameSplit[1]) ?? 0;
    final smalls = element.querySelectorAll('.blog_list_name small');
    final commonRating = Utils.getNumberDouble(smalls[0]?.text?.split('/')[0]);
    final subscribersCount = Utils.getNumberInt(smalls[1]?.text);

    return ExtendedTag(
      name,
      icon: image,
      count: count,
      commonRating: commonRating,
      subscribersCount: subscribersCount,
      link: Tag.parseLink((tagLink?.attributes ?? {})['href']),
      prefix: Tag.parsePrefix((tagLink?.attributes ?? {})['href']),
      isMain: Tag.parseIsMain((tagLink?.attributes ?? {})['href']),
    );
  }

  static PageInfo parsePageInfo(Element tagArticle) {
    final blogHeader = tagArticle?.querySelector('#blogHeader');
    if (blogHeader == null) return null;

    final infoMain = blogHeader.querySelectorAll('#blogSubscribers > span');
    final fav = blogHeader.querySelector('#blogFavroiteLinks');
    var image =
        (blogHeader.querySelector('.blog_avatar')?.attributes ?? {})['src'];

    if (image != null && image is String && image.startsWith('/'))
      image = 'http://joyreactor.cc$image';

    final tagIdStr = (fav?.querySelector('a')?.attributes ?? {})['href'];

    int tagId;
    if (tagIdStr != null && _extractTagIdRegex.hasMatch(tagIdStr)) {
      tagId = int.tryParse(_extractTagIdRegex.firstMatch(tagIdStr).group(1));
    }

    return PageInfo(
      icon: image,
      tagId: tagId,
      bg: (tagArticle.querySelector('#contentInnerHeader')?.attributes ??
          {})['src'],
      subscribersCount: Utils.getNumberInt(infoMain[0]?.text),
      count: Utils.getNumberInt(infoMain[1]?.text) ?? 0,
      commonRating: Utils.getNumberDouble(infoMain[2]?.text),
      subscribed: fav?.querySelector('.remove_from_fav') != null,
      blocked: fav?.querySelector('.remove_from_unpopular') != null,
    );
  }

  static final _extractTagIdRegex = RegExp(r'\/favorite/[^\/]+\/([0-9]+)');
}
