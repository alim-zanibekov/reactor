import 'package:flutter/material.dart';

import '../../../core/common/retry-network-image.dart';
import '../../../core/widgets/safe-image.dart';

class VideoThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double aspectRatio;
  final AssetImage icon;
  final Function onPlay;

  const VideoThumbnail({
    Key? key,
    this.imageUrl,
    required this.aspectRatio,
    required this.icon,
    required this.onPlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(fit: StackFit.expand, children: <Widget>[
        if (imageUrl != null)
          AppSafeImage(
            fit: BoxFit.cover,
            showAnimation: false,
            imageProvider: AppNetworkImageWithRetry(imageUrl!),
          ),
        ColoredBox(
          color: const Color.fromRGBO(0, 0, 0, 0.1),
          child: Center(
            child: GestureDetector(
              onTap: () => onPlay(),
              child: Image(image: icon, width: 64, height: 64),
            ),
          ),
        ),
      ]),
    );
  }
}
