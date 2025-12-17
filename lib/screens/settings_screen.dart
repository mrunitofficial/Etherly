import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:etherly/localization/app_localizations.dart';
import '../../main.dart' show dynamicColorNotifier;

/// Easy options menu item builder for dropdown settings.
extension on ThemeMode {
  String getLocalizedName(AppLocalizations loc) {
    switch (this) {
      case ThemeMode.system:
        return loc.translate('settingsDeviceDefault');
      case ThemeMode.light:
        return loc.translate('settingsLightMode');
      case ThemeMode.dark:
        return loc.translate('settingsDarkMode');
    }
  }
}

extension on int {
  String getLocalizedName(AppLocalizations loc) {
    switch (this) {
      case 0:
        return loc.translate('settingsHome');
      case 1:
        return loc.translate('settingsAllChannels');
      case 2:
        return loc.translate('settingsFavorites');
      default:
        return '';
    }
  }
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

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.themeNotifier.value;
    _forceDefaultColor = !(dynamicColorNotifier.value);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedTab = _prefs!.getInt('startingTab') ?? 0;
        _autoPlay = _prefs!.getBool('autoPlay') ?? false;
        _forceDefaultColor = _prefs!.getBool('forceDefaultColor') ?? false;
        _selectedQuality = _prefs!.getString('streamQuality') ?? 'mp3';
      });
      dynamicColorNotifier.value = !_forceDefaultColor;
    }
  }

  Future<void> _saveQuality(String quality) async {
    if (_prefs != null) {
      await _prefs!.setString('streamQuality', quality);
    }
  }

  Future<void> _saveDynamicColor(bool useDynamicColor) async {
    if (_prefs != null) {
      await _prefs!.setBool('forceDefaultColor', useDynamicColor);
    }
  }

  Future<void> _saveTheme(ThemeMode themeMode) async {
    if (_prefs != null) {
      await _prefs!.setString('theme', themeMode.toString());
    }
  }

  Future<void> _saveStartingTab(int tabIndex) async {
    if (_prefs != null) {
      await _prefs!.setInt('startingTab', tabIndex);
    }
  }

  Future<void> _saveAutoPlay(bool autoPlay) async {
    if (_prefs != null) {
      await _prefs!.setBool('autoPlay', autoPlay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(loc.translate('settingsTitle')),
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: EdgeInsets.only(bottom: 128),
                children: <Widget>[
                  _buildQualityDropdownSetting(loc),
                  _buildThemeDropdownSetting(loc),
                  if (!kIsWeb) _buildForceDefaultColorSwitch(loc),
                  _buildStartingTabDropdownSetting(loc),
                  if (!kIsWeb) _buildAutoPlaySwitch(loc),
                  const Divider(),
                  _buildAboutSection(loc),
                ],
              ),
            ),
          ),
          if (!kIsWeb)
            Positioned(
              right: 24,
              bottom: 48,
              child: FloatingActionButton.extended(
                icon: const Icon(Icons.feedback_outlined),
                label: Text(loc.translate('settingsSendFeedback')),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onPressed: () async {
                  const email = 'info@etherly.nl';
                  final subject = loc.translate('settingsFeedbackEmailSubject');
                  final mailtoLink =
                      'mailto:$email?subject=${Uri.encodeComponent(subject)}';
                  if (await canLaunchUrlString(mailtoLink)) {
                    await launchUrlString(mailtoLink);
                  } else {}
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForceDefaultColorSwitch(AppLocalizations loc) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      title: Text(loc.translate('settingsForceDefaultColor')),
      trailing: Switch(
        value: _forceDefaultColor,
        onChanged: (bool newValue) {
          setState(() {
            _forceDefaultColor = newValue;
          });
          dynamicColorNotifier.value = !newValue;
          _saveDynamicColor(newValue);
        },
      ),
    );
  }

  Widget _buildAutoPlaySwitch(AppLocalizations loc) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      title: Text(loc.translate('settingsAutoplayOnStartup')),
      trailing: Switch(
        value: _autoPlay,
        onChanged: (bool newValue) {
          setState(() {
            _autoPlay = newValue;
          });
          _saveAutoPlay(newValue);
        },
      ),
    );
  }

  Widget _buildThemeDropdownSetting(AppLocalizations loc) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      title: Text(loc.translate('settingsAppTheme')),
      trailing: SizedBox(
        width: 140,
        child: DropdownButton<ThemeMode>(
          isExpanded: true,
          elevation: 1,
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          value: _selectedTheme,
          onChanged: (ThemeMode? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedTheme = newValue;
              });
              widget.themeNotifier.value = newValue;
              _saveTheme(newValue);
            }
          },
          items: ThemeMode.values.map<DropdownMenuItem<ThemeMode>>((
            ThemeMode mode,
          ) {
            return DropdownMenuItem(
              value: mode,
              child: Text(mode.getLocalizedName(loc)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStartingTabDropdownSetting(AppLocalizations loc) {
    const tabIndices = [0, 1, 2];
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      title: Text(loc.translate('settingsDefaultStartScreen')),
      trailing: SizedBox(
        width: 140,
        child: DropdownButton<int>(
          isExpanded: true,
          elevation: 1,
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          value: _selectedTab,
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedTab = newValue;
              });
              _saveStartingTab(newValue);
            }
          },
          items: tabIndices.map<DropdownMenuItem<int>>((int index) {
            return DropdownMenuItem(
              value: index,
              child: Text(index.getLocalizedName(loc)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQualityDropdownSetting(AppLocalizations loc) {
    final qualityOptions = [
      {'key': 'mp3', 'label': loc.translate('settingsStreamingQualityHigh')},
      {'key': 'aac', 'label': loc.translate('settingsStreamingQualityHighest')},
    ];
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      title: Text(loc.translate('settingsDefaultStreamingQuality')),
      trailing: SizedBox(
        width: 140,
        child: DropdownButton<String>(
          isExpanded: true,
          elevation: 1,
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          value: _selectedQuality,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedQuality = newValue;
              });
              _saveQuality(newValue);
            }
          },
          items: qualityOptions.map<DropdownMenuItem<String>>((opt) {
            return DropdownMenuItem<String>(
              value: opt['key']!,
              child: Text(opt['label']!),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAboutSection(AppLocalizations loc) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('settingsAboutTitle'),
            style: textTheme.titleLarge,
          ),
          Text(loc.translate('settingsAboutDescription1')),
          const SizedBox(height: 8),
          Text(loc.translate('settingsAboutDescription2')),
          const SizedBox(height: 16),
          Text(loc.translate('settingsCreatedBy'), style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}
