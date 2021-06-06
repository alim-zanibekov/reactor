import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/parsers/link-parser.dart';
import '../../core/parsers/types/module.dart';
import '../image-gallery/image-gallery.dart';
import '../page/posts-page.dart';
import '../post/post-page.dart';
import '../search/search-list.dart';
import '../search/search.dart';
import '../user/user-page.dart';
import 'page-wrapper.dart';

final _duration = const Duration(milliseconds: 200);

openTag(BuildContext context, Tag? tag, {bool animate = true}) {
  Navigator.push(
    context,
    PageTransition(
      duration: animate ? _duration : Duration.zero,
      curve: Curves.easeInOut,
      type: PageTransitionType.rightToLeft,
      child: PageWrapper(
        child: AppPage(
          tag: tag,
        ),
      ),
    ),
  );
}

openPost(BuildContext context, Post? post, Function? loadContent,
    {bool scrollToComments = false}) {
  Navigator.push(
    context,
    PageTransition(
      duration: _duration,
      curve: Curves.easeInOut,
      type: PageTransitionType.rightToLeft,
      child: PageWrapper(
        child: AppOnePostPage(
          post: post,
          scrollToComments: scrollToComments,
          loadContent: loadContent,
        ),
      ),
    ),
  );
}

openPostById(BuildContext context, int? postId,
    {int? commentId, bool animate = true}) {
  Navigator.push(
    context,
    PageTransition(
      duration: animate ? _duration : Duration.zero,
      curve: Curves.easeInOut,
      type: PageTransitionType.rightToLeft,
      child: PageWrapper(
        child: AppOnePostPage(
          postId: postId,
          commentId: commentId,
        ),
      ),
    ),
  );
}

openImage(
    BuildContext context, List<ImageProvider> images, int currentImageIndex) {
  Navigator.push(
    context,
    PageTransition(
      duration: _duration,
      curve: Curves.easeInOut,
      type: PageTransitionType.rightToLeft,
      child: ImageGalleryScreen(
        imageProviders: images,
        selectedIndex: currentImageIndex,
      ),
    ),
  );
}

openUser(BuildContext context, String username, String link,
    {bool animate = true}) {
  Navigator.push(
    context,
    PageTransition(
        duration: animate ? _duration : Duration.zero,
        curve: Curves.easeInOut,
        type: PageTransitionType.rightToLeft,
        child: PageWrapper(
          child: AppUserPage(
            username: username,
            link: link,
            main: false,
          ),
        )),
  );
}

openSearch(BuildContext context, {bool animate = true}) {
  Navigator.push(
    context,
    PageTransition(
      duration: animate ? _duration : Duration.zero,
      curve: Curves.easeInOut,
      type: PageTransitionType.rightToLeft,
      child: AppSearch(),
    ),
  );
}

openSearchList(
    BuildContext context, String query, String author, List<String?>? tags,
    {bool animate = true}) {
  Navigator.push(
    context,
    PageTransition(
      duration: animate ? _duration : Duration.zero,
      curve: Curves.easeInOut,
      type: PageTransitionType.rightToLeft,
      child: AppSearchList(query: query, author: author, tags: tags),
    ),
  );
}

goToLinkOrOpen(BuildContext context, String link) async {
  final parsed = LinkParser.parse(link);
  if (parsed is PostLink) {
    openPostById(context, parsed.id, commentId: parsed.commentId);
  } else if (parsed is TagLink) {
    openTag(context, parsed.tag);
  } else if (parsed is UserLink) {
    openUser(context, parsed.username, parsed.link);
  } else {
    if (await canLaunch(link)) {
      await launch(link, forceSafariVC: false);
    }
  }
}

goToLink(BuildContext context, String link) {
  final parsed = LinkParser.parse(link);
  if (parsed is PostLink) {
    openPostById(context, parsed.id, animate: false);
  } else if (parsed is TagLink) {
    openTag(context, parsed.tag, animate: false);
  } else if (parsed is UserLink) {
    openUser(context, parsed.username, parsed.link, animate: false);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Ссылка не распознана'),
    ));
  }
}
