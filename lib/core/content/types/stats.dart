import 'post.dart';

class StatsComment {
  final int id;
  final int postId;
  final double rating;
  final String username;
  final String userLink;

  StatsComment({
    this.id,
    this.postId,
    this.rating,
    this.username,
    this.userLink,
  });
}

class StatsUser {
  final String username;
  final String link;
  final double ratingDelta;

  StatsUser({this.username, this.ratingDelta, this.link});
}

class Stats {
  final List<IconTag> trends;

  final List<ExtendedTag> weekTags;
  final List<ExtendedTag> twoDayTags;
  final List<ExtendedTag> allTimeTags;

  final List<StatsComment> twoDayComments;
  final List<StatsComment> weekComments;

  final List<StatsUser> monthUsers;
  final List<StatsUser> weekUsers;

  Stats({
    this.trends,
    this.weekTags,
    this.twoDayTags,
    this.allTimeTags,
    this.twoDayComments,
    this.weekComments,
    this.monthUsers,
    this.weekUsers,
  });
}
