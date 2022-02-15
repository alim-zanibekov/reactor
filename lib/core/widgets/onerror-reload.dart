import 'package:flutter/material.dart';

class AppOnErrorReload extends StatelessWidget {
  final String text;
  final Function? onReloadPressed;
  final bool hasMaxWidth;
  final Widget? button;
  final Icon icon;

  const AppOnErrorReload({
    Key? key,
    required this.text,
    this.icon = const Icon(
      Icons.error_outline,
      color: Color(0xFFFF8A80),
      size: 44,
    ),
    this.onReloadPressed,
    this.hasMaxWidth = true,
    this.button,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      color: isDark ? Colors.black26 : Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          icon,
          Container(
            padding: const EdgeInsets.only(top: 10),
            constraints: BoxConstraints(
              maxWidth: hasMaxWidth ? 200 : double.infinity,
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
            ),
          ),
          button ??
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  if (onReloadPressed != null) {
                    onReloadPressed!();
                  }
                },
              )
        ],
      ),
    );
  }
}

class AppOnErrorReloadExpanded extends StatelessWidget {
  final Function? onReloadPressed;

  const AppOnErrorReloadExpanded({Key? key, this.onReloadPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: AppOnErrorReload(
        text: 'При загрузке произошла ошибка',
        hasMaxWidth: false,
        button: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: OutlinedButton(
            onPressed: () => onReloadPressed?.call(),
            child: const Text('Попробовать снова'),
          ),
        ),
      ),
    );
  }
}
