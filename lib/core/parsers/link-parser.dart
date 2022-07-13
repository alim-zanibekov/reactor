import 'utils.dart';

import 'types/module.dart';

class _Link {}

class PostLink extends _Link {
  final int? id;
  final int? commentId;

  PostLink(this.id, this.commentId);
}

class TagLink extends _Link {
  final Tag tag;

  TagLink(this.tag);
}

class UserLink extends _Link {
  final String username;
  final String link;

  UserLink(this.username, this.link);
}

class UndefinedLink extends _Link {}

class LinkParser {
  static final _postLinkRegex = RegExp(
      r'(?:https?:)?\/\/(?:joy|[^\/\.]+\.)reactor.cc\/post\/([^\/#]+)(#comment([0-9]+))?.*?');
  static final _tagLinkRegex = RegExp(
      r'(?:https?:)?\/\/(joy|[^\/\.]+\.)reactor.cc\/tag\/([^\/]+)(\/rating|\/subtags)?.*?');
  static final _fanLinkRegex =
      RegExp(r'(?:https?:)?\/\/([^\/\.]+)\.reactor.cc\/?.*?');
  static final _userLinkRegex = RegExp(
      r'(?:https?:)?\/\/(?:joy|[^\/\.]+\.)reactor.cc\/user\/([^\/]+).*?');

  static _Link parse(String link) {
    if (_postLinkRegex.hasMatch(link)) {
      final match = _postLinkRegex.firstMatch(link);
      if (match == null) return UndefinedLink();

      final postId = Utils.getNumberInt(match.group(1));
      final commentId = match.groupCount > 2 && match.group(3) != null
          ? Utils.getNumberInt(match.group(3))
          : null;
      return PostLink(postId, commentId);
    } else if (_tagLinkRegex.hasMatch(link)) {
      final match = _tagLinkRegex.firstMatch(link);
      final tagLink = match?.group(2);
      if (match == null || tagLink == null) return UndefinedLink();

      return TagLink(
        Tag(
          Uri.decodeComponent(tagLink).replaceAll('+', ' '),
          prefix: match.group(1) != null && match.group(1) != 'joy'
              ? match.group(1)?.replaceAll('.', '')
              : null,
          isMain: match.group(3) != null,
          link: match.group(2),
        ),
      );
    } else if (_fanLinkRegex.hasMatch(link)) {
      final match = _fanLinkRegex.firstMatch(link);
      if (match == null) return UndefinedLink();

      return TagLink(
        Tag(
          match.group(1) ?? '-//-',
          prefix: match.group(1),
          isMain: false,
          link: '',
        ),
      );
    } else if (_userLinkRegex.hasMatch(link)) {
      final match = _userLinkRegex.firstMatch(link);
      final userLink = match?.group(1);
      if (userLink == null) return UndefinedLink();

      return UserLink(
        Uri.decodeComponent(userLink).replaceAll('+', ' '),
        userLink,
      );
    }
    return UndefinedLink();
  }
}
