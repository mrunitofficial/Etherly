import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Etherly'**
  String get appTitle;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A Dutch radio app'**
  String get appDescription;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @dutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get dutch;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navStations.
  ///
  /// In en, this message translates to:
  /// **'All stations'**
  String get navStations;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @mainTooltipVoiceSearch.
  ///
  /// In en, this message translates to:
  /// **'Voice search'**
  String get mainTooltipVoiceSearch;

  /// No description provided for @mainTooltipCast.
  ///
  /// In en, this message translates to:
  /// **'Cast to device'**
  String get mainTooltipCast;

  /// No description provided for @mainTooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get mainTooltipSettings;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite stations'**
  String get homeFavoritesTitle;

  /// No description provided for @homeRecentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent stations'**
  String get homeRecentsTitle;

  /// No description provided for @homeCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular stations'**
  String get homeCategoriesTitle;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Etherly'**
  String get homeWelcome;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No stations'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No radio stations available'**
  String get homeEmptySubtitle;

  /// No description provided for @homeMoreFrom.
  ///
  /// In en, this message translates to:
  /// **'More from'**
  String get homeMoreFrom;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @searchPanelHint.
  ///
  /// In en, this message translates to:
  /// **'Search stations...'**
  String get searchPanelHint;

  /// No description provided for @searchPanelVoiceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Voice search'**
  String get searchPanelVoiceTooltip;

  /// No description provided for @searchPanelMicPermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for voice search.'**
  String get searchPanelMicPermission;

  /// No description provided for @searchPanelTypeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search stations...'**
  String get searchPanelTypeToSearch;

  /// No description provided for @searchPanelVoiceToSearch.
  ///
  /// In en, this message translates to:
  /// **'Speak to search stations...'**
  String get searchPanelVoiceToSearch;

  /// No description provided for @searchPanelNoResults.
  ///
  /// In en, this message translates to:
  /// **'No stations found'**
  String get searchPanelNoResults;

  /// No description provided for @searchPanelVoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Start talking to search...'**
  String get searchPanelVoiceHint;

  /// No description provided for @settingsDefaultStreamingQuality.
  ///
  /// In en, this message translates to:
  /// **'Prefered stream quality'**
  String get settingsDefaultStreamingQuality;

  /// No description provided for @settingsStreamingQualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High (MP3)'**
  String get settingsStreamingQualityHigh;

  /// No description provided for @settingsStreamingQualityHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest (AAC)'**
  String get settingsStreamingQualityHighest;

  /// No description provided for @settingsAppTheme.
  ///
  /// In en, this message translates to:
  /// **'App theme'**
  String get settingsAppTheme;

  /// No description provided for @settingsDeviceDefault.
  ///
  /// In en, this message translates to:
  /// **'Device default'**
  String get settingsDeviceDefault;

  /// No description provided for @settingsLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get settingsLightMode;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsDefaultStartScreen.
  ///
  /// In en, this message translates to:
  /// **'Default start screen'**
  String get settingsDefaultStartScreen;

  /// No description provided for @settingsHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get settingsHome;

  /// No description provided for @settingsAllChannels.
  ///
  /// In en, this message translates to:
  /// **'All stations'**
  String get settingsAllChannels;

  /// No description provided for @settingsFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get settingsFavorites;

  /// No description provided for @settingsAutoplayOnStartup.
  ///
  /// In en, this message translates to:
  /// **'Autoplay on startup'**
  String get settingsAutoplayOnStartup;

  /// No description provided for @settingsForceDefaultColor.
  ///
  /// In en, this message translates to:
  /// **'Force default color scheme'**
  String get settingsForceDefaultColor;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Etherly'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutDescription1.
  ///
  /// In en, this message translates to:
  /// **'Etherly is a lightweight, open-source internet radio player. This app is designed to be modern, fast, and easy to use.'**
  String get settingsAboutDescription1;

  /// No description provided for @settingsAboutDescription2.
  ///
  /// In en, this message translates to:
  /// **'Please be aware that this app is built on the Flutter framework using Visual Studio Code, Github and Github pages. This app may include various third-party packages provided by the open-source community. These components are governed by their own respective licenses.'**
  String get settingsAboutDescription2;

  /// No description provided for @settingsCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by Mr Unit'**
  String get settingsCreatedBy;

  /// No description provided for @settingsSendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get settingsSendFeedback;

  /// No description provided for @settingsFeedbackEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Feedback for Etherly'**
  String get settingsFeedbackEmailSubject;

  /// No description provided for @settingsCouldNotOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app.'**
  String get settingsCouldNotOpenEmail;

  /// No description provided for @settingsPreferredMusicApp.
  ///
  /// In en, this message translates to:
  /// **'Preferred music app'**
  String get settingsPreferredMusicApp;

  /// No description provided for @settingsMusicAppAlwaysAsk.
  ///
  /// In en, this message translates to:
  /// **'Always ask'**
  String get settingsMusicAppAlwaysAsk;

  /// No description provided for @settingsMusicAppYoutube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get settingsMusicAppYoutube;

  /// No description provided for @settingsMusicAppYtMusic.
  ///
  /// In en, this message translates to:
  /// **'YouTube Music'**
  String get settingsMusicAppYtMusic;

  /// No description provided for @settingsMusicAppSpotify.
  ///
  /// In en, this message translates to:
  /// **'Spotify'**
  String get settingsMusicAppSpotify;

  /// No description provided for @settingsMusicAppAppleMusic.
  ///
  /// In en, this message translates to:
  /// **'Apple Music'**
  String get settingsMusicAppAppleMusic;

  /// No description provided for @settingsMusicAppTidal.
  ///
  /// In en, this message translates to:
  /// **'Tidal'**
  String get settingsMusicAppTidal;

  /// No description provided for @settingsMusicAppSoundcloud.
  ///
  /// In en, this message translates to:
  /// **'SoundCloud'**
  String get settingsMusicAppSoundcloud;

  /// No description provided for @settingsMusicAppAmazon.
  ///
  /// In en, this message translates to:
  /// **'Amazon Music'**
  String get settingsMusicAppAmazon;

  /// No description provided for @playerSearchInternet.
  ///
  /// In en, this message translates to:
  /// **'Search internet'**
  String get playerSearchInternet;

  /// No description provided for @playerNoMusicAppsInstalled.
  ///
  /// In en, this message translates to:
  /// **'No music apps installed'**
  String get playerNoMusicAppsInstalled;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorite stations yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite a radio station first'**
  String get favoritesEmptySubtitle;

  /// No description provided for @stationsTitle.
  ///
  /// In en, this message translates to:
  /// **'All stations'**
  String get stationsTitle;

  /// No description provided for @stationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No stations'**
  String get stationsEmptyTitle;

  /// No description provided for @stationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No radio stations found'**
  String get stationsEmptySubtitle;

  /// No description provided for @playerPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playerPlay;

  /// No description provided for @playerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// No description provided for @playerFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get playerFavorite;

  /// No description provided for @playerSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get playerSleepTimer;

  /// No description provided for @playerCancelSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Cancel sleep timer'**
  String get playerCancelSleepTimer;

  /// No description provided for @playerClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get playerClose;

  /// No description provided for @playerSendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get playerSendFeedback;

  /// No description provided for @playerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get playerSettings;

  /// No description provided for @playerStreamQuality.
  ///
  /// In en, this message translates to:
  /// **'Stream quality'**
  String get playerStreamQuality;

  /// No description provided for @playerAbout.
  ///
  /// In en, this message translates to:
  /// **'About Etherly'**
  String get playerAbout;

  /// No description provided for @playerLoadingStation.
  ///
  /// In en, this message translates to:
  /// **'Select a station...'**
  String get playerLoadingStation;

  /// No description provided for @playerLoadingSong.
  ///
  /// In en, this message translates to:
  /// **'Loading song...'**
  String get playerLoadingSong;

  /// No description provided for @playerStartPlaying.
  ///
  /// In en, this message translates to:
  /// **'Start playing...'**
  String get playerStartPlaying;

  /// No description provided for @playerPickMusicApp.
  ///
  /// In en, this message translates to:
  /// **'Choose music app'**
  String get playerPickMusicApp;

  /// No description provided for @playerHintExpand.
  ///
  /// In en, this message translates to:
  /// **'Swipe or tap the player to show controls'**
  String get playerHintExpand;

  /// No description provided for @sleepTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimerTitle;

  /// No description provided for @sleepTimer5min.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get sleepTimer5min;

  /// No description provided for @sleepTimer10min.
  ///
  /// In en, this message translates to:
  /// **'10 minutes'**
  String get sleepTimer10min;

  /// No description provided for @sleepTimer20min.
  ///
  /// In en, this message translates to:
  /// **'20 minutes'**
  String get sleepTimer20min;

  /// No description provided for @sleepTimer30min.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get sleepTimer30min;

  /// No description provided for @sleepTimer60min.
  ///
  /// In en, this message translates to:
  /// **'60 minutes'**
  String get sleepTimer60min;

  /// No description provided for @sleepTimerOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get sleepTimerOr;

  /// No description provided for @sleepTimerSetExact.
  ///
  /// In en, this message translates to:
  /// **'Set exact time'**
  String get sleepTimerSetExact;

  /// No description provided for @notification_channel_name.
  ///
  /// In en, this message translates to:
  /// **'Radio playback'**
  String get notification_channel_name;

  /// No description provided for @castStopCasting.
  ///
  /// In en, this message translates to:
  /// **'Stop casting'**
  String get castStopCasting;

  /// No description provided for @castDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Casten'**
  String get castDialogTitle;

  /// No description provided for @castNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get castNoDevices;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
