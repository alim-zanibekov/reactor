import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

import '../../core/content/tag-parser.dart';
import '../common/types.dart';
import 'types/module.dart';

class ContentParser {
  Post parsePost(int id, String c) {
    final parsedPage = parser.parse(c);
    return _parse(id, parsedPage.querySelector('.postContainer'), true);
  }

  Post parseInner(int id, String c) {
    final parsedPage = parser.parse(c);
    return _parse(id, parsedPage.body, false);
  }

  Post _parse(int id, Element parsedPage, bool parseComments) {
    final tags = _parseTags(parsedPage);
    final contentBlock = parsedPage.querySelector('.post_content');
    List<ContentUnit> content = [];
    bool censored = false;
    if (contentBlock == null) {
      censored = _isCensored(parsedPage);
    } else {
      content = _parseContent(contentBlock);
    }
    final footer = parsedPage.querySelector('.ufoot');

    final ratingContainer = footer.querySelector('.post_rating');

    final rating = _parseRating(ratingContainer);
    final votedUp =
        ratingContainer.querySelector('.vote-minus.vote-change') != null;
    final votedDown =
        ratingContainer.querySelector('.vote-plus.vote-change') != null;
    final canVote = ratingContainer.querySelector('.vote-plus') != null;
    final comments = parseComments ? _parseComments(parsedPage, id) : null;
    final bestComment = _parseBestCommentElement(parsedPage, id);
    final user = _parseUser(parsedPage);
    final dateTime = _parseDate(parsedPage);
    final favorite = _parseFavorite(parsedPage);
    final commentsCount = int.parse(parsedPage
        .querySelector('.toggleComments')
        .text
        .replaceAll(RegExp(r'[^0-9]+'), ''));

    final hidden =
        (footer.querySelector('.hidden_link a')?.attributes ?? {})['href']
            ?.contains('delete');

    return Post(
        id: id,
        censored: censored,
        tags: tags,
        content: content,
        rating: rating,
        favorite: favorite,
        comments: comments,
        user: user,
        hidden: hidden ?? false,
        votedUp: votedUp,
        votedDown: votedDown,
        canVote: canVote,
        dateTime: dateTime,
        commentsCount: commentsCount,
        bestComment: bestComment);
  }

  ContentPage<Post> parsePage(String c) {
    final parsedPage = parser.parse(c);
    final current = parsedPage.querySelector('.pagination_expanded .current');
    final pageId = current != null
        ? int.tryParse(parsedPage
                .querySelector('.pagination_expanded .current')
                .text) ??
            0
        : 0;

    final pageInfo =
        TagParser.parsePageInfo(parsedPage.getElementById('tagArticle'));

    return ContentPage<Post>(
        authorized:
            parsedPage.querySelector('#topbar .login #settings') != null,
        pageInfo: pageInfo,
        isLast: pageId <= 1,
        content: parsedPage
            .querySelectorAll('.postContainer')
            .map((e) {
              final id = int.tryParse(
                      e.attributes['id'].replaceAll('postContainer', '')) ??
                  0;
              return _parse(id, e, false);
            })
            .where((element) => element != null)
            .toList(),
        id: pageId);
  }

  List<ContentUnit> parseContent(String c) {
    final parsedPage = parser.parse(c);
    return _parseContent(parsedPage.body);
  }

  List<PostComment> parseComments(String c, int postId) {
    final parsedPage = parser.parse(c);
    return _parseCommentsElement(
        parsedPage.querySelector('.comment_list_post'), postId);
  }

  bool _isCensored(Element parsedPage) {
    final img = parsedPage.querySelector('.post_top > img');
    return img != null && img.attributes['alt'] == 'Censorship';
  }

  List<Tag> _parseTags(Element parsedPage) {
    final tags = parsedPage.querySelectorAll('.taglist a');
    return tags.map((tag) {
      final attributes = tag?.attributes ?? {};

      final value = tag.text;
      return Tag(
        value,
        isMain: Tag.parseIsMain(attributes['href']),
        prefix: Tag.parsePrefix(attributes['href']),
        link: Tag.parseLink(attributes['href']),
      );
    }).toList();
  }

  UserShort _parseUser(Element parsedPage) {
    final nick = parsedPage.querySelector('.uhead_nick');
    final img = nick?.querySelector('img');
    final avatar = img.attributes['src'];
    final username = img.attributes['alt'];
    final userLink =
        (nick?.querySelector('a')?.attributes ?? {})['href']?.split('/')?.last;
    return UserShort(avatar: avatar, username: username, link: userLink);
  }

