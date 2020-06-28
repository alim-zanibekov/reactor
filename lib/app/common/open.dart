import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/content/link-parser.dart';
import '../../core/content/types/module.dart';
import '../image-gallery/image-gallery.dart';
import '../page/posts-page.dart';
import '../post/post.dart';
import '../user/user-page.dart';

openTag(BuildContext context, Tag tag, {bool animate = true}) {
  Navigator.push(
    context,
    PageTransition(
      duration: animate ? const Duration(milliseconds: 200) : Duration.zero,
      curve: Curves.easeInOut,
      type: PageTransitionType.rightToLeft,
      child: AppPage(
        tag: tag,
      ),
    ),
  );
}

openPost(BuildContext context, Post post, Function loadContent,
    {bool scrollToComments = false}) {
  Navigator.push(
    context,
    PageTransition(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      type: PageTransitionType.rightToLeft,
      child: AppOnePostPage(
        post: post,
        scrollToComments: scrollToComments,
        loadContent: loadContent,
      ),
    ),
  );
}

openPostById(BuildContext context, int postId, {bool animate = true}) {
  Navigator.push(
    context,
    PageTransition(
      duration: animate ? const Duration(milliseconds: 200) : Duration.zero,
      curve: Curves.easeInOut,
      type: PageTransitionType.rightToLeft,
      child: AppOnePostPage(postId: postId),
    ),
  );
}

openPostComment(BuildContext context, int postId, int commentId) {
  Navigator.push(
    context,
    PageTransition(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      type: PageTransitionType.rightToLeft,
      child: AppOnePostPage(
        postId: postId,
        commentId: commentId,
      ),
    ),
  );
}

openImage(
    BuildContext context, List<ImageProvider> images, int currentImageIndex) {
  Navigator.push(
    context,
    PageTransition(
      duration: const Duration(milliseconds: 200),
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
      duration: animate ? const Duration(milliseconds: 200) : Duration.zero,
      curve: Curves.easeInOut,
      type: PageTransitionType.rightToLeft,
      child: AppUserPage(
        username: username,
        link: link,
        main: false,
      ),
    ),
  );
}

goToLinkOrOpen(BuildContext context, String link) async {
  final parsed = LinkParser.parse(link);
  if (parsed is PostLink) {
    openPostById(context, parsed.id, animate: false);
  } else if (parsed is TagLink) {
    openTag(context, parsed.tag, animate: false);
  } else if (parsed is UserLink) {
    openUser(context, parsed.username, parsed.link, animate: false);
  } else {
    if (await canLaunch(link)) {
      await launch(link, forceSafariVC: false);
    }
  }
}

goToLink(BuildContext context, String link, {throwIsUnknown = false}) {
  final parsed = LinkParser.parse(link);
  if (parsed is PostLink) {
    openPostById(context, parsed.id, animate: false);
  } else if (parsed is TagLink) {
    openTag(context, parsed.tag, animate: false);
  } else if (parsed is UserLink) {
    openUser(context, parsed.username, parsed.link, animate: false);
  } else {
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text('Ссылка не распознана'),
    ));
  }
}
