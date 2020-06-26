import 'content.dart';
import 'user.dart';

abstract class HasChildren<T> {
  List<T> children;
}

class Tag {
  static final _extractTag3LDomainRegex =
      RegExp(r'https?:\/\/(.*?)\.reactor\.');

  final bool isMain;
  final String prefix;
  final String link;
  String value;

  static parsePrefix(String link) {
    return _extractTag3LDomainRegex.firstMatch(link ?? '')?.group(1);
  }

  static parseIsMain(String link) {
    return (link ?? '').contains('/rating');
  }

  static parseLink(String link) {
    return _linkRegex.firstMatch(link ?? '')?.group(1);
  }

  static final _linkRegex = RegExp(r'tag\/([^\/]+)');

  Tag(this.value, {this.isMain = false, this.prefix, this.link});
}

class IconTag extends Tag {
  final String icon;

  IconTag(
    value, {
    this.icon,
    isMain,
    prefix,
    link,
  }) : super(
          value,
          isMain: isMain,
          prefix: prefix,
          link: link,
        );
}

class ExtendedTag extends IconTag {
  final int count;
  final int subscribersCount;
  final double commonRating;
  final int subscribersDeltaCount;

  ExtendedTag(String value, {
    String icon,
    this.count,
    this.subscribersCount,
    this.commonRating,
    this.subscribersDeltaCount,
    isMain,
    prefix,
    link,
  }) : super(
    value,
    icon: icon,
    isMain: isMain,
    prefix: prefix,
    link: link,
  );
}

class PageInfo extends ExtendedTag {
  bool subscribed;
  bool blocked;

  final int tagId;
  final String bg;

  PageInfo({
    icon,
    this.tagId,
    this.bg,
    count,
    subscribersCount,
    commonRating,
    this.blocked = false,
    this.subscribed = false,
  }) : super(
    null,
    icon: icon,
    count: count,
    subscribersCount: subscribersCount,
    commonRating: commonRating,
  );
}

class ContentPage<T> {
  final int id;
  final List<T> content;
  final PageInfo pageInfo;
  final bool isLast;
  final bool authorized;

  ContentPage({
    this.id,
    this.content,
    this.pageInfo,
    this.isLast,
    this.authorized,
  });
}

class Post {
  final int id;
  final List<Tag> tags;
  final List<ContentUnit> content;
  final UserShort user;
  final DateTime dateTime;
  final PostComment bestComment;
  final bool censored;
  final bool hidden;

  int commentsCount;
  double rating;
  bool votedUp;
  bool canVote;
  bool votedDown;
  bool favorite;
  List<PostComment> comments;
  double height;
  bool expanded = false;

  get link {
    return 'http://joyreactor.cc/post/$id';
  }

  Post({
    this.id,
    this.tags,
    this.content,
    this.rating,
    this.bestComment,
    this.comments,
    this.user,
    this.dateTime,
    this.hidden,
    this.canVote,
    this.commentsCount,
    this.favorite = false,
    this.votedDown = false,
    this.votedUp = false,
    this.censored,
  });
}

class PostComment implements HasChildren<PostComment> {
  final int id;
  final int depth;
  final int postId;
  final DateTime time;
  final UserShort user;

  double rating;
  bool hidden;
  List<PostComment> children = [];
  List<ContentUnit> content;
  bool votedUp;
  bool canVote;
  bool votedDown;

  bool deleted = false;

  PostComment({
    this.id,
    this.depth,
    this.user,
    this.postId,
    this.content,
    this.canVote,
    this.votedUp,
    this.votedDown,
    this.rating,
    this.time,
    this.hidden = false,
  });
}

class CommentParent implements HasChildren<PostComment> {
  List<PostComment> children = [];
}