  bool _parseFavorite(Element parsedPage) {
    final favorite = parsedPage.querySelector('.favorite_link');
    if (favorite != null) {
      return favorite.classes.contains('favorite');
    }
    return false;
  }

  DateTime _parseDate(Element parsedPage) {
    final date = parsedPage.querySelector('.date > span');
    final timestamp = int.parse(date.attributes['data-time']);
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  double _parseRating(Element ratingContainer) {
    if (ratingContainer != null) {
      final text = ratingContainer.text.trim();
      return text == '--' ? null : double.tryParse(text);
    }
    return null;
  }

  List<PostComment> _parseComments(Element parsedPage, int postId) {
    final commentsContainer =
        parsedPage.querySelector('.ufoot .comment_list_post');
    return _parseCommentsElement(commentsContainer, postId);
  }

  PostComment _parseBestCommentElement(Element parsedPage, int postId) {
    final commentsContainer =
        parsedPage.querySelector('.post_top .post_comment_list');
    if (commentsContainer != null) {
      final comments = commentsContainer.children;
      final parent = CommentParent();
      HasChildren last = parent;
      int i = 0;
      if (comments.isNotEmpty) {
        comments[0].firstChild.remove();
        comments.forEach((element) {
          final comment = _parseBestComment(element, i++, postId);
          last.children.add(comment);
          last = comment;
        });
        return parent.children[0];
      }
    }
    return null;
  }

  List<PostComment> _parseCommentsElement(
      Element commentsContainer, int postId) {
    PostComment last;
    final parent = CommentParent();
    List<HasChildren> stack = [parent];
    List<Pair<int, Element>> elementsStack =
        commentsContainer.children.reversed.map((e) => Pair(0, e)).toList();
    while (elementsStack.isNotEmpty) {
      final pair = elementsStack.removeLast();
      final child = pair.right;
      if (pair.left != stack.length - 1) {
        while (stack.length > 0 && stack.length - 1 != pair.left) {
          stack.removeLast();
        }
      }

      if (child.classes.contains('comment')) {
        final comment = _parseComment(child, pair.left, postId);
        last = comment;
        stack.last.children.add(comment);
      } else if (child.classes.contains('comment_list') &&
          child.children.isNotEmpty) {
        elementsStack
            .addAll(child.children.reversed.map((e) => Pair(stack.length, e)));
        stack.add(last);
      }
    }

    return parent.children;
  }

  PostComment _parseComment(Element element, int depth, int postId) {
    final time = DateTime.fromMillisecondsSinceEpoch(
        int.parse(element.attributes['timestamp']) * 1000);
    final bottom = element.querySelector('.comments_bottom');
    final avatarElement = bottom.querySelector('.avatar');
    final id = int.parse(element.attributes['id'].replaceFirst('comment', ''));
    final creatorId = int.parse(element?.attributes['userid']);
    final ratingText = bottom.querySelector('.comment_rating')?.text;
    final avatar = avatarElement?.attributes['src'];
    final username = avatarElement?.attributes['alt'];
    final hidden = element.querySelector('.comment_show') != null;
    final usernameElement = bottom.querySelector('.comment_username');
    final userLink =
        (usernameElement?.attributes ?? {})['href']?.split('/')?.last;

    final votedUp = bottom.querySelector('.vote-minus.vote-change') != null;
    final votedDown = bottom.querySelector('.vote-plus.vote-change') != null;
    final canVote = bottom.querySelector('.vote-plus') != null;

    return PostComment(
        id: id,
        postId: postId,
        votedUp: votedUp ?? false,
        votedDown: votedDown ?? false,
        canVote: canVote ?? false,
        time: time,
        rating: double.tryParse(ratingText?.trim() ?? ''),
        hidden: hidden,
        user: UserShort(
            id: creatorId, avatar: avatar, username: username, link: userLink),
        content: !hidden ? _parseContent(element.querySelector('.txt')) : null,
        depth: depth);
  }

  PostComment _parseBestComment(Element element, int depth, int postId) {
    final bottom = element.querySelector('.comments_bottom');
    final avatarElement = bottom.querySelector('.avatar');
    final timestampString = bottom
        .querySelector('.comment_date')
        ?.children[0]
        ?.attributes['data-time'];
    final time = timestampString != null
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(timestampString) * 1000)
        : DateTime.now();
    final id = int.parse(
        (element.querySelector('.comment_link')?.attributes ?? {})['href']
                ?.split('#comment')
                ?.last ??
            '');
    final creatorId = null;
    final ratingText = bottom.querySelector('.post_rating')?.text?.trim();
    final avatar = avatarElement?.attributes['src'];
    final username = avatarElement?.attributes['alt'];
    final hidden = element.querySelector('.comment_show') != null;
    final usernameElement = bottom.querySelector('.comment_username');
    final userLink =
        (usernameElement?.attributes ?? {})['href']?.split('/')?.last;

    return PostComment(
        id: id,
        time: time,
        postId: postId,
        votedUp: false,
        votedDown: false,
        canVote: false,
        rating: double.tryParse(ratingText?.replaceAll('+', '')?.trim() ?? ''),
        hidden: hidden,
        user: UserShort(
            id: creatorId, avatar: avatar, username: username, link: userLink),
        content: !hidden ? _parseContent(element) : null,
        depth: depth);
  }

