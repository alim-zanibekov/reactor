import 'package:flutter/material.dart';

import '../../core/preferences/preferences.dart';
import '../../main.dart';

class AppSettings extends StatefulWidget {
  const AppSettings({Key key}) : super(key: key);

  @override
  _AppSettingsState createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  Preferences _preferences = Preferences();
  AppTheme _theme;
  AppPostsType _postsType;
  bool _sfw;
  bool _sendErrorStatistics;

  @override
  void initState() {
    _theme = _preferences.theme;
    _postsType = _preferences.postsType;
    _sfw = _preferences.sfw;
    _sendErrorStatistics = _preferences.sendErrorStatistics;
    super.initState();
  }

  void _handleTheme(AppTheme value) async {
    setState(() {
      _theme = value;
    });
    await _preferences.setTheme(value);
    App.appTheme.add(value);
  }

  void _handlePostType(AppPostsType value) async {
    setState(() {
      _postsType = value;
    });
    await _preferences.setDefaultPostType(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('Открывать по умолчанию'),
          ),
          LabeledRadio<AppPostsType>(
            label: 'Новое',
            padding: EdgeInsets.symmetric(horizontal: 5.0).copyWith(left: 20),
            value: AppPostsType.NEW,
            groupValue: _postsType,
            onChanged: _handlePostType,
          ),
          LabeledRadio<AppPostsType>(
            label: 'Хорошее',
            padding: EdgeInsets.symmetric(horizontal: 5.0).copyWith(left: 20),
            value: AppPostsType.GOOD,
            groupValue: _postsType,
            onChanged: _handlePostType,
          ),
          LabeledRadio<AppPostsType>(
            label: 'Лучшее',
            padding: EdgeInsets.symmetric(horizontal: 5.0).copyWith(left: 20),
            value: AppPostsType.BEST,
            groupValue: _postsType,
            onChanged: _handlePostType,
          ),
          const ListTile(
            title: const Text('Тема'),
          ),
          LabeledRadio<AppTheme>(
            label: 'Автоматически',
            padding: EdgeInsets.symmetric(horizontal: 5.0).copyWith(left: 20),
            value: AppTheme.AUTO,
            groupValue: _theme,
            onChanged: _handleTheme,
          ),
          LabeledRadio<AppTheme>(
            label: 'Темная',
            padding: EdgeInsets.symmetric(horizontal: 5.0).copyWith(left: 20),
            value: AppTheme.DARK,
            groupValue: _theme,
            onChanged: _handleTheme,
          ),
          LabeledRadio<AppTheme>(
            label: 'Светлая',
            padding: EdgeInsets.symmetric(horizontal: 5.0).copyWith(left: 20),
            value: AppTheme.LIGHT,
            groupValue: _theme,
            onChanged: _handleTheme,
          ),
          SwitchListTile(
            title: const Text('SFW'),
            value: _sfw,
            activeColor: Theme.of(context).accentColor,
            onChanged: (bool sfw) async {
              setState(() {
                _sfw = sfw;
              });
              await _preferences.setSFW(sfw);
            },
          ),
          SwitchListTile(
            title: const Text('Отправлять отчеты об ошибках'),
            value: _sendErrorStatistics,
            activeColor: Theme.of(context).accentColor,
            onChanged: (bool sendErrorStatistics) async {
              Scaffold.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Пока что нельзя это выключить, подождите более стабильной версии',
                  ),
                ),
              );
              return;
              setState(() {
                _sendErrorStatistics = sendErrorStatistics;
              });
              await _preferences.setSendErrorStatistics(sendErrorStatistics);
            },
          )
        ],
      ),
    );
  }
}

class LabeledRadio<T> extends StatelessWidget {
  const LabeledRadio({
    this.label,
    this.padding,
    this.groupValue,
    this.value,
    this.onChanged,
  });

  final String label;
  final EdgeInsets padding;
  final T groupValue;
  final T value;
  final void Function(T) onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (value != groupValue) onChanged(value);
      },
      child: Padding(
        padding: padding,
        child: Row(
          children: <Widget>[
            SizedBox(
              height: 35,
              child: Radio<T>(
                activeColor: Theme.of(context).accentColor,
                groupValue: groupValue,
                value: value,
                onChanged: (T newValue) {
                  onChanged(newValue);
                },
              ),
            ),
            Text(label, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
