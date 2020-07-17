import 'types/module.dart';

class _Link {}

class PostLink extends _Link {
  final int id;
  final int commentId;

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
      final postId = int.tryParse(match.group(1));
      final commentId = match.groupCount > 2 && match.group(3) != null
          ? int.tryParse(match.group(3))
          : null;
      return PostLink(postId, commentId);
    } else if (_tagLinkRegex.hasMatch(link)) {
      final match = _tagLinkRegex.firstMatch(link);
      return TagLink(
        Tag(
          Uri.decodeComponent(match.group(2)).replaceAll('+', ' '),
          prefix: match.group(1) != 'joy'
              ? match.group(1).replaceAll('.', '')
              : null,
          isMain: match.group(3) != null,
          link: match.group(2),
        ),
      );
    } else if (_fanLinkRegex.hasMatch(link)) {
      final match = _tagLinkRegex.firstMatch(link);
      return TagLink(
        Tag(
          match.group(1),
          prefix: match.group(1),
          isMain: false,
          link: '',
        ),
      );
    } else if (_userLinkRegex.hasMatch(link)) {
      final userLink = _postLinkRegex.firstMatch(link).group(1);
      return UserLink(
        Uri.decodeComponent(userLink).replaceAll('+', ' '),
        userLink,
      );
    }
    return UndefinedLink();
  }
}