  ContentUnit _parseImage(Element element) {
    final iFrame = element.querySelector('iframe');
    final youTubeVideo = element.querySelector('.youtube-player');
    final embedHasSrc = iFrame != null &&
        ((iFrame.attributes ?? {})['src']?.isNotEmpty ?? false);

    final coub =
        embedHasSrc && iFrame.attributes['src'].contains('://coub.com/embed/');

    final vimeo =
        embedHasSrc && iFrame.attributes['src'].contains('vimeo.com/video/');

    final soundCloud = embedHasSrc &&
        iFrame.attributes['src'].contains('soundcloud.com/player');

    final gif = element.querySelectorAll('source');
    final image = element.querySelector('img');
    final prettyPhoto = element.querySelector('.prettyPhotoLink');

    if (gif.isNotEmpty) {
      final width = double.parse(gif.first.parentNode.attributes['width']);
      final height = double.parse(gif.first.parentNode.attributes['height']);
      final src = gif.map((e) => e.attributes['src']).toList();
      final srcWebm = src.indexWhere((e) => e.toLowerCase().endsWith('webm'));
      final srcMp4 = src.indexWhere((e) => e.toLowerCase().endsWith('mp4'));

      return ContentUnitGif(
          srcMp4 != -1 ? src[srcMp4] : src[srcWebm], width, height);
    } else if (youTubeVideo != null) {
      return ContentUnitYouTubeVideo(
          youtubeRegex.firstMatch(youTubeVideo.attributes['src']).group(1));
    } else if (coub) {
      return (ContentUnitCoubVideo(iFrame.attributes['src']));
    } else if (vimeo) {
      return (ContentUnitVimeoVideo(iFrame.attributes['src']));
    } else if (soundCloud) {
      return (ContentUnitSoundCloudAudio(iFrame.attributes['src']));
    } else if (image != null) {
      var width = double.tryParse(image.attributes['width']);
      var height = double.tryParse(image.attributes['height']);
      if (height == null || width == null) {
        width = height = null;
      }
      return ContentUnitImage(image.attributes['src'], width, height,
          prettyImageLink:
              prettyPhoto != null ? prettyPhoto.attributes['href'] : null);
    }
    return null;
  }

  List<ContentTextStyle> _extractStyles(List<ContentTextStyle> stack) {
    return Set.of(stack.where((e) => e != null).toList()).toList();
  }

  ContentTextSize _extractTextSize(List<ContentTextSize> stack) {
    return stack.lastWhere((element) => element != null);
  }

  String _extractLink(List<String> links) {
    try {
      return links.lastWhere((element) => element != null);
    } on StateError {
      return null;
    }
  }

