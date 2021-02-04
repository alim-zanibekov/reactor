import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

import './types/module.dart';
import '../common/pair.dart';
import 'content-parser.dart';
import 'types/post.dart';

class CommentsParser {
  final _contentParser = ContentParser();

  List<PostComment> parsePostComments(Element parsedPage, int postId) {
    final commentsContainer =
        parsedPage.querySelector('.ufoot .comment_list_post');
    return _parseCommentsElement(commentsContainer, postId);
  }

  List<PostComment> parseComments(String c, int postId) {
    final parsedPage = parser.parse(c);
    return _parseCommentsElement(
        parsedPage.querySelector('.comment_list_post'), postId);
  }

  PostComment parseComment(Element element, int postId) {
    return _parseComment(element, 0, postId);
  }

  PostComment parseBestCommentElement(Element parsedPage, int postId) {
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
        while (stack.isNotEmpty && stack.length - 1 != pair.left) {
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
        id: creatorId,
        avatar: avatar,
        username: username,
        link: userLink,
      ),
      content:
          !hidden ? _contentParser.parse(element.querySelector('.txt')) : null,
      depth: depth,
    );
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
        id: creatorId,
        avatar: avatar,
        username: username,
        link: userLink,
      ),
      content: !hidden ? _contentParser.parse(element) : null,
      depth: depth,
    );
  }
}
