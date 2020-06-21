import 'post.dart';

class UserShort {
  final int id;
  final String username;
  final String avatar;
  final String link;

  UserShort({this.id, this.username, this.avatar, this.link});
}

class Award {
  final String title;
  final String icon;
  final int id;

  Award({this.title, this.icon, this.id});
}

class UserTag extends Tag {
  final double weight;
  final double rating;
  final double ratingWeekDelta;
  final String icon;

  UserTag(String value,
      {this.icon,
      this.rating,
      this.ratingWeekDelta,
      this.weight,
      isMain,
      prefix,
      link})
      : super(value, isMain: isMain, prefix: prefix, link: link);
}

class UserStats {
  final int postCount;
  final int bestPostCount;
  final int goodPostCount;
  final int commentsCount;
  final int daysCount;
  final DateTime lastEnter;

  UserStats(
      {this.postCount,
      this.bestPostCount,
      this.goodPostCount,
      this.commentsCount,
      this.daysCount,
      this.lastEnter});
}

class UserFull {
  final int id;
  final String username;
  final String link;
  final String avatar;
  final List<Award> awards;
  final double rating;
  final int stars;
  final List<UserTag> tagCloud;
  final List<UserTag> activeIn;
  final List<Tag> moderating;
  final List<Tag> subscriptions;
  final List<Tag> ignore;
  final Tag mainTag;
  final double ratingWeekDelta;
  final UserStats stats;

  UserFull(
      {this.id,
      this.link,
      this.username,
      this.activeIn,
      this.avatar,
      this.awards,
      this.rating,
      this.stars,
      this.tagCloud,
      this.mainTag,
      this.ignore,
      this.ratingWeekDelta,
      this.moderating,
      this.stats,
      this.subscriptions});

  UserShort toShort() => UserShort(id: id, avatar: avatar, username: username);
}