  List<ContentUnit> _parseContent(Element content) {
    List<ContentUnit> result = [];
    List<Pair<int, Object>> nodes = content.nodes.reversed
        .map<Pair<int, Object>>((e) => Pair(0, e))
        .toList();
    List<Pair<int, ContentTextSize>> sizes = [Pair(0, ContentTextSize.s12)];
    List<Pair<int, ContentTextStyle>> styles = [
      Pair(0, ContentTextStyle.NORMAL)
    ];
    List<Pair<int, String>> links = [Pair(0, null)];

    while (nodes.isNotEmpty) {
      final pair = nodes.removeLast();
      final node = pair.right;
      if (pair.left < sizes.length - 1) {
        while (sizes.length > 0 && sizes.length - 1 != pair.left) {
          sizes.removeLast();
          styles.removeLast();
          links.removeLast();
        }
      }
      final nextDepth = pair.left + 1;
      if (node is ContentUnitBreak) {
        if (result.isNotEmpty) {
          result.add(node);
        }
      } else if (node is Node && node.nodeType == Node.ELEMENT_NODE) {
        Element element = node;
        if (element.classes.contains('comments_bottom') ||
            element.classes.contains('mainheader') ||
            element.classes.contains('blog_results')) {
          continue;
        }

        if (element.attributes['class'] == 'image') {
          final res = _parseImage(element);
          if (res != null) {
            result.add(res);
          }
        } else if (element.localName == 'br') {
          nodes.add(Pair(nextDepth, ContentUnitBreak(ContentBreak.LINEBREAK)));
        } else if (node.nodes.isNotEmpty) {
          ContentTextSize size;
          ContentTextStyle style;

          if (element.localName == 'h1')
            size = ContentTextSize.s18;
          else if (element.localName == 'h2')
            size = ContentTextSize.s16;
          else if (element.localName == 'h3')
            size = ContentTextSize.s14;
          else if (element.localName == 'h4')
            size = ContentTextSize.s14;
          else if (element.localName == 'h5')
            size = ContentTextSize.s12;
          else if (element.localName == 'h6') size = ContentTextSize.s12;

          if (size != null) {
            style = ContentTextStyle.BOLD;
          } else {
            if (element.localName == 'b' || element.localName == 'strong')
              style = ContentTextStyle.BOLD;
            else if (element.localName == 'i')
              style = ContentTextStyle.ITALIC;
            else if (element.localName == 's' || element.localName == 'strike')
              style = ContentTextStyle.LINE;
            else if (element.localName == 'a')
              style = ContentTextStyle.UNDERLINE;
          }

          final block = BLOCK_NODES.contains(element.localName);

          sizes.add(Pair(nextDepth, size));
          styles.add(Pair(nextDepth, style));
          links.add(Pair(nextDepth,
              (element.localName == 'a') ? element.attributes['href'] : null));

          if (block)
            nodes.add(
                Pair(nextDepth, ContentUnitBreak(ContentBreak.BLOCK_BREAK)));
          nodes.addAll(node.nodes.reversed.map((e) => Pair(nextDepth, e)));
          if (block)
            nodes.add(
                Pair(nextDepth, ContentUnitBreak(ContentBreak.BLOCK_BREAK)));
        }
      } else if (node is Node &&
          node.nodeType == Node.TEXT_NODE &&
          node.text.trim().isNotEmpty) {
        String link = _extractLink(links.map((e) => e.right).toList());
        String text = node.text;
        if (result.isEmpty || result.last is ContentUnitBreak) {
          text = text.trimLeft();
        }
        final size = _extractTextSize(sizes.map((e) => e.right).toList());
        final style = _extractStyles(styles.map((e) => e.right).toList());

        if (link != null) {
          if (redirectRegex.hasMatch(link)) {
            link = Uri.decodeQueryComponent(
                redirectRegex.firstMatch(link).group(1));
          }
          result
              .add(ContentUnitLink(text, link: link, size: size, style: style));
        } else {
          result.add(ContentUnitText(text, size: size, style: style));
        }
      }
    }
    ContentUnit prev;
    final preResult = result.where((e) {
      bool res = e is! ContentUnitBreak ||
          (e is ContentUnitBreak &&
                  (e.value == ContentBreak.BLOCK_BREAK &&
                      prev.value != e.value) ||
              e.value == ContentBreak.LINEBREAK);
      prev = e;
      return res;
    }).toList();

    while (preResult.isNotEmpty && preResult.last is ContentBreak) {
      preResult.removeLast();
    }
    List<ContentUnit<String>> answer = [];

    for (int i = 0; i < preResult.length; ++i) {
      if (preResult[i] is ContentUnitBreak) {
        if (answer.isNotEmpty && answer.last is ContentUnitText) {
          answer.last.value += '\n';
        }
      } else {
        answer.add(preResult[i]);
      }
    }

    if (answer.isNotEmpty && answer.last is ContentUnitText) {
      answer.last.value = answer.last.value.trim();
    }

    return answer;
  }

  static final youtubeRegex = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/ ]{11})',
      caseSensitive: false);

  static final redirectRegex = RegExp(
      r'(?:https?)?:?\/\/(?:joy|[^\/\.]+\.)?reactor.cc\/redirect\?url=([^\&]+)',
      caseSensitive: false);

  static final soundCloudRegex = RegExp(
      'https?:\/\/(?:w\.|www\.|)(?:soundcloud\.com\/)',
      caseSensitive: false);

  static const List<String> TEXT_NODES = [
    'p',
    'span',
    'b',
    's',
    'strike',
    'i',
    'strong',
    'a',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6'
  ];
  static const List<String> BLOCK_NODES = [
    'p',
    'div',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6'
  ];
}
