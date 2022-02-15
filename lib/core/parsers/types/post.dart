import 'content.dart';
import 'user.dart';

abstract class HasChildren<T> {
  List<T> children = [];
}

class QuizAnswer {
  final int? id;
  final String text;
  final double percent;
  final int? count;

  const QuizAnswer({
    this.id,
    required this.text,
    required this.percent,
    this.count,
  });
}

class Quiz {
  final String title;
  final List<QuizAnswer> answers;

  const Quiz({required this.title, required this.answers});
}

class Tag {
  static final _extractTag3LDomainRegex =
      RegExp(r'https?:\/\/(.*?)\.reactor\.');

  final bool isMain;
  final String? prefix;
  final String? link;
  String value;

  static parsePrefix(String? link) {
    return _extractTag3LDomainRegex.firstMatch(link ?? '')?.group(1);
  }

  static parseIsMain(String? link) {
    return (link ?? '').contains('/rating');
  }

  static parseLink(String? link) {
    return _linkRegex.firstMatch(link ?? '')?.group(1);
  }

  static final _linkRegex = RegExp(r'tag\/([^\/]+)');

  Tag(this.value, {this.isMain = false, this.prefix, this.link})
      : assert(!isMain || (isMain && link != null));
}

class IconTag extends Tag {
  final String? icon;

  IconTag(
    String value, {
    this.icon,
    bool? isMain,
    String? prefix,
    String? link,
  }) : super(
          value,
          isMain: isMain ?? false,
          prefix: prefix,
          link: link,
        );
}

class ExtendedTag extends IconTag {
  final int? count;
  final int? subscribersCount;
  final double? commonRating;
  final int? subscribersDeltaCount;

  ExtendedTag(
    String value, {
    String? icon,
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
  final String? bg;

  PageInfo(
    String value, {
    String? icon,
    required this.tagId,
    this.bg,
    int? count,
    int? subscribersCount,
    double? commonRating,
    this.blocked = false,
    this.subscribed = false,
  }) : super(
          value,
          icon: icon,
          count: count,
          subscribersCount: subscribersCount,
          commonRating: commonRating,
        );
}

class ContentPage<T> {
  final int id;
  final List<T> content;
  final PageInfo? pageInfo;
  final bool isLast;
  final bool authorized;
  final bool reversedPagination;

  ContentPage({
    required this.id,
    required this.content,
    this.pageInfo,
    this.isLast = false,
    this.authorized = false,
    this.reversedPagination = false,
  });

  static empty<T>() {
    return ContentPage<T>(
      id: 0,
      content: [],
      isLast: true,
      authorized: true,
      pageInfo: null,
    );
  }
}

class Post {
  final int id;
  final List<Tag> tags;
  final List<ContentUnit> content;
  final UserShort? user;
  final DateTime? dateTime;
  final PostComment? bestComment;
  final bool censored;
  final bool unsafe;
  final bool hidden;

  int? commentsCount;
  double? rating;
  bool votedUp;
  bool canVote;
  bool votedDown;
  bool favorite;
  List<PostComment>? comments;
  double? height;
  bool expanded = false;
  Quiz? quiz;

  get link {
    return 'http://joyreactor.cc/post/$id';
  }

  Post({
    required this.id,
    required this.tags,
    required this.content,
    this.rating,
    this.bestComment,
    this.comments,
    this.user,
    this.dateTime,
    this.hidden = false,
    this.canVote = false,
    this.unsafe = false,
    this.commentsCount,
    this.favorite = false,
    this.votedDown = false,
    this.votedUp = false,
    this.censored = false,
    this.quiz,
  });
}

class PostComment implements HasChildren<PostComment> {
  final int id;
  final int depth;
  final int postId;
  final DateTime? time;
  final UserShort? user;

  double? rating;
  bool hidden;
  List<PostComment> children = [];
  List<ContentUnit>? content;
  bool votedUp;
  bool canVote;
  bool votedDown;

  bool deleted = false;

  PostComment({
    required this.id,
    required this.depth,
    required this.postId,
    this.user,
    this.content,
    this.canVote = false,
    this.votedUp = false,
    this.votedDown = false,
    this.rating,
    this.time,
    this.hidden = false,
  });
}

class CommentParent implements HasChildren<PostComment> {
  List<PostComment> children = [];
}
