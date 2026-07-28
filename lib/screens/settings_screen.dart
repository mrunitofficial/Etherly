import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:etherly/localization/app_localizations.dart';

import 'package:etherly/services/music_app_service.dart';
import 'package:etherly/services/theme_data.dart';

/// Easy options menu item builder for dropdown settings.
extension on ThemeMode {
  String getLocalizedName(AppLocalizations loc) => switch (this) {
    ThemeMode.system => loc.settingsDeviceDefault,
    ThemeMode.light => loc.settingsLightMode,
    ThemeMode.dark => loc.settingsDarkMode,
  };
}

extension on int {
  String getLocalizedName(AppLocalizations loc) => switch (this) {
    0 => loc.settingsHome,
    1 => loc.settingsAllChannels,
    2 => loc.settingsFavorites,
    _ => '',
  };
}

/// A screen that displays the settings for the app.
class SettingsScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  const SettingsScreen({super.key, required this.themeNotifier});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SharedPreferences? _prefs;
  late ThemeMode _selectedTheme;
  int _selectedTab = 0;
  bool _autoPlay = false;
  bool _forceDefaultColor = false;
  String _selectedQuality = 'mp3';
  String _selectedMusicApp = 'always_ask';
  String _selectedLanguage = 'system';
  List<String> _availableAppIds = [];
  final MusicAppService _musicAppService = MusicAppService();

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.themeNotifier.value;
    _forceDefaultColor = !dynamicColorNotifier.value;
    _loadSettings();
    _checkAvailableApps();
  }

  Future<void> _checkAvailableApps() async {
    final apps = await _musicAppService.getAvailableApps();
    if (mounted) {
      setState(() {
        _availableAppIds = apps.map((a) => a['id']!).toList();

        final isSpecialOption =
            _selectedMusicApp == 'always_ask' ||
            _selectedMusicApp == 'internet_search';
        if (!isSpecialOption && !_availableAppIds.contains(_selectedMusicApp)) {
          _selectedMusicApp = 'always_ask';
          _saveSetting('favoriteMusicApp', 'always_ask');
        }
      });
    }
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedTab = _prefs!.getInt('startingTab') ?? 0;
        _autoPlay = _prefs!.getBool('autoPlay') ?? false;
        _forceDefaultColor = _prefs!.getBool('forceDefaultColor') ?? false;
        _selectedQuality = _prefs!.getString('streamQuality') ?? 'mp3';
        _selectedMusicApp =
            _prefs!.getString('favoriteMusicApp') ?? 'always_ask';
        _selectedLanguage = _prefs!.getString('language') ?? 'system';
      });
      dynamicColorNotifier.value = !_forceDefaultColor;
    }
  }

  Future<void> _saveSetting<T>(String key, T value) async {
    if (_prefs == null) return;
    if (value is String) {
      await _prefs!.setString(key, value);
    } else if (value is bool) {
      await _prefs!.setBool(key, value);
    } else if (value is int) {
      await _prefs!.setInt(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final shapes = theme.extension<Shapes>()!;
    final sizes = theme.extension<Sizes>()!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainer,
        title: Text(loc.settingsTitle),
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: EdgeInsets.only(bottom: sizes.largeIncreased),
                children: <Widget>[
                  SettingDropdownTile<String>(
                    title: loc.settingsDefaultStreamingQuality,
                    initialSelection: _selectedQuality,
                    onSelected: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedQuality = newValue;
                        });
                        _saveSetting('streamQuality', newValue);
                      }
                    },
                    dropdownMenuEntries: [
                      DropdownMenuEntry<String>(
                        value: 'mp3',
                        label: loc.settingsStreamingQualityHigh,
                      ),
                      DropdownMenuEntry<String>(
                        value: 'aac',
                        label: loc.settingsStreamingQualityHighest,
                      ),
                    ],
                  ),
                  SettingDropdownTile<ThemeMode>(
                    title: loc.settingsAppTheme,
                    initialSelection: _selectedTheme,
                    onSelected: (ThemeMode? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedTheme = newValue;
                        });
                        widget.themeNotifier.value = newValue;
                        _saveSetting('theme', newValue.name);
                      }
                    },
                    dropdownMenuEntries: ThemeMode.values.map((ThemeMode mode) {
                      return DropdownMenuEntry<ThemeMode>(
                        value: mode,
                        label: mode.getLocalizedName(loc),
                      );
                    }).toList(),
                  ),
                  if (kIsWeb)
                    SettingDropdownTile<String>(
                      title: loc.language,
                      initialSelection: _selectedLanguage,
                      onSelected: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedLanguage = newValue;
                          });
                          languageNotifier.value = newValue;
                          _saveSetting('language', newValue);
                        }
                      },
                      dropdownMenuEntries: [
                        DropdownMenuEntry<String>(
                          value: 'system',
                          label: loc.system,
                        ),
                        ...AppLocalizations.supportedLocales.map((locale) {
                          return DropdownMenuEntry<String>(
                            value: locale.languageCode,
                            label: lookupAppLocalizations(locale).languageName,
                          );
                        }),
                      ],
                    ),
                  if (!kIsWeb)
                    SettingSwitchTile(
                      title: loc.settingsForceDefaultColor,
                      value: _forceDefaultColor,
                      onChanged: (bool newValue) {
                        setState(() {
                          _forceDefaultColor = newValue;
                        });
                        dynamicColorNotifier.value = !newValue;
                        _saveSetting('forceDefaultColor', newValue);
                      },
                    ),
                  SettingDropdownTile<int>(
                    title: loc.settingsDefaultStartScreen,
                    initialSelection: _selectedTab,
                    onSelected: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedTab = newValue;
                        });
                        _saveSetting('startingTab', newValue);
                      }
                    },
                    dropdownMenuEntries: const [0, 1, 2].map((int index) {
                      return DropdownMenuEntry<int>(
                        value: index,
                        label: index.getLocalizedName(loc),
                      );
                    }).toList(),
                  ),
                  if (!kIsWeb)
                    SettingSwitchTile(
                      title: loc.settingsAutoplayOnStartup,
                      value: _autoPlay,
                      onChanged: (bool newValue) {
                        setState(() {
                          _autoPlay = newValue;
                        });
                        _saveSetting('autoPlay', newValue);
                      },
                    ),
                  if (!kIsWeb)
                    SettingDropdownTile<String>(
                      title: loc.settingsPreferredMusicApp,
                      initialSelection: _getSafeMusicAppValue(loc),
                      onSelected: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedMusicApp = newValue;
                          });
                          _saveSetting('favoriteMusicApp', newValue);
                        }
                      },
                      dropdownMenuEntries: _getMusicAppEntries(loc),
                    ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: spacing.medium),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.settingsAboutTitle, style: theme.textTheme.titleLarge),
                        Text(loc.settingsAboutDescription1),
                        SizedBox(height: spacing.small),
                        Text(loc.settingsAboutDescription2),
                        SizedBox(height: spacing.medium),
                        Text(loc.settingsCreatedBy, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: spacing.large,
            bottom: spacing.extraLarge,
            child: FloatingActionButton.extended(
              icon: const Icon(Icons.feedback_outlined),
              label: Text(loc.settingsSendFeedback),
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              shape: RoundedRectangleBorder(borderRadius: shapes.medium),
              onPressed: () async {
                const email = 'info@etherly.nl';
                final subject = loc.settingsFeedbackEmailSubject;
                final mailtoLink =
                    'mailto:$email?subject=${Uri.encodeComponent(subject)}';
                if (await canLaunchUrlString(mailtoLink)) {
                  await launchUrlString(mailtoLink);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  String _getSafeMusicAppValue(AppLocalizations loc) {
    final entries = _getMusicAppEntries(loc);
    return entries.any((entry) => entry.value == _selectedMusicApp)
        ? _selectedMusicApp
        : 'always_ask';
  }

  List<DropdownMenuEntry<String>> _getMusicAppEntries(AppLocalizations loc) {
    String getAppLabel(String id, String defaultName) => switch (id) {
      'youtube' => loc.settingsMusicAppYoutube,
      'ytmusic' => loc.settingsMusicAppYtMusic,
      'spotify' => loc.settingsMusicAppSpotify,
      'apple_music' => loc.settingsMusicAppAppleMusic,
      'tidal' => loc.settingsMusicAppTidal,
      'soundcloud' => loc.settingsMusicAppSoundcloud,
      'amazon' => loc.settingsMusicAppAmazon,
      _ => defaultName,
    };

    final musicAppOptions = [
      {'key': 'always_ask', 'label': loc.settingsMusicAppAlwaysAsk},
      ..._musicAppService
          .getAllSupportedApps()
          .where(
            (app) =>
                _availableAppIds.contains(app['id']) ||
                app['id'] == _selectedMusicApp,
          )
          .map(
            (app) => {
              'key': app['id'] as String,
              'label': getAppLabel(app['id'] as String, app['name'] as String),
            },
          ),
      {'key': 'internet_search', 'label': loc.playerSearchInternet},
    ];

    return musicAppOptions.map((opt) {
      return DropdownMenuEntry<String>(
        value: opt['key']!,
        label: opt['label']!,
      );
    }).toList();
  }
}

/// Reusable dropdown setting row component.
class SettingDropdownTile<T> extends StatelessWidget {
  final String title;
  final T initialSelection;
  final ValueChanged<T?> onSelected;
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;

  const SettingDropdownTile({
    super.key,
    required this.title,
    required this.initialSelection,
    required this.onSelected,
    required this.dropdownMenuEntries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final sizes = theme.extension<Sizes>()!;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.small),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: spacing.medium),
        title: Text(title),
        trailing: DropdownMenu<T>(
          width: sizes.extraLargeIncreased,
          requestFocusOnTap: false,
          initialSelection: initialSelection,
          onSelected: onSelected,
          dropdownMenuEntries: dropdownMenuEntries,
        ),
      ),
    );
  }
}

/// Reusable switch setting row component.
class SettingSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<Spacing>()!;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.small),
      child: SwitchListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: spacing.medium),
        title: Text(title),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
