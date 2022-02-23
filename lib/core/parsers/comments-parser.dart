import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

import './types/module.dart';
import '../common/pair.dart';
import 'content-parser.dart';
import 'utils.dart';

class CommentsParser {
  final _contentParser = ContentParser();

  List<PostComment>? parsePostComments(Element parsedPage, int postId) {
    final commentsContainer =
        parsedPage.querySelector('.ufoot .comment_list_post');
    if (commentsContainer == null) return null;
    return _parseCommentsElement(commentsContainer, postId);
  }

  List<PostComment>? parseComments(String? c, int postId) {
    final parsedPage = parser.parse(c);
    final commentsContainer = parsedPage.querySelector('.comment_list_post');
    if (commentsContainer == null) return null;
    return _parseCommentsElement(commentsContainer, postId);
  }

  PostComment parseComment(Element element, int postId) {
    return _parseComment(element, 0, postId);
  }

  PostComment? parseBestCommentElement(Element parsedPage, int postId) {
    final commentsContainer =
        parsedPage.querySelector('.post_top .post_comment_list');
    if (commentsContainer != null) {
      final comments = commentsContainer.children;
      final parent = CommentParent();
      HasChildren last = parent;
      int i = 0;
      if (comments.isNotEmpty) {
        comments[0].firstChild?.remove();
        comments.forEach((element) {
          final comment = _parseBestComment(element, i++, postId);
          last.children.add(comment);
          last = comment;
        });
        if (parent.children.isNotEmpty) {
          return parent.children.first;
        }
      }
    }
    return null;
  }

  List<PostComment>? _parseCommentsElement(
      Element commentsContainer, int postId) {
    PostComment? last;
    final parent = CommentParent();
    List<HasChildren?> stack = [parent];
    List<Pair<int, Element>> elementsStack =
        commentsContainer.children.reversed.map((e) => Pair(0, e)).toList();
    while (elementsStack.isNotEmpty) {
      final pair = elementsStack.removeLast();
      final child = pair.right;
      if (pair.left != stack.length - 1) {
        while (stack.isNotEmpty && stack.length - 1 != pair.left) {
          stack.removeLast();
        }
      }

      if (child.classes.contains('comment')) {
        final comment = _parseComment(child, pair.left, postId);
        last = comment;
        (stack.isEmpty ? null : stack.last)?.children.add(comment);
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
    final creatorId = Utils.getNumberInt(element.attributes['userid']);
    final _ts = Utils.getNumberInt(element.attributes['timestamp']);
    final time =
        _ts != null ? DateTime.fromMillisecondsSinceEpoch(_ts * 1000) : null;
    final txt = element.querySelector('.txt');
    final avatarElement = txt?.querySelector('.avatar');
    final id = Utils.getNumberInt(
            element.attributes['id']?.replaceFirst('comment', '')) ??
        0;
    final ratingText = txt?.querySelector('.comment_rating')?.text;
    final avatar = avatarElement?.attributes['src'] ??
        (creatorId != null
            ? "http://img2.reactor.cc/pics/avatar/user/$creatorId"
            : null);

    final hidden = element.querySelector('.comment_show') != null;
    final usernameElement = txt?.querySelector('.comment_username');
    final username = usernameElement?.text.trim();
    final userLink = usernameElement?.attributes['href']?.split('/').last;

    final votedUp = txt?.querySelector('.vote-minus.vote-change') != null;
    final votedDown = txt?.querySelector('.vote-plus.vote-change') != null;
    final canVote = txt?.querySelector('.vote-plus') != null;
    final content = element.querySelector('.txt');

    return PostComment(
      id: id,
      postId: postId,
      votedUp: votedUp,
      votedDown: votedDown,
      canVote: canVote,
      time: time,
      rating: double.tryParse(ratingText?.trim() ?? ''),
      hidden: hidden,
      user: username != null
          ? UserShort(
              id: creatorId,
              avatar: avatar,
              username: username,
              link: userLink ?? username,
            )
          : null,
      content:
          !hidden && content != null ? _contentParser.parse(content) : null,
      depth: depth,
    );
  }

  PostComment _parseBestComment(Element element, int depth, int postId) {
    final bottom = element.querySelector('.comments_bottom');
    final avatarElement = bottom?.querySelector('.avatar');
    final timestampString = bottom
        ?.querySelector('.comment_date')
        ?.children
        .asMap()[0]
        ?.attributes['data-time'];
    final time = timestampString != null
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(timestampString) * 1000)
        : DateTime.now();
    final id = int.parse(
        (element.querySelector('.comment_link')?.attributes ?? {})['href']
                ?.split('#comment')
                ?.last ??
            '');
    final dynamic creatorId = null;
    final ratingText = bottom?.querySelector('.post_rating')?.text.trim();
    final avatar = avatarElement?.attributes['src'];
    final username = avatarElement?.attributes['alt'];
    final hidden = element.querySelector('.comment_show') != null;
    final usernameElement = bottom?.querySelector('.comment_username');
    final userLink = usernameElement?.attributes['href']?.split('/').last;

    return PostComment(
      id: id,
      time: time,
      postId: postId,
      votedUp: false,
      votedDown: false,
      canVote: false,
      rating: double.tryParse(ratingText?.replaceAll('+', '').trim() ?? ''),
      hidden: hidden,
      user: (username != null && userLink != null)
          ? UserShort(
              id: creatorId,
              avatar: avatar,
              username: username,
              link: userLink,
            )
          : null,
      content: !hidden ? _contentParser.parse(element) : null,
      depth: depth,
    );
  }
}
