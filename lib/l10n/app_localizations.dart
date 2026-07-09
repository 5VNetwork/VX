import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('zh')
  ];

  /// No description provided for @node.
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get node;

  /// No description provided for @inbound.
  ///
  /// In en, this message translates to:
  /// **'Inbound'**
  String get inbound;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// No description provided for @logLevel.
  ///
  /// In en, this message translates to:
  /// **'Log Level'**
  String get logLevel;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @routing.
  ///
  /// In en, this message translates to:
  /// **'Routing'**
  String get routing;

  /// No description provided for @whileList.
  ///
  /// In en, this message translates to:
  /// **'CN'**
  String get whileList;

  /// No description provided for @gfw.
  ///
  /// In en, this message translates to:
  /// **'GFW'**
  String get gfw;

  /// No description provided for @proxyAll.
  ///
  /// In en, this message translates to:
  /// **'Proxy All'**
  String get proxyAll;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @systemProxy.
  ///
  /// In en, this message translates to:
  /// **'System Proxy'**
  String get systemProxy;

  /// No description provided for @inputManually.
  ///
  /// In en, this message translates to:
  /// **'Input Manually'**
  String get inputManually;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @addNode.
  ///
  /// In en, this message translates to:
  /// **'Add Node'**
  String get addNode;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @clipboard.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get clipboard;

  /// No description provided for @protocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get protocol;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addToHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Add to home screen'**
  String get addToHomeScreen;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @domainStrategy.
  ///
  /// In en, this message translates to:
  /// **'Domain Strategy'**
  String get domainStrategy;

  /// No description provided for @enableMux.
  ///
  /// In en, this message translates to:
  /// **'Enable Mux'**
  String get enableMux;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @ipOrDomain.
  ///
  /// In en, this message translates to:
  /// **'IP / Domain'**
  String get ipOrDomain;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @nodeSelection.
  ///
  /// In en, this message translates to:
  /// **'Node Selection'**
  String get nodeSelection;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @compass.
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get compass;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnecting.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting'**
  String get disconnecting;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @autoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Auto Update'**
  String get autoUpdate;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @speedTest.
  ///
  /// In en, this message translates to:
  /// **'Speed Test'**
  String get speedTest;

  /// No description provided for @statusTest.
  ///
  /// In en, this message translates to:
  /// **'Usable Test'**
  String get statusTest;

  /// No description provided for @selfhost.
  ///
  /// In en, this message translates to:
  /// **'Selfhost'**
  String get selfhost;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get reconnecting;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide from home'**
  String get hide;

  /// No description provided for @gettingNodesSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Getting Nodes/Subscriptions'**
  String get gettingNodesSubscriptions;

  /// No description provided for @emptyClipboard.
  ///
  /// In en, this message translates to:
  /// **'Empty clipboard'**
  String get emptyClipboard;

  /// No description provided for @decodeQrCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to decode QR code'**
  String get decodeQrCode;

  /// No description provided for @proxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get proxy;

  /// No description provided for @direct.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get direct;

  /// No description provided for @promote.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get promote;

  /// No description provided for @domainsOrIps.
  ///
  /// In en, this message translates to:
  /// **'Domains/IPs'**
  String get domainsOrIps;

  /// No description provided for @addProxyDomainIp.
  ///
  /// In en, this message translates to:
  /// **'Add Proxy Domain/IP'**
  String get addProxyDomainIp;

  /// No description provided for @addDirectDomainIp.
  ///
  /// In en, this message translates to:
  /// **'Add Direct Domain/IP'**
  String get addDirectDomainIp;

  /// No description provided for @domain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get domain;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @invalidIp.
  ///
  /// In en, this message translates to:
  /// **'Invalid IP'**
  String get invalidIp;

  /// No description provided for @invalidCidr.
  ///
  /// In en, this message translates to:
  /// **'Invalid CIDR'**
  String get invalidCidr;

  /// No description provided for @exact.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get exact;

  /// No description provided for @regularExpression.
  ///
  /// In en, this message translates to:
  /// **'Regular Expression'**
  String get regularExpression;

  /// No description provided for @keyword.
  ///
  /// In en, this message translates to:
  /// **'Keyword'**
  String get keyword;

  /// No description provided for @rootDomain.
  ///
  /// In en, this message translates to:
  /// **'Root Domain'**
  String get rootDomain;

  /// No description provided for @addServer.
  ///
  /// In en, this message translates to:
  /// **'Add Server'**
  String get addServer;

  /// No description provided for @editServer.
  ///
  /// In en, this message translates to:
  /// **'Edit Server'**
  String get editServer;

  /// No description provided for @sshKey.
  ///
  /// In en, this message translates to:
  /// **'SSH Key'**
  String get sshKey;

  /// No description provided for @selectFromFile.
  ///
  /// In en, this message translates to:
  /// **'Select From File'**
  String get selectFromFile;

  /// No description provided for @sudoPassword.
  ///
  /// In en, this message translates to:
  /// **'Sudo Password'**
  String get sudoPassword;

  /// No description provided for @statusMonitor.
  ///
  /// In en, this message translates to:
  /// **'Status Monitor'**
  String get statusMonitor;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Field Required'**
  String get fieldRequired;

  /// No description provided for @invalidPort.
  ///
  /// In en, this message translates to:
  /// **'Invalid Port'**
  String get invalidPort;

  /// No description provided for @invalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid Address'**
  String get invalidAddress;

  /// No description provided for @failedToAddServer.
  ///
  /// In en, this message translates to:
  /// **'Failed to add server'**
  String get failedToAddServer;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memory;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @serverPubKey.
  ///
  /// In en, this message translates to:
  /// **'Server Public Key'**
  String get serverPubKey;

  /// No description provided for @serverPubKeyHelper.
  ///
  /// In en, this message translates to:
  /// **'If not filled, any public key sent by the server on the first connection will be accepted, then the public key will be used on the future connections.'**
  String get serverPubKeyHelper;

  /// No description provided for @failedConnectServer.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect'**
  String get failedConnectServer;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @keyPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Key Passphrase'**
  String get keyPassphrase;

  /// No description provided for @showRealtimeStatus.
  ///
  /// In en, this message translates to:
  /// **'Show Realtime Status'**
  String get showRealtimeStatus;

  /// No description provided for @hideRealtimeStatus.
  ///
  /// In en, this message translates to:
  /// **'Hide Realtime Status'**
  String get hideRealtimeStatus;

  /// No description provided for @app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get app;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'App Name'**
  String get appName;

  /// No description provided for @prefix.
  ///
  /// In en, this message translates to:
  /// **'Prefix'**
  String get prefix;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @addToProxy.
  ///
  /// In en, this message translates to:
  /// **'Add to Proxy?'**
  String get addToProxy;

  /// No description provided for @addToDirect.
  ///
  /// In en, this message translates to:
  /// **'Add to Direct?'**
  String get addToDirect;

  /// No description provided for @default0.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get default0;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @remainingData.
  ///
  /// In en, this message translates to:
  /// **'Remaining Data'**
  String get remainingData;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @updateInterval.
  ///
  /// In en, this message translates to:
  /// **'Update Interval'**
  String get updateInterval;

  /// No description provided for @testArea.
  ///
  /// In en, this message translates to:
  /// **'Test Area'**
  String get testArea;

  /// No description provided for @autoDownload.
  ///
  /// In en, this message translates to:
  /// **'Automatically Download New Version'**
  String get autoDownload;

  /// No description provided for @unableToGetNodes.
  ///
  /// In en, this message translates to:
  /// **'Failed to get nodes, your pasteboard does not contain a subscription url that VX can parse'**
  String get unableToGetNodes;

  /// No description provided for @unableToGetNodesEmptyClipboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to get nodes, clipboard is empty'**
  String get unableToGetNodesEmptyClipboard;

  /// No description provided for @subscriptionAddress.
  ///
  /// In en, this message translates to:
  /// **'Subscription Address'**
  String get subscriptionAddress;

  /// No description provided for @subscriptionShareLinkQueryExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra link query'**
  String get subscriptionShareLinkQueryExtra;

  /// No description provided for @subscriptionShareLinkQueryExtraHint.
  ///
  /// In en, this message translates to:
  /// **'tx=10&foo=1&sig=a1b2'**
  String get subscriptionShareLinkQueryExtraHint;

  /// No description provided for @subscriptionShareLinkQueryExtraHelper.
  ///
  /// In en, this message translates to:
  /// **'Appended to each node URL before parsing.'**
  String get subscriptionShareLinkQueryExtraHelper;

  /// No description provided for @subscriptionShareLinkQueryExtraInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use a valid JSON object or query string (e.g. key=value&key2=value2)'**
  String get subscriptionShareLinkQueryExtraInvalid;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @invalidHttp.
  ///
  /// In en, this message translates to:
  /// **'Invalid HTTPS URL'**
  String get invalidHttp;

  /// No description provided for @noNode.
  ///
  /// In en, this message translates to:
  /// **'No Node'**
  String get noNode;

  /// No description provided for @failedToChangeOutboundMode.
  ///
  /// In en, this message translates to:
  /// **'Failed to change outbound mode'**
  String get failedToChangeOutboundMode;

  /// No description provided for @failedToChangeFakeDns.
  ///
  /// In en, this message translates to:
  /// **'Failed to change fake dns'**
  String get failedToChangeFakeDns;

  /// No description provided for @failedToChangeRoutingMode.
  ///
  /// In en, this message translates to:
  /// **'Failed to change routing mode'**
  String get failedToChangeRoutingMode;

  /// No description provided for @disableInAuto.
  ///
  /// In en, this message translates to:
  /// **'Disable in auto mode'**
  String get disableInAuto;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @remark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get remark;

  /// No description provided for @remarkAddress.
  ///
  /// In en, this message translates to:
  /// **'Remark & Address'**
  String get remarkAddress;

  /// No description provided for @usable.
  ///
  /// In en, this message translates to:
  /// **'Usable'**
  String get usable;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @latency.
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get latency;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @selectOneOutbound.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectOneOutbound;

  /// No description provided for @addFailedUniqueConstraint.
  ///
  /// In en, this message translates to:
  /// **'Addition failed because the rule confilcts with an existing rule.'**
  String get addFailedUniqueConstraint;

  /// No description provided for @enableInAuto.
  ///
  /// In en, this message translates to:
  /// **'Enable in auto mode'**
  String get enableInAuto;

  /// No description provided for @homeCustomizeDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag cards to reorder. Hidden cards move to the bottom tray.'**
  String get homeCustomizeDragHint;

  /// No description provided for @homeCustomizeResetOrder.
  ///
  /// In en, this message translates to:
  /// **'Reset order'**
  String get homeCustomizeResetOrder;

  /// No description provided for @homeCustomizeHiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get homeCustomizeHiddenTitle;

  /// No description provided for @homeCustomizeDropHere.
  ///
  /// In en, this message translates to:
  /// **'Drop here to add at bottom'**
  String get homeCustomizeDropHere;

  /// No description provided for @homeCustomizeMergeWith.
  ///
  /// In en, this message translates to:
  /// **'Merge with…'**
  String get homeCustomizeMergeWith;

  /// No description provided for @homeCustomizeNoMergeTargets.
  ///
  /// In en, this message translates to:
  /// **'No mergeable widgets'**
  String get homeCustomizeNoMergeTargets;

  /// No description provided for @compact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get compact;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @large.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// No description provided for @showClient.
  ///
  /// In en, this message translates to:
  /// **'Show Client'**
  String get showClient;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @disconnectedUnexpectedly.
  ///
  /// In en, this message translates to:
  /// **'Disconnected unexpectedly. Reason: {reason}'**
  String disconnectedUnexpectedly(String reason);

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// No description provided for @iosAppRoutingNoSupport.
  ///
  /// In en, this message translates to:
  /// **'App-based routing is currently not supported on iOS'**
  String get iosAppRoutingNoSupport;

  /// No description provided for @failedToChangeInboundMode.
  ///
  /// In en, this message translates to:
  /// **'Failed to change inbound'**
  String get failedToChangeInboundMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @mannual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get mannual;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at'**
  String get updatedAt;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'{value} {value, plural, =0{Minutes} =1{Minute} other{Minutes}}'**
  String min(num value);

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'{value} {value, plural, =0{Hours} =1{Hour} other{Hours}}'**
  String hour(num value);

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @openSourceSoftwareNotice.
  ///
  /// In en, this message translates to:
  /// **'Open Source Software Notice'**
  String get openSourceSoftwareNotice;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @privacyPolicySummary.
  ///
  /// In en, this message translates to:
  /// **'VX only collects diagnostic logs if the switch button below is on. These logs do not contain personal data. Please click the button below to view the detailed privacy policy.'**
  String get privacyPolicySummary;

  /// No description provided for @diagnosticLogDoesNotContainPersonalData.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic logs does not link to you, and does not contain personal data'**
  String get diagnosticLogDoesNotContainPersonalData;

  /// No description provided for @shareDiagnosticLogWithDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Share diagnostic logs with developers'**
  String get shareDiagnosticLogWithDeveloper;

  /// No description provided for @shareCnDirectAppsWithDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Help improve CN routing (share direct app list)'**
  String get shareCnDirectAppsWithDeveloper;

  /// No description provided for @shareCnDirectAppsDescription.
  ///
  /// In en, this message translates to:
  /// **'When enabled, package names and app labels from your Direct app set are sent anonymously to help build a list of China apps. This is done after you have finished editing your Direct app set. The data uploaded is not linked to you.'**
  String get shareCnDirectAppsDescription;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @contactUsSummary.
  ///
  /// In en, this message translates to:
  /// **'You can contact us by the following ways. Thank you!'**
  String get contactUsSummary;

  /// No description provided for @contactUsFreely.
  ///
  /// In en, this message translates to:
  /// **'If you have any questions or need any features, please contact us.'**
  String get contactUsFreely;

  /// No description provided for @contactUsProPriority.
  ///
  /// In en, this message translates to:
  /// **'If you are a Pro user, please let us know when contacting us — we prioritize Pro users\' inquiries.'**
  String get contactUsProPriority;

  /// No description provided for @bugAreWelcome.
  ///
  /// In en, this message translates to:
  /// **'Bug reports and suggestions are welcome, thanks very much!'**
  String get bugAreWelcome;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @sourceCodeUrl.
  ///
  /// In en, this message translates to:
  /// **'URL to source code'**
  String get sourceCodeUrl;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @loginWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Login'**
  String get loginWithEmail;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get loginWithGoogle;

  /// No description provided for @loginWithApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get loginWithApple;

  /// No description provided for @loginWithMicrosoft.
  ///
  /// In en, this message translates to:
  /// **'Microsoft'**
  String get loginWithMicrosoft;

  /// No description provided for @newUserTrialText.
  ///
  /// In en, this message translates to:
  /// **'New users can try Pro for 7 days for free'**
  String get newUserTrialText;

  /// No description provided for @proExpiredAt.
  ///
  /// In en, this message translates to:
  /// **'Pro Expiry'**
  String get proExpiredAt;

  /// No description provided for @addGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Group'**
  String get addGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @deleteGroupAndNodes.
  ///
  /// In en, this message translates to:
  /// **'Delete Group and Nodes'**
  String get deleteGroupAndNodes;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @addToGroup.
  ///
  /// In en, this message translates to:
  /// **'Add to Group'**
  String get addToGroup;

  /// No description provided for @addToAppSet.
  ///
  /// In en, this message translates to:
  /// **'Add to App Set'**
  String get addToAppSet;

  /// No description provided for @addToDomainSet.
  ///
  /// In en, this message translates to:
  /// **'Add to Domain Set'**
  String get addToDomainSet;

  /// No description provided for @addToIpSet.
  ///
  /// In en, this message translates to:
  /// **'Add to IP Set'**
  String get addToIpSet;

  /// No description provided for @logDnsResolver.
  ///
  /// In en, this message translates to:
  /// **'DNS: {resolver}'**
  String logDnsResolver(String resolver);

  /// No description provided for @addApp.
  ///
  /// In en, this message translates to:
  /// **'Add App'**
  String get addApp;

  /// No description provided for @noSelectedNode.
  ///
  /// In en, this message translates to:
  /// **'No selected node'**
  String get noSelectedNode;

  /// No description provided for @pleaseSelectNode.
  ///
  /// In en, this message translates to:
  /// **'Please select a node'**
  String get pleaseSelectNode;

  /// No description provided for @pleaseSelectSelector.
  ///
  /// In en, this message translates to:
  /// **'Please select a selector'**
  String get pleaseSelectSelector;

  /// No description provided for @pleaseEnterRuleName.
  ///
  /// In en, this message translates to:
  /// **'Please enter rule name'**
  String get pleaseEnterRuleName;

  /// No description provided for @ruleName.
  ///
  /// In en, this message translates to:
  /// **'Matched Rule Name'**
  String get ruleName;

  /// No description provided for @matchAll.
  ///
  /// In en, this message translates to:
  /// **'Match All'**
  String get matchAll;

  /// No description provided for @ruleMatchCondition.
  ///
  /// In en, this message translates to:
  /// **'When any condition is true, the rule matches. If there is no condition, the rule will never match.'**
  String get ruleMatchCondition;

  /// No description provided for @conditionMatch.
  ///
  /// In en, this message translates to:
  /// **'When all subconditions are true, the condition is true. If there are zero subconditions, the condition is false.'**
  String get conditionMatch;

  /// No description provided for @inboundLabel.
  ///
  /// In en, this message translates to:
  /// **'Inbound'**
  String get inboundLabel;

  /// No description provided for @domainSet.
  ///
  /// In en, this message translates to:
  /// **'Domain Set'**
  String get domainSet;

  /// No description provided for @appSet.
  ///
  /// In en, this message translates to:
  /// **'App Set'**
  String get appSet;

  /// No description provided for @ipSet.
  ///
  /// In en, this message translates to:
  /// **'IP Set'**
  String get ipSet;

  /// No description provided for @addRouterRule.
  ///
  /// In en, this message translates to:
  /// **'Add Router Rule'**
  String get addRouterRule;

  /// No description provided for @addDnsRule.
  ///
  /// In en, this message translates to:
  /// **'Add DNS Rule'**
  String get addDnsRule;

  /// No description provided for @editRule.
  ///
  /// In en, this message translates to:
  /// **'Edit Rule'**
  String get editRule;

  /// No description provided for @addRouter.
  ///
  /// In en, this message translates to:
  /// **'Add Route Mode'**
  String get addRouter;

  /// No description provided for @copyDefault.
  ///
  /// In en, this message translates to:
  /// **'Copy Default'**
  String get copyDefault;

  /// No description provided for @ruleOrder.
  ///
  /// In en, this message translates to:
  /// **'Rules are matched from top to bottom'**
  String get ruleOrder;

  /// No description provided for @nodeChain.
  ///
  /// In en, this message translates to:
  /// **'Node Chain'**
  String get nodeChain;

  /// No description provided for @nodeChainDesc.
  ///
  /// In en, this message translates to:
  /// **'Nodes selected by this selector will form a node chain with the below nodes. The last node in the below list is the landing node. [Your Traffic] -> [Node(s) selected by the selector] -> [First node in the below list] -> ... -> [Last node in the below list] -> [Final destination]'**
  String get nodeChainDesc;

  /// No description provided for @addSelector.
  ///
  /// In en, this message translates to:
  /// **'Add Selector'**
  String get addSelector;

  /// No description provided for @selectorNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Selector name cannot be duplicated'**
  String get selectorNameDuplicate;

  /// No description provided for @renameSelector.
  ///
  /// In en, this message translates to:
  /// **'Rename Selector'**
  String get renameSelector;

  /// No description provided for @allNodes.
  ///
  /// In en, this message translates to:
  /// **'All Nodes'**
  String get allNodes;

  /// No description provided for @partialNodes.
  ///
  /// In en, this message translates to:
  /// **'Partial Nodes'**
  String get partialNodes;

  /// No description provided for @nodeGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get nodeGroup;

  /// No description provided for @lowestLatency.
  ///
  /// In en, this message translates to:
  /// **'Lowest Latency'**
  String get lowestLatency;

  /// No description provided for @lowLatency.
  ///
  /// In en, this message translates to:
  /// **'Low Latency'**
  String get lowLatency;

  /// No description provided for @highThroughput.
  ///
  /// In en, this message translates to:
  /// **'High Speed'**
  String get highThroughput;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @setNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Set name cannot be duplicated'**
  String get setNameDuplicate;

  /// No description provided for @mutuallyExclusiveSetName.
  ///
  /// In en, this message translates to:
  /// **'Mutually Exclusive Set Name'**
  String get mutuallyExclusiveSetName;

  /// No description provided for @include.
  ///
  /// In en, this message translates to:
  /// **'Include'**
  String get include;

  /// No description provided for @exclude.
  ///
  /// In en, this message translates to:
  /// **'Exclude'**
  String get exclude;

  /// No description provided for @simple.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get simple;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @customDirect.
  ///
  /// In en, this message translates to:
  /// **'Custom Direct'**
  String get customDirect;

  /// No description provided for @customProxy.
  ///
  /// In en, this message translates to:
  /// **'Custom Proxy'**
  String get customProxy;

  /// No description provided for @cnGames.
  ///
  /// In en, this message translates to:
  /// **'CN Games'**
  String get cnGames;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @gfwWithoutCustomDirect.
  ///
  /// In en, this message translates to:
  /// **'GFW (without custom direct)'**
  String get gfwWithoutCustomDirect;

  /// No description provided for @gfwModeProxyDomains.
  ///
  /// In en, this message translates to:
  /// **'GFW Mode Proxy Domains'**
  String get gfwModeProxyDomains;

  /// No description provided for @gfwModeProxyIps.
  ///
  /// In en, this message translates to:
  /// **'GFW Mode Proxy IPs'**
  String get gfwModeProxyIps;

  /// No description provided for @cnModeProxyDomains.
  ///
  /// In en, this message translates to:
  /// **'CN Mode Proxy Domains'**
  String get cnModeProxyDomains;

  /// No description provided for @cnModeDirectDomains.
  ///
  /// In en, this message translates to:
  /// **'CN Mode Direct Domains'**
  String get cnModeDirectDomains;

  /// No description provided for @cnModeDirectIps.
  ///
  /// In en, this message translates to:
  /// **'CN Mode Direct IPs'**
  String get cnModeDirectIps;

  /// No description provided for @proxyAllModeProxyDomains.
  ///
  /// In en, this message translates to:
  /// **'Proxy-All Mode Proxy Domains'**
  String get proxyAllModeProxyDomains;

  /// No description provided for @proxyAllModeDirectDomains.
  ///
  /// In en, this message translates to:
  /// **'Proxy-All Mode Direct Domains'**
  String get proxyAllModeDirectDomains;

  /// No description provided for @proxyAllModeDirectIps.
  ///
  /// In en, this message translates to:
  /// **'Proxy-All Mode Direct IPs'**
  String get proxyAllModeDirectIps;

  /// No description provided for @ruBlockModeProxyDomains.
  ///
  /// In en, this message translates to:
  /// **'RU-Block Mode Proxy Domains'**
  String get ruBlockModeProxyDomains;

  /// No description provided for @ruBlockModeProxyIps.
  ///
  /// In en, this message translates to:
  /// **'RU-Block Mode Proxy IPs'**
  String get ruBlockModeProxyIps;

  /// No description provided for @ruBlockAllModeProxyDomains.
  ///
  /// In en, this message translates to:
  /// **'RU-Block(All) Mode Proxy Domains'**
  String get ruBlockAllModeProxyDomains;

  /// No description provided for @ruBlockAllModeProxyIps.
  ///
  /// In en, this message translates to:
  /// **'RU-Block(All) Mode Proxy IPs'**
  String get ruBlockAllModeProxyIps;

  /// No description provided for @ipToDomain.
  ///
  /// In en, this message translates to:
  /// **'IP -> Domain'**
  String get ipToDomain;

  /// No description provided for @showSessionOngoingIndicator.
  ///
  /// In en, this message translates to:
  /// **'Show session ongoing indicator'**
  String get showSessionOngoingIndicator;

  /// No description provided for @hideSessionOngoingIndicator.
  ///
  /// In en, this message translates to:
  /// **'Hide session ongoing indicator'**
  String get hideSessionOngoingIndicator;

  /// No description provided for @showRealtimeUsage.
  ///
  /// In en, this message translates to:
  /// **'Show realtime usage'**
  String get showRealtimeUsage;

  /// No description provided for @hideRealtimeUsage.
  ///
  /// In en, this message translates to:
  /// **'Hide realtime usage'**
  String get hideRealtimeUsage;

  /// No description provided for @proFeatureDescription.
  ///
  /// In en, this message translates to:
  /// **'This is a Pro feature. Upgrade to Pro to unlock all features'**
  String get proFeatureDescription;

  /// No description provided for @becomePermanentPro.
  ///
  /// In en, this message translates to:
  /// **'Become Permanent Pro User'**
  String get becomePermanentPro;

  /// No description provided for @becomePermanentProDescription.
  ///
  /// In en, this message translates to:
  /// **'Become permanent Pro user'**
  String get becomePermanentProDescription;

  /// No description provided for @tryPro.
  ///
  /// In en, this message translates to:
  /// **'Try Pro'**
  String get tryPro;

  /// No description provided for @newUserProTrial.
  ///
  /// In en, this message translates to:
  /// **'New users can try Pro for 7 days'**
  String get newUserProTrial;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @purchaseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase Cancelled'**
  String get purchaseCancelled;

  /// No description provided for @verifyingPurchase.
  ///
  /// In en, this message translates to:
  /// **'Verifying Purchase...'**
  String get verifyingPurchase;

  /// No description provided for @restoringPurchase.
  ///
  /// In en, this message translates to:
  /// **'Restoring Purchase...'**
  String get restoringPurchase;

  /// No description provided for @purchaseVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify purchase: {reason}'**
  String purchaseVerificationFailed(String reason);

  /// No description provided for @ifYouHavePaid.
  ///
  /// In en, this message translates to:
  /// **'If you have paid, don\'t worry, your payment will be automatically refunded by the store. If you have any questions, please contact us. Order ID: {orderId}'**
  String ifYouHavePaid(String orderId);

  /// No description provided for @invalidPurchase.
  ///
  /// In en, this message translates to:
  /// **'Invalid Purchase'**
  String get invalidPurchase;

  /// No description provided for @purchaseSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Purchase Successful'**
  String get purchaseSuccessful;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed: {status}'**
  String purchaseFailed(String status);

  /// No description provided for @unableToConnectToStore.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to store'**
  String get unableToConnectToStore;

  /// No description provided for @loginBeforePurchase.
  ///
  /// In en, this message translates to:
  /// **'Please login before purchasing. New users can try Pro for 7 days'**
  String get loginBeforePurchase;

  /// No description provided for @loginBeforeRestore.
  ///
  /// In en, this message translates to:
  /// **'Please login before restoring purchase.'**
  String get loginBeforeRestore;

  /// No description provided for @visitWebsiteToPurchasePro.
  ///
  /// In en, this message translates to:
  /// **'Please visit our website to purchase Pro'**
  String get visitWebsiteToPurchasePro;

  /// No description provided for @upgradeToPermanentPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPermanentPro;

  /// No description provided for @caseInsensitive.
  ///
  /// In en, this message translates to:
  /// **'Case Insensitive'**
  String get caseInsensitive;

  /// No description provided for @startFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start'**
  String get startFailed;

  /// No description provided for @startFailedWithReason.
  ///
  /// In en, this message translates to:
  /// **'Failed to start: {reason}. StackTrace: {stackTrace}'**
  String startFailedWithReason(String reason, String stackTrace);

  /// No description provided for @startFailedReasonTunNeedAdmin.
  ///
  /// In en, this message translates to:
  /// **'To use TUN mode, please run VX as an administrator or install Service (the installation button is in Settings page)'**
  String get startFailedReasonTunNeedAdmin;

  /// No description provided for @startFailedReasonNoNode.
  ///
  /// In en, this message translates to:
  /// **'No node'**
  String get startFailedReasonNoNode;

  /// No description provided for @startFailedReasonNoEnabledNode.
  ///
  /// In en, this message translates to:
  /// **'No enabled nodes, enable at least one node'**
  String get startFailedReasonNoEnabledNode;

  /// No description provided for @startFailedReasonNoSelected.
  ///
  /// In en, this message translates to:
  /// **'No selected node'**
  String get startFailedReasonNoSelected;

  /// No description provided for @failedToUpdateSub.
  ///
  /// In en, this message translates to:
  /// **'Failed to update subscription: {value}'**
  String failedToUpdateSub(String value);

  /// No description provided for @failedToAddSubscription.
  ///
  /// In en, this message translates to:
  /// **'Failed to add subscription, there is an existing subscription with the same link'**
  String get failedToAddSubscription;

  /// No description provided for @tunNeedAdmin.
  ///
  /// In en, this message translates to:
  /// **'To use tun, rerun VX as administrator'**
  String get tunNeedAdmin;

  /// No description provided for @windowsServiceRequiresAdmin.
  ///
  /// In en, this message translates to:
  /// **'This action requires administrator permission. Restart VX as administrator and try again.'**
  String get windowsServiceRequiresAdmin;

  /// No description provided for @windowsServiceInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'VX Service installation failed: {error}'**
  String windowsServiceInstallFailed(String error);

  /// No description provided for @windowsServiceInstalled.
  ///
  /// In en, this message translates to:
  /// **'Windows service installed'**
  String get windowsServiceInstalled;

  /// No description provided for @windowsServiceRemoved.
  ///
  /// In en, this message translates to:
  /// **'Windows service removed'**
  String get windowsServiceRemoved;

  /// No description provided for @windowsServiceInstall.
  ///
  /// In en, this message translates to:
  /// **'Install VX Service'**
  String get windowsServiceInstall;

  /// No description provided for @windowsServiceRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove VX Service'**
  String get windowsServiceRemove;

  /// No description provided for @decodeResult.
  ///
  /// In en, this message translates to:
  /// **'Successfully got {value1} {value1, plural, =1{node} other{nodes}}, {value2} {value2, plural, =1{node failed} other{nodes failed}}'**
  String decodeResult(num value1, num value2);

  /// No description provided for @updateSubResult.
  ///
  /// In en, this message translates to:
  /// **'Successfully updated {value1} {value1, plural, =1{subscription} other{subscriptions}}, {value2} {value2, plural, =1{subscription} other{subscriptions}} failed. {value3} {value3, plural, =1{node} other{nodes}} added, {value4} {value4, plural, =1{node} other{nodes}} failed to parse'**
  String updateSubResult(num value1, num value2, num value3, num value4);

  /// No description provided for @failedToUpdateCountry.
  ///
  /// In en, this message translates to:
  /// **'Failed to update areas'**
  String get failedToUpdateCountry;

  /// No description provided for @keepAlivePeriodMustBeBetween2And60.
  ///
  /// In en, this message translates to:
  /// **'Need to be between 2 and 60'**
  String get keepAlivePeriodMustBeBetween2And60;

  /// No description provided for @showApp.
  ///
  /// In en, this message translates to:
  /// **'Show App'**
  String get showApp;

  /// No description provided for @hideApp.
  ///
  /// In en, this message translates to:
  /// **'Hide App'**
  String get hideApp;

  /// No description provided for @showSystemApps.
  ///
  /// In en, this message translates to:
  /// **'Show System Apps'**
  String get showSystemApps;

  /// No description provided for @hideSystemApps.
  ///
  /// In en, this message translates to:
  /// **'Hide System Apps'**
  String get hideSystemApps;

  /// No description provided for @doubleTapToDelete.
  ///
  /// In en, this message translates to:
  /// **'Double tap to delete'**
  String get doubleTapToDelete;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @sshKeyPath.
  ///
  /// In en, this message translates to:
  /// **'SSH Key File Path'**
  String get sshKeyPath;

  /// No description provided for @useCommonSshKey.
  ///
  /// In en, this message translates to:
  /// **'Use Added SSH Key'**
  String get useCommonSshKey;

  /// No description provided for @addCommonSshKey.
  ///
  /// In en, this message translates to:
  /// **'Add SSH Key'**
  String get addCommonSshKey;

  /// No description provided for @sshKeyContentOrPathRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one of SSH Key Content or SSH Key File Path is required'**
  String get sshKeyContentOrPathRequired;

  /// No description provided for @failedToAddCommonSshKey.
  ///
  /// In en, this message translates to:
  /// **'Failed to add SSH key'**
  String get failedToAddCommonSshKey;

  /// No description provided for @failedToAddCommonSshKeyDueToDuplicateName.
  ///
  /// In en, this message translates to:
  /// **'Failed to add SSH key because there is a key with the same name'**
  String get failedToAddCommonSshKeyDueToDuplicateName;

  /// No description provided for @quickDeploy.
  ///
  /// In en, this message translates to:
  /// **'Quick Deploy'**
  String get quickDeploy;

  /// No description provided for @deploy.
  ///
  /// In en, this message translates to:
  /// **'Deploy'**
  String get deploy;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deploySuccess.
  ///
  /// In en, this message translates to:
  /// **'{deploy} on Server-{server} succeeded'**
  String deploySuccess(String deploy, String server);

  /// No description provided for @bbrError.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable BBR: {error}'**
  String bbrError(String error);

  /// No description provided for @firewallError.
  ///
  /// In en, this message translates to:
  /// **'Failed to disable OS firewall: {error}'**
  String firewallError(String error);

  /// No description provided for @failedToDeploy.
  ///
  /// In en, this message translates to:
  /// **'Failed to deploy: {value}'**
  String failedToDeploy(String value);

  /// No description provided for @peerCertChainSHA256Hash.
  ///
  /// In en, this message translates to:
  /// **'SHA256'**
  String get peerCertChainSHA256Hash;

  /// No description provided for @serverCA.
  ///
  /// In en, this message translates to:
  /// **'Root CA'**
  String get serverCA;

  /// No description provided for @failedToInitGrpcClient.
  ///
  /// In en, this message translates to:
  /// **'Failed to init grpc client: {value}'**
  String failedToInitGrpcClient(String value);

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @failure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get failure;

  /// No description provided for @appKeyword.
  ///
  /// In en, this message translates to:
  /// **'App Keyword'**
  String get appKeyword;

  /// No description provided for @sniffDomain.
  ///
  /// In en, this message translates to:
  /// **'Sniff Domain'**
  String get sniffDomain;

  /// No description provided for @trafficStats.
  ///
  /// In en, this message translates to:
  /// **'Traffic Stats'**
  String get trafficStats;

  /// No description provided for @useSshKey.
  ///
  /// In en, this message translates to:
  /// **'Use SSH Key'**
  String get useSshKey;

  /// No description provided for @errorOnly.
  ///
  /// In en, this message translates to:
  /// **'Error Only'**
  String get errorOnly;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @failedToUndoBlockDns.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove the WFP filter for blocking dns traffic of primary NIC, please close this app which can remove the filter'**
  String get failedToUndoBlockDns;

  /// No description provided for @failedToRemoveSystemProxy.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove system proxy, please remove it mannually at Settings > System Proxy.'**
  String get failedToRemoveSystemProxy;

  /// No description provided for @failedToChangeNode.
  ///
  /// In en, this message translates to:
  /// **'Failed to change node: {value}'**
  String failedToChangeNode(String value);

  /// No description provided for @failureDetail.
  ///
  /// In en, this message translates to:
  /// **'Failure detail'**
  String get failureDetail;

  /// No description provided for @failedNodes.
  ///
  /// In en, this message translates to:
  /// **'Failed nodes'**
  String get failedNodes;

  /// No description provided for @failedSub.
  ///
  /// In en, this message translates to:
  /// **'Failed subscriptions'**
  String get failedSub;

  /// No description provided for @addRemark.
  ///
  /// In en, this message translates to:
  /// **'Add a remark?'**
  String get addRemark;

  /// No description provided for @multiSelect.
  ///
  /// In en, this message translates to:
  /// **'Multi Select'**
  String get multiSelect;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @quickAction.
  ///
  /// In en, this message translates to:
  /// **'Quick Action'**
  String get quickAction;

  /// No description provided for @deleteUnusable.
  ///
  /// In en, this message translates to:
  /// **'Delete Unusable Nodes'**
  String get deleteUnusable;

  /// No description provided for @smallScreenPreference.
  ///
  /// In en, this message translates to:
  /// **'Small Screen Preference'**
  String get smallScreenPreference;

  /// No description provided for @chainProxy.
  ///
  /// In en, this message translates to:
  /// **'Chain Proxy'**
  String get chainProxy;

  /// No description provided for @singleNode.
  ///
  /// In en, this message translates to:
  /// **'Single Node'**
  String get singleNode;

  /// No description provided for @multipleNodes.
  ///
  /// In en, this message translates to:
  /// **'Multiple Nodes'**
  String get multipleNodes;

  /// No description provided for @balanceStrategy.
  ///
  /// In en, this message translates to:
  /// **'Balance Strategy'**
  String get balanceStrategy;

  /// No description provided for @manualNodeMode.
  ///
  /// In en, this message translates to:
  /// **'Manual Mode'**
  String get manualNodeMode;

  /// No description provided for @outboundMode.
  ///
  /// In en, this message translates to:
  /// **'Outbound'**
  String get outboundMode;

  /// No description provided for @random.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get random;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @balanceStrategyMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get balanceStrategyMemory;

  /// No description provided for @selectingStrategy.
  ///
  /// In en, this message translates to:
  /// **'Select Strategy'**
  String get selectingStrategy;

  /// No description provided for @mostThroughput.
  ///
  /// In en, this message translates to:
  /// **'Speed Highest'**
  String get mostThroughput;

  /// No description provided for @allOk.
  ///
  /// In en, this message translates to:
  /// **'Usable'**
  String get allOk;

  /// No description provided for @yourDevices.
  ///
  /// In en, this message translates to:
  /// **'Your Devices'**
  String get yourDevices;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @addNewNode.
  ///
  /// In en, this message translates to:
  /// **'Add New Node'**
  String get addNewNode;

  /// No description provided for @useExistingNode.
  ///
  /// In en, this message translates to:
  /// **'Use Existing Node'**
  String get useExistingNode;

  /// No description provided for @atLeastTwoNodes.
  ///
  /// In en, this message translates to:
  /// **'At least two nodes are required'**
  String get atLeastTwoNodes;

  /// No description provided for @advancedMode.
  ///
  /// In en, this message translates to:
  /// **'Pro Mode'**
  String get advancedMode;

  /// No description provided for @simpleMode.
  ///
  /// In en, this message translates to:
  /// **'Simple Mode'**
  String get simpleMode;

  /// No description provided for @rule.
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get rule;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @selector.
  ///
  /// In en, this message translates to:
  /// **'Selector'**
  String get selector;

  /// No description provided for @atmoicDomainSet.
  ///
  /// In en, this message translates to:
  /// **'Small Domain Set'**
  String get atmoicDomainSet;

  /// No description provided for @greatDomainSet.
  ///
  /// In en, this message translates to:
  /// **'Large Domain Set'**
  String get greatDomainSet;

  /// No description provided for @atmoicIpSet.
  ///
  /// In en, this message translates to:
  /// **'Small IP Set'**
  String get atmoicIpSet;

  /// No description provided for @greatIpSet.
  ///
  /// In en, this message translates to:
  /// **'Large IP Set'**
  String get greatIpSet;

  /// No description provided for @createGreatDomainSet.
  ///
  /// In en, this message translates to:
  /// **'Create Great Domain Set'**
  String get createGreatDomainSet;

  /// No description provided for @editGreatDomainSet.
  ///
  /// In en, this message translates to:
  /// **'Edit Great Domain Set'**
  String get editGreatDomainSet;

  /// No description provided for @createSmallDomainSet.
  ///
  /// In en, this message translates to:
  /// **'Create Small Domain Set'**
  String get createSmallDomainSet;

  /// No description provided for @editSmallDomainSet.
  ///
  /// In en, this message translates to:
  /// **'Edit Small Domain Set'**
  String get editSmallDomainSet;

  /// No description provided for @editGreatIpSet.
  ///
  /// In en, this message translates to:
  /// **'Edit Great IP Set'**
  String get editGreatIpSet;

  /// No description provided for @createGreatIpSet.
  ///
  /// In en, this message translates to:
  /// **'Create Great IP Set'**
  String get createGreatIpSet;

  /// No description provided for @editAppSet.
  ///
  /// In en, this message translates to:
  /// **'Edit App Set'**
  String get editAppSet;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @range.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get range;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @geoSiteOrGeoIPFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Downloading needed geo files...'**
  String get geoSiteOrGeoIPFileNotFound;

  /// No description provided for @createIpSmallSet.
  ///
  /// In en, this message translates to:
  /// **'Create IP Small Set'**
  String get createIpSmallSet;

  /// No description provided for @editIpSmallSet.
  ///
  /// In en, this message translates to:
  /// **'Edit IP Small Set'**
  String get editIpSmallSet;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @domainSetDescription.
  ///
  /// In en, this message translates to:
  /// **'The following domain set uses proxy DNS server (default 8.8.8.8 and 1.1.1.1) to resolve, other domains use direct DNS server (default is dns servers of your primary physical nic, or 223.5.5.5 and 114.114.114.114 if the former cannot be known) to resolve'**
  String get domainSetDescription;

  /// No description provided for @routerRuleDescription.
  ///
  /// In en, this message translates to:
  /// **'For each connection, rules are matched one by one from top to bottom, if a rule matches, the following rules will not be considered. If no rule matches, the connection will abort.'**
  String get routerRuleDescription;

  /// No description provided for @dstIpSet.
  ///
  /// In en, this message translates to:
  /// **'Destination IP Set'**
  String get dstIpSet;

  /// No description provided for @ruleNameVXTestNodes.
  ///
  /// In en, this message translates to:
  /// **'VX Node Testing'**
  String get ruleNameVXTestNodes;

  /// No description provided for @ruleNameInternalDnsProxyGoProxy.
  ///
  /// In en, this message translates to:
  /// **'Internal DNS (CF)'**
  String get ruleNameInternalDnsProxyGoProxy;

  /// No description provided for @ruleNameInternalDnsDirectGoDirect.
  ///
  /// In en, this message translates to:
  /// **'Internal DNS (Aliyun & CF)'**
  String get ruleNameInternalDnsDirectGoDirect;

  /// No description provided for @ruleNameProxyDnsServerGoProxy.
  ///
  /// In en, this message translates to:
  /// **'Default Proxy DNS Server'**
  String get ruleNameProxyDnsServerGoProxy;

  /// No description provided for @ruleNameDirectDnsServerGoDirect.
  ///
  /// In en, this message translates to:
  /// **'Default Direct DNS Server'**
  String get ruleNameDirectDnsServerGoDirect;

  /// No description provided for @ruleNameDnsHijack.
  ///
  /// In en, this message translates to:
  /// **'DNS Hijack: Non-Direct Domain'**
  String get ruleNameDnsHijack;

  /// No description provided for @ruleNameCustomDirectDomain.
  ///
  /// In en, this message translates to:
  /// **'Custom Direct Domain'**
  String get ruleNameCustomDirectDomain;

  /// No description provided for @ruleNameCustomDirectIp.
  ///
  /// In en, this message translates to:
  /// **'Custom Direct IP'**
  String get ruleNameCustomDirectIp;

  /// No description provided for @ruleNameCustomProxyDomain.
  ///
  /// In en, this message translates to:
  /// **'Custom Proxy Domain'**
  String get ruleNameCustomProxyDomain;

  /// No description provided for @ruleNameCustomProxyIp.
  ///
  /// In en, this message translates to:
  /// **'Custom Proxy IP'**
  String get ruleNameCustomProxyIp;

  /// No description provided for @ruleNameProxyApp.
  ///
  /// In en, this message translates to:
  /// **'Proxy App'**
  String get ruleNameProxyApp;

  /// No description provided for @ruleNameDirectApp.
  ///
  /// In en, this message translates to:
  /// **'Direct App'**
  String get ruleNameDirectApp;

  /// No description provided for @ruleNameCnDirectIp.
  ///
  /// In en, this message translates to:
  /// **'CN Mode Direct IPs'**
  String get ruleNameCnDirectIp;

  /// No description provided for @ruleNameDefaultProxy.
  ///
  /// In en, this message translates to:
  /// **'Default Proxy'**
  String get ruleNameDefaultProxy;

  /// No description provided for @ruleNameCnDirectDomain.
  ///
  /// In en, this message translates to:
  /// **'CN Mode Direct Domains'**
  String get ruleNameCnDirectDomain;

  /// No description provided for @ruleNameGfwProxyDomain.
  ///
  /// In en, this message translates to:
  /// **'GFW Mode Proxy Domains'**
  String get ruleNameGfwProxyDomain;

  /// No description provided for @ruleNameGfwProxyIp.
  ///
  /// In en, this message translates to:
  /// **'GFW Mode Proxy IPs'**
  String get ruleNameGfwProxyIp;

  /// No description provided for @ruleNameRuBlockProxyDomain.
  ///
  /// In en, this message translates to:
  /// **'RU-Block Mode Proxy Domains'**
  String get ruleNameRuBlockProxyDomain;

  /// No description provided for @ruleNameRuBlockProxyIp.
  ///
  /// In en, this message translates to:
  /// **'RU-Block Mode Proxy IPs'**
  String get ruleNameRuBlockProxyIp;

  /// No description provided for @ruleNameRuBlockAllProxyDomain.
  ///
  /// In en, this message translates to:
  /// **'RU-Block(All) Mode Proxy Domains'**
  String get ruleNameRuBlockAllProxyDomain;

  /// No description provided for @ruleNameRuBlockAllProxyIp.
  ///
  /// In en, this message translates to:
  /// **'RU-Block(All) Mode Proxy IPs'**
  String get ruleNameRuBlockAllProxyIp;

  /// No description provided for @ruleNameDefaultDirect.
  ///
  /// In en, this message translates to:
  /// **'Default Direct'**
  String get ruleNameDefaultDirect;

  /// No description provided for @ruleNameGlobalDirectDomain.
  ///
  /// In en, this message translates to:
  /// **'Proxy-All Mode Direct Domains'**
  String get ruleNameGlobalDirectDomain;

  /// No description provided for @ruleNameGlobalDirectIp.
  ///
  /// In en, this message translates to:
  /// **'Proxy-All Mode Direct IPs'**
  String get ruleNameGlobalDirectIp;

  /// No description provided for @addAppSet.
  ///
  /// In en, this message translates to:
  /// **'Add App Set'**
  String get addAppSet;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Pro Account'**
  String get pro;

  /// No description provided for @proxyShare.
  ///
  /// In en, this message translates to:
  /// **'Proxy Share'**
  String get proxyShare;

  /// No description provided for @sniff.
  ///
  /// In en, this message translates to:
  /// **'Sniff'**
  String get sniff;

  /// No description provided for @proxyShareDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable HTTP and SOCKS inbound after VPN starts, so that other devices in the local network can access the internet through this machine. The inbound name is \"proxyShare\", which you can use in rules.'**
  String get proxyShareDesc;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login Success'**
  String get loginSuccess;

  /// No description provided for @emailLogin.
  ///
  /// In en, this message translates to:
  /// **'Login by Email'**
  String get emailLogin;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @apple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// No description provided for @microsoft.
  ///
  /// In en, this message translates to:
  /// **'Microsoft'**
  String get microsoft;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate VX'**
  String get rateApp;

  /// No description provided for @userConsend.
  ///
  /// In en, this message translates to:
  /// **'Once you login, your email will be stored in our server until you delete your account. This is neccessary for providing account login. We do not share your email with any third party. Do you allow us to store your email?'**
  String get userConsend;

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @disagree.
  ///
  /// In en, this message translates to:
  /// **'Disagree'**
  String get disagree;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @greatSetDescription1.
  ///
  /// In en, this message translates to:
  /// **'A large set is composed of small sets or other large sets. When telling whether a domain/IP is in the set, the exluded sets will be considered first, if the domain is in any of the excluded set, then the domain is not in the set. '**
  String get greatSetDescription1;

  /// No description provided for @greatSetDescription2.
  ///
  /// In en, this message translates to:
  /// **'A large set can have a mutually exclusive set. If a domain/IP is in set A, then the domain/IP is not in it\'s mutually exclusive set.'**
  String get greatSetDescription2;

  /// No description provided for @pleaseLoginFirst.
  ///
  /// In en, this message translates to:
  /// **'Please login first'**
  String get pleaseLoginFirst;

  /// No description provided for @telegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get telegram;

  /// No description provided for @failedToDownloadGeoData.
  ///
  /// In en, this message translates to:
  /// **'Failed to download GeoData: {value}'**
  String failedToDownloadGeoData(String value);

  /// No description provided for @doNotUse1080IOS.
  ///
  /// In en, this message translates to:
  /// **'Do not use 1080 on iOS'**
  String get doNotUse1080IOS;

  /// No description provided for @deletedNode.
  ///
  /// In en, this message translates to:
  /// **'Deleted Node'**
  String get deletedNode;

  /// No description provided for @selectorContainsDeletedLandHandler.
  ///
  /// In en, this message translates to:
  /// **'Selector {value} uses a deleted node as landing node, please remove it and retry'**
  String selectorContainsDeletedLandHandler(String value);

  /// No description provided for @tunIpv6Settings.
  ///
  /// In en, this message translates to:
  /// **'TUN Settings'**
  String get tunIpv6Settings;

  /// No description provided for @alwaysEnableIpv6.
  ///
  /// In en, this message translates to:
  /// **'Always Enable IPv6'**
  String get alwaysEnableIpv6;

  /// No description provided for @dependsOnDefaultNic.
  ///
  /// In en, this message translates to:
  /// **'Depends on Default Physical NIC'**
  String get dependsOnDefaultNic;

  /// No description provided for @dependsOnDefaultNicDesc.
  ///
  /// In en, this message translates to:
  /// **'If the default physical NIC supports IPv6, then the TUN NIC will also support IPv6, otherwise IPv6 is not supported'**
  String get dependsOnDefaultNicDesc;

  /// No description provided for @tunIpv4Desc.
  ///
  /// In en, this message translates to:
  /// **'On Windows/Linux, if your physical NIC supports IPv6, IPv6 traffic will not be handled by VX TUN, they will be handled by your physical NIC; on Android/iOS/macOS, IPv6 traffic will be blocked anyway.'**
  String get tunIpv4Desc;

  /// No description provided for @tunRejectIpv6.
  ///
  /// In en, this message translates to:
  /// **'Reject IPv6 if node does not support it'**
  String get tunRejectIpv6;

  /// No description provided for @tunRejectIpv6Desc.
  ///
  /// In en, this message translates to:
  /// **'Match a connection based on destination, source, application (if available), if the matched handler does not support IPv6, reject the connection'**
  String get tunRejectIpv6Desc;

  /// No description provided for @tunCidr4.
  ///
  /// In en, this message translates to:
  /// **'TUN IPv4 address (CIDR)'**
  String get tunCidr4;

  /// No description provided for @tunCidr6.
  ///
  /// In en, this message translates to:
  /// **'TUN IPv6 address (CIDR)'**
  String get tunCidr6;

  /// No description provided for @tunCidr4Hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 172.23.27.1/24'**
  String get tunCidr4Hint;

  /// No description provided for @tunCidr6Hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. fc20::1/120'**
  String get tunCidr6Hint;

  /// No description provided for @tunDns4.
  ///
  /// In en, this message translates to:
  /// **'TUN DNS IPv4'**
  String get tunDns4;

  /// No description provided for @tunDns6.
  ///
  /// In en, this message translates to:
  /// **'TUN DNS IPv6'**
  String get tunDns6;

  /// No description provided for @tunDns4Hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 172.23.27.2'**
  String get tunDns4Hint;

  /// No description provided for @tunDns6Hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. fc20::2'**
  String get tunDns6Hint;

  /// No description provided for @tunRoutes4.
  ///
  /// In en, this message translates to:
  /// **'TUN IPv4 routes'**
  String get tunRoutes4;

  /// No description provided for @tunRoutes6.
  ///
  /// In en, this message translates to:
  /// **'TUN IPv6 routes'**
  String get tunRoutes6;

  /// No description provided for @tunRoutes4Hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 0.0.0.0/0 (comma-separated)'**
  String get tunRoutes4Hint;

  /// No description provided for @tunRoutes6Hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ::/0 (comma-separated)'**
  String get tunRoutes6Hint;

  /// No description provided for @tunMtu.
  ///
  /// In en, this message translates to:
  /// **'TUN MTU'**
  String get tunMtu;

  /// No description provided for @tunMtuHint.
  ///
  /// In en, this message translates to:
  /// **'Empty = platform default'**
  String get tunMtuHint;

  /// No description provided for @failedToCreateAllFirstLaunch.
  ///
  /// In en, this message translates to:
  /// **'Failed to create database tables: {value}'**
  String failedToCreateAllFirstLaunch(String value);

  /// No description provided for @failedToInsertDefaultData.
  ///
  /// In en, this message translates to:
  /// **'Failed to insert default data into database: {value}'**
  String failedToInsertDefaultData(String value);

  /// No description provided for @newVersionDownloadedDialog.
  ///
  /// In en, this message translates to:
  /// **'New version {version} downloaded, install it?'**
  String newVersionDownloadedDialog(String version);

  /// No description provided for @skipThisVersion.
  ///
  /// In en, this message translates to:
  /// **'Skip this version'**
  String get skipThisVersion;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Remind Me Later'**
  String get later;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @autoCheck.
  ///
  /// In en, this message translates to:
  /// **'Automatically Check New Version'**
  String get autoCheck;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {value}...'**
  String downloading(String value);

  /// No description provided for @installFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to install update, reason: {reason}'**
  String installFailed(String reason);

  /// No description provided for @tun46SettingIpv4Only.
  ///
  /// In en, this message translates to:
  /// **'IPv4 Only'**
  String get tun46SettingIpv4Only;

  /// No description provided for @tun46SettingIpv4AndIpv6.
  ///
  /// In en, this message translates to:
  /// **'IPv4 and IPv6'**
  String get tun46SettingIpv4AndIpv6;

  /// No description provided for @ad.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get ad;

  /// No description provided for @advancedSettingDesc.
  ///
  /// In en, this message translates to:
  /// **'VPN related settings'**
  String get advancedSettingDesc;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @customizeHomeWidgets.
  ///
  /// In en, this message translates to:
  /// **'Customize home'**
  String get customizeHomeWidgets;

  /// No description provided for @customizeHomeWidgetsDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose which sections to show on the home screen.'**
  String get customizeHomeWidgetsDesc;

  /// No description provided for @homeWidgetStats.
  ///
  /// In en, this message translates to:
  /// **'Speed & stats'**
  String get homeWidgetStats;

  /// No description provided for @homeWidgetNodesHelper.
  ///
  /// In en, this message translates to:
  /// **'Nodes helper'**
  String get homeWidgetNodesHelper;

  /// No description provided for @homeWidgetNodes.
  ///
  /// In en, this message translates to:
  /// **'Current nodes'**
  String get homeWidgetNodes;

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

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server Error'**
  String get serverError;

  /// No description provided for @gfwDesc.
  ///
  /// In en, this message translates to:
  /// **'All domains/IPs that are blocked by GFW go proxy, others go direct'**
  String get gfwDesc;

  /// No description provided for @cnDesc.
  ///
  /// In en, this message translates to:
  /// **'All domains/IPs of China mainland go direct, others go proxy'**
  String get cnDesc;

  /// No description provided for @proxyAllDesc.
  ///
  /// In en, this message translates to:
  /// **'All non-private domains/IPs go proxy'**
  String get proxyAllDesc;

  /// No description provided for @dnsRule.
  ///
  /// In en, this message translates to:
  /// **'DNS Rules'**
  String get dnsRule;

  /// No description provided for @dnsRuleNameGfwProxyFake.
  ///
  /// In en, this message translates to:
  /// **'GFW Mode Proxy Domains & Non CN Domains(A/AAAA)'**
  String get dnsRuleNameGfwProxyFake;

  /// No description provided for @dnsRuleNameGfwProxy.
  ///
  /// In en, this message translates to:
  /// **'GFW Mode Proxy Domains'**
  String get dnsRuleNameGfwProxy;

  /// No description provided for @dnsRuleNameRuBlockProxyFake.
  ///
  /// In en, this message translates to:
  /// **'RU-Block Mode Proxy Domains(A/AAAA)'**
  String get dnsRuleNameRuBlockProxyFake;

  /// No description provided for @dnsRuleNameRuBlockProxy.
  ///
  /// In en, this message translates to:
  /// **'RU-Block Mode Proxy Domains'**
  String get dnsRuleNameRuBlockProxy;

  /// No description provided for @dnsRuleNameRuBlockAllProxyFake.
  ///
  /// In en, this message translates to:
  /// **'RU-Block(All) Mode Proxy Domains(A/AAAA)'**
  String get dnsRuleNameRuBlockAllProxyFake;

  /// No description provided for @dnsRuleNameRuBlockAllProxy.
  ///
  /// In en, this message translates to:
  /// **'RU-Block(All) Mode Proxy Domains'**
  String get dnsRuleNameRuBlockAllProxy;

  /// No description provided for @dnsRuleNameCnProxyFake.
  ///
  /// In en, this message translates to:
  /// **'CN Mode Proxy Domains(A/AAAA)'**
  String get dnsRuleNameCnProxyFake;

  /// No description provided for @dnsRuleNameCnProxy.
  ///
  /// In en, this message translates to:
  /// **'CN Mode Proxy Domains'**
  String get dnsRuleNameCnProxy;

  /// No description provided for @dnsRuleNameProxyAllProxyFake.
  ///
  /// In en, this message translates to:
  /// **'Proxy-All Mode Proxy Domains(A/AAAA)'**
  String get dnsRuleNameProxyAllProxyFake;

  /// No description provided for @dnsRuleNameProxyAllProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy-All Mode Proxy Domains'**
  String get dnsRuleNameProxyAllProxy;

  /// No description provided for @dnsRuleNameDefaultDirect.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get dnsRuleNameDefaultDirect;

  /// No description provided for @routerRules.
  ///
  /// In en, this message translates to:
  /// **'Router Rules'**
  String get routerRules;

  /// No description provided for @dnsRuleDesc.
  ///
  /// In en, this message translates to:
  /// **'For each DNS request, rules are matched one by one starting from the top. If a rule matches, the following rule will not be considered. The dns server specified by the rule will be used to handle the dns query. If no rule matches, return empty DNS result.'**
  String get dnsRuleDesc;

  /// No description provided for @dnsServer.
  ///
  /// In en, this message translates to:
  /// **'DNS Server'**
  String get dnsServer;

  /// No description provided for @howDnsRuleMatch.
  ///
  /// In en, this message translates to:
  /// **'When all conditions match or there is no condition enabled, a dns rule matches.'**
  String get howDnsRuleMatch;

  /// No description provided for @selectAtleastOneDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Select at least one dns server'**
  String get selectAtleastOneDnsServer;

  /// No description provided for @dnsType.
  ///
  /// In en, this message translates to:
  /// **'DNS Type'**
  String get dnsType;

  /// No description provided for @directDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Direct DNS Server'**
  String get directDnsServer;

  /// No description provided for @proxyDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Proxy DNS Server'**
  String get proxyDnsServer;

  /// No description provided for @addDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Add DNS Server'**
  String get addDnsServer;

  /// No description provided for @useDefaultDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Use DNS servers of default NIC. If unable to get the servers, fallback to use the above servers.'**
  String get useDefaultDnsServer;

  /// No description provided for @useDefaultNicDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Use DNS servers of default NIC. If unable to get the servers, use the following:'**
  String get useDefaultNicDnsServer;

  /// No description provided for @addDnsAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Multiple addresses supported. Use comma to seperate. Each dns query will be sent to all addresses simultaneouly, the first reply will be used.'**
  String get addDnsAddressHint;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get invalidUrl;

  /// No description provided for @duplicateDnsServerName.
  ///
  /// In en, this message translates to:
  /// **'Duplicate DNS server name'**
  String get duplicateDnsServerName;

  /// No description provided for @dnsTypeConditionDesc.
  ///
  /// In en, this message translates to:
  /// **'If checked, then this condition is enabled. The condition is true only when the type of a dns query is in the selected type.'**
  String get dnsTypeConditionDesc;

  /// No description provided for @enabledConditions.
  ///
  /// In en, this message translates to:
  /// **'Enabled conditions: {number}'**
  String enabledConditions(num number);

  /// No description provided for @enabledSubconditions.
  ///
  /// In en, this message translates to:
  /// **'Enabled subconditions: {number}'**
  String enabledSubconditions(num number);

  /// No description provided for @conditionsCount.
  ///
  /// In en, this message translates to:
  /// **'{number} conditions'**
  String conditionsCount(num number);

  /// No description provided for @showSelector.
  ///
  /// In en, this message translates to:
  /// **'Show Selector'**
  String get showSelector;

  /// No description provided for @hideSelector.
  ///
  /// In en, this message translates to:
  /// **'Hide Selector'**
  String get hideSelector;

  /// No description provided for @showHandler.
  ///
  /// In en, this message translates to:
  /// **'Show Handler'**
  String get showHandler;

  /// No description provided for @hideHandler.
  ///
  /// In en, this message translates to:
  /// **'Hide Selector'**
  String get hideHandler;

  /// No description provided for @restoreIAP.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get restoreIAP;

  /// No description provided for @debugLog.
  ///
  /// In en, this message translates to:
  /// **'Debug Log'**
  String get debugLog;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @saveToDownloadFolder.
  ///
  /// In en, this message translates to:
  /// **'Save to Download'**
  String get saveToDownloadFolder;

  /// No description provided for @saveToDownloadFolderDesc.
  ///
  /// In en, this message translates to:
  /// **'Move the logs to your Download folder'**
  String get saveToDownloadFolderDesc;

  /// No description provided for @debugLogDesc.
  ///
  /// In en, this message translates to:
  /// **'If you encountered any problem during using VX, you can enable the button, and wait until the problem occur again, then click upload to upload the logs to us, rememeber to close it and delete the logsafter uploading.  Developer logs are not uploaded automatically since they contain your network activities, including the websites and apps you use. We delete the logs immediately once we process them.'**
  String get debugLogDesc;

  /// No description provided for @clashFormatSupported.
  ///
  /// In en, this message translates to:
  /// **'Only Clash Rule files are supported'**
  String get clashFormatSupported;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @fallbackToProxy.
  ///
  /// In en, this message translates to:
  /// **'Fallback To Proxy'**
  String get fallbackToProxy;

  /// No description provided for @fallbackToProxySetting.
  ///
  /// In en, this message translates to:
  /// **'When a direct connection failed, fallback to use proxy. The node selected by the \"Proxy\" selector will be used, if the selector does not exist, a random nodes will be selected'**
  String get fallbackToProxySetting;

  /// No description provided for @changeIpv6ToDomain.
  ///
  /// In en, this message translates to:
  /// **'Change IPv6 to Domain'**
  String get changeIpv6ToDomain;

  /// No description provided for @changeIpv6ToDomainDesc.
  ///
  /// In en, this message translates to:
  /// **'If the matched node does not support IPv6, but the target address is IPv6, and the domain is sniffed, change target address to the domain.'**
  String get changeIpv6ToDomainDesc;

  /// No description provided for @installAsWinService.
  ///
  /// In en, this message translates to:
  /// **'Add VX to Windows Service'**
  String get installAsWinService;

  /// No description provided for @installAsWinServiceDesc.
  ///
  /// In en, this message translates to:
  /// **'Before use TUN, VX needs to be added into Windows Service. Click Yes to install VX as a service, which would require you to give permission in the following UAC prompt window.'**
  String get installAsWinServiceDesc;

  /// No description provided for @placeOnTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get placeOnTop;

  /// No description provided for @stopPlaceOnTop.
  ///
  /// In en, this message translates to:
  /// **'Untop'**
  String get stopPlaceOnTop;

  /// No description provided for @fallbackTo.
  ///
  /// In en, this message translates to:
  /// **'Fallback to {node}'**
  String fallbackTo(String node);

  /// No description provided for @pingTestMethod.
  ///
  /// In en, this message translates to:
  /// **'Latency Test Method'**
  String get pingTestMethod;

  /// No description provided for @pingReal.
  ///
  /// In en, this message translates to:
  /// **'Real Latency'**
  String get pingReal;

  /// No description provided for @pingRealDesc.
  ///
  /// In en, this message translates to:
  /// **'Time used to retrieve a result'**
  String get pingRealDesc;

  /// No description provided for @startOnBoot.
  ///
  /// In en, this message translates to:
  /// **'Start on Boot'**
  String get startOnBoot;

  /// No description provided for @startOnBootDesc.
  ///
  /// In en, this message translates to:
  /// **'Start VX automatically at startup'**
  String get startOnBootDesc;

  /// No description provided for @alwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Always ON'**
  String get alwaysOn;

  /// No description provided for @alwaysOnDesc.
  ///
  /// In en, this message translates to:
  /// **'As long as you did not click disconnect, always try to be connected when the app is running'**
  String get alwaysOnDesc;

  /// No description provided for @systemManagedVpnNotice.
  ///
  /// In en, this message translates to:
  /// **'This VPN connection is managed by Android. To connect or disconnect, go to Settings > Network & Internet > VPN.'**
  String get systemManagedVpnNotice;

  /// No description provided for @openVpnSettings.
  ///
  /// In en, this message translates to:
  /// **'Open VPN Settings'**
  String get openVpnSettings;

  /// No description provided for @checkAndUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check and Update'**
  String get checkAndUpdate;

  /// No description provided for @noNewVersion.
  ///
  /// In en, this message translates to:
  /// **'No new versions'**
  String get noNewVersion;

  /// No description provided for @enableSystemExtension.
  ///
  /// In en, this message translates to:
  /// **'Please enable VX SystemExtension by going to System Settings -> General -> Login Items & Extensions -> Network Extensions'**
  String get enableSystemExtension;

  /// No description provided for @systemProxyPortSetting.
  ///
  /// In en, this message translates to:
  /// **'System Proxy Port Setting'**
  String get systemProxyPortSetting;

  /// No description provided for @randomPorts.
  ///
  /// In en, this message translates to:
  /// **'Random Ports'**
  String get randomPorts;

  /// No description provided for @outboundPortStrategyRandomAllPortsSameTime.
  ///
  /// In en, this message translates to:
  /// **'Random (all ports at same time)'**
  String get outboundPortStrategyRandomAllPortsSameTime;

  /// No description provided for @outboundNameCannotBeDirectOrDns.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be \"direct\" or \"dns\"'**
  String get outboundNameCannotBeDirectOrDns;

  /// No description provided for @outboundServerAddressCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Server address cannot be empty'**
  String get outboundServerAddressCannotBeEmpty;

  /// No description provided for @outboundPortCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Port cannot be empty'**
  String get outboundPortCannotBeEmpty;

  /// No description provided for @outboundPortHintExample.
  ///
  /// In en, this message translates to:
  /// **'443,444,1080-1090'**
  String get outboundPortHintExample;

  /// No description provided for @outboundPortSelectStrategy.
  ///
  /// In en, this message translates to:
  /// **'Port Select Strategy'**
  String get outboundPortSelectStrategy;

  /// No description provided for @outboundPortStrategyOneSwitchByInterval.
  ///
  /// In en, this message translates to:
  /// **'One (switch port by interval)'**
  String get outboundPortStrategyOneSwitchByInterval;

  /// No description provided for @outboundSetIntervalOrMinMax.
  ///
  /// In en, this message translates to:
  /// **'Set interval, or min/max interval'**
  String get outboundSetIntervalOrMinMax;

  /// No description provided for @outboundPortSwitchIntervalSeconds.
  ///
  /// In en, this message translates to:
  /// **'Interval (seconds)'**
  String get outboundPortSwitchIntervalSeconds;

  /// No description provided for @outboundPortSwitchIntervalHelper.
  ///
  /// In en, this message translates to:
  /// **'Use this for fixed switch interval'**
  String get outboundPortSwitchIntervalHelper;

  /// No description provided for @outboundRequiredWhenIntervalEmpty.
  ///
  /// In en, this message translates to:
  /// **'Required when interval is empty'**
  String get outboundRequiredWhenIntervalEmpty;

  /// No description provided for @outboundMinIntervalMustBeLeqMax.
  ///
  /// In en, this message translates to:
  /// **'Must be <= max interval'**
  String get outboundMinIntervalMustBeLeqMax;

  /// No description provided for @outboundMinIntervalSeconds.
  ///
  /// In en, this message translates to:
  /// **'Min Interval (seconds)'**
  String get outboundMinIntervalSeconds;

  /// No description provided for @outboundMaxIntervalMustBeGeqMin.
  ///
  /// In en, this message translates to:
  /// **'Must be >= min interval'**
  String get outboundMaxIntervalMustBeGeqMin;

  /// No description provided for @outboundMaxIntervalSeconds.
  ///
  /// In en, this message translates to:
  /// **'Max Interval (seconds)'**
  String get outboundMaxIntervalSeconds;

  /// No description provided for @outboundMux.
  ///
  /// In en, this message translates to:
  /// **'Mux'**
  String get outboundMux;

  /// No description provided for @outboundUdpOverTcp.
  ///
  /// In en, this message translates to:
  /// **'UDP over TCP'**
  String get outboundUdpOverTcp;

  /// No description provided for @outboundStream.
  ///
  /// In en, this message translates to:
  /// **'Stream'**
  String get outboundStream;

  /// No description provided for @staticPorts.
  ///
  /// In en, this message translates to:
  /// **'Static Ports'**
  String get staticPorts;

  /// No description provided for @whenNoDomain.
  ///
  /// In en, this message translates to:
  /// **'Sniff When No Domain Info'**
  String get whenNoDomain;

  /// No description provided for @hasNoDomain.
  ///
  /// In en, this message translates to:
  /// **'No domain info'**
  String get hasNoDomain;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @checkUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check Update'**
  String get checkUpdate;

  /// No description provided for @handlerCopiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Copy succeeded. The node has been added to the Default group'**
  String get handlerCopiedSuccess;

  /// No description provided for @hysteriaRejectQuic.
  ///
  /// In en, this message translates to:
  /// **'Hysteria Reject QUIC'**
  String get hysteriaRejectQuic;

  /// No description provided for @syncBackup.
  ///
  /// In en, this message translates to:
  /// **'Sync & Backup'**
  String get syncBackup;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloudSync;

  /// No description provided for @cloudSyncDesc1.
  ///
  /// In en, this message translates to:
  /// **'Sync your database between multiple devices. '**
  String get cloudSyncDesc1;

  /// No description provided for @cloudSyncDesc2.
  ///
  /// In en, this message translates to:
  /// **'For Android devices with Google Services installed and notification on and Apple devices that can communicate with Google FCM servers, sync are real-time. Otherwise, sync will happen every 5 minutes, you can click the top left V logo icon to trigger a sync manually.'**
  String get cloudSyncDesc2;

  /// No description provided for @cloudSyncDesc3.
  ///
  /// In en, this message translates to:
  /// **'The sync data will be automatically cleared from the cloud after your device have fetched them. If your device has not fetched them for 7 days, the data will deleted from the cloud.'**
  String get cloudSyncDesc3;

  /// No description provided for @nodeSub.
  ///
  /// In en, this message translates to:
  /// **'Node/Subscription'**
  String get nodeSub;

  /// No description provided for @routeSetDNSSelector.
  ///
  /// In en, this message translates to:
  /// **'Rule/Set/Selector/DNS'**
  String get routeSetDNSSelector;

  /// No description provided for @selectorSetting.
  ///
  /// In en, this message translates to:
  /// **'Selector Settings'**
  String get selectorSetting;

  /// No description provided for @selectorTestFieldsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {tag}'**
  String selectorTestFieldsTitle(String tag);

  /// No description provided for @selectorTestSpeedTestSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed test size'**
  String get selectorTestSpeedTestSizeLabel;

  /// No description provided for @selectorTestByteSuffix.
  ///
  /// In en, this message translates to:
  /// **'Byte'**
  String get selectorTestByteSuffix;

  /// No description provided for @selectorTestSpeedTestSizeHelper.
  ///
  /// In en, this message translates to:
  /// **'1000000 Byte = 1 MB'**
  String get selectorTestSpeedTestSizeHelper;

  /// No description provided for @selectorTestSpeedTestIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed test interval'**
  String get selectorTestSpeedTestIntervalLabel;

  /// No description provided for @selectorTestMinutesSuffix.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get selectorTestMinutesSuffix;

  /// No description provided for @selectorTestSpeedTestIntervalHelper.
  ///
  /// In en, this message translates to:
  /// **'Periodically test speed of all filtered handlers'**
  String get selectorTestSpeedTestIntervalHelper;

  /// No description provided for @selectorTestPingTestIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Ping test interval'**
  String get selectorTestPingTestIntervalLabel;

  /// No description provided for @selectorTestPingTestIntervalHelper.
  ///
  /// In en, this message translates to:
  /// **'Periodically test ping of all filtered handlers'**
  String get selectorTestPingTestIntervalHelper;

  /// No description provided for @selectorTestUnusableTestIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Unusable test interval'**
  String get selectorTestUnusableTestIntervalLabel;

  /// No description provided for @selectorTestUnusableTestIntervalHelper.
  ///
  /// In en, this message translates to:
  /// **'Periodically test filtered but unusable handlers whether they are usable or not'**
  String get selectorTestUnusableTestIntervalHelper;

  /// No description provided for @selectorTestMustBeNonNegativeInteger.
  ///
  /// In en, this message translates to:
  /// **'Must be a non-negative integer'**
  String get selectorTestMustBeNonNegativeInteger;

  /// No description provided for @selectorTestMustBeAtMostUint32Max.
  ///
  /// In en, this message translates to:
  /// **'Must be at most 4294967295'**
  String get selectorTestMustBeAtMostUint32Max;

  /// No description provided for @serverKey.
  ///
  /// In en, this message translates to:
  /// **'Server/Key'**
  String get serverKey;

  /// No description provided for @lanSync.
  ///
  /// In en, this message translates to:
  /// **'LAN Sync'**
  String get lanSync;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @conditaionWarn1.
  ///
  /// In en, this message translates to:
  /// **'In most cases, domain conditions and IP conditions should not exist at the same time. When they both exist, the rule will only match when the request has both domain and IP information, which is not always the case.'**
  String get conditaionWarn1;

  /// No description provided for @setName.
  ///
  /// In en, this message translates to:
  /// **'Set Name'**
  String get setName;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'Add Set'**
  String get addSet;

  /// No description provided for @domainIpAppConditionDesc.
  ///
  /// In en, this message translates to:
  /// **'When a request\'s domain/IP/App is in any of the sets, the rule matches.'**
  String get domainIpAppConditionDesc;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Database Backup'**
  String get backup;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get autoBackup;

  /// No description provided for @autoBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically backup database to cloud once a day.'**
  String get autoBackupDesc;

  /// No description provided for @currentBackup.
  ///
  /// In en, this message translates to:
  /// **'Current Backup'**
  String get currentBackup;

  /// No description provided for @exportToFile.
  ///
  /// In en, this message translates to:
  /// **'Export to file'**
  String get exportToFile;

  /// No description provided for @uploadDb.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadDb;

  /// No description provided for @restoreDb.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreDb;

  /// No description provided for @deleteCloudDb.
  ///
  /// In en, this message translates to:
  /// **'Delete database in cloud'**
  String get deleteCloudDb;

  /// No description provided for @uploadDbSuccess.
  ///
  /// In en, this message translates to:
  /// **'Upload database successfully'**
  String get uploadDbSuccess;

  /// No description provided for @restoreDbSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restore database successfully'**
  String get restoreDbSuccess;

  /// No description provided for @deleteDbSuccess.
  ///
  /// In en, this message translates to:
  /// **'Delete successfully'**
  String get deleteDbSuccess;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid View'**
  String get gridView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listView;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @fallbackRetryDomain.
  ///
  /// In en, this message translates to:
  /// **'Retry Domain'**
  String get fallbackRetryDomain;

  /// No description provided for @fallbackRetryDomainDesc.
  ///
  /// In en, this message translates to:
  /// **'If a proxy connection uses ip targets and failed due to i/o timeout(this might due to DNS pollution), use domain as target and retry. The sniffed domain of the connection will be used first, if it is unavailable, the ip-to-domain domain will be used.'**
  String get fallbackRetryDomainDesc;

  /// No description provided for @backupPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Used to encrypt database. Only devices with this password can restore backups. The password is encrypted and stored locally.'**
  String get backupPasswordDesc;

  /// No description provided for @syncPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Used to encrypt sync data. Only devices with this password can sync data successfully. The password is encrypted and stored locally.'**
  String get syncPasswordDesc;

  /// No description provided for @addDomainIpAppSet.
  ///
  /// In en, this message translates to:
  /// **'Add Domain/App/IP Set'**
  String get addDomainIpAppSet;

  /// No description provided for @unsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get unsaved;

  /// No description provided for @unapplied.
  ///
  /// In en, this message translates to:
  /// **'Unapplied'**
  String get unapplied;

  /// No description provided for @unappliedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unapplied changes'**
  String get unappliedChanges;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @applySuccess.
  ///
  /// In en, this message translates to:
  /// **'Applied successfully'**
  String get applySuccess;

  /// No description provided for @applyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply'**
  String get applyFailed;

  /// No description provided for @rememberPasswordInMemory.
  ///
  /// In en, this message translates to:
  /// **'Remember sudo password in memory for later use'**
  String get rememberPasswordInMemory;

  /// No description provided for @doNotShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Do not show again'**
  String get doNotShowAgain;

  /// No description provided for @rpmTunNotice.
  ///
  /// In en, this message translates to:
  /// **'When TUN is on, Reverse Path Forwarding mode will be set to Loose(2) and reset to what it was when disconnect. You can go to the following website to learn about Reverse Path Forwarding'**
  String get rpmTunNotice;

  /// No description provided for @internalDnsDesc.
  ///
  /// In en, this message translates to:
  /// **'Internal DNS servers are mainly used to resolve domains when outbounds are dialing. They will be used from left to right until one of them succeeds.'**
  String get internalDnsDesc;

  /// No description provided for @nodeSetDesc.
  ///
  /// In en, this message translates to:
  /// **'There is a small domain set named \"__node__\" which contains domains and SNIs of all nodes. There is also a small IP set named \"__node__\" which contains IPs of all nodes.'**
  String get nodeSetDesc;

  /// No description provided for @dnsNameDesc.
  ///
  /// In en, this message translates to:
  /// **'A DNS server\'s name can be referenced in the inbound condition to specify which node it uses.'**
  String get dnsNameDesc;

  /// No description provided for @directAppSetDesc.
  ///
  /// In en, this message translates to:
  /// **'On Android, applications in the direct app set will not go through VX (Split Tunnel)'**
  String get directAppSetDesc;

  /// No description provided for @deleteDebugLogs.
  ///
  /// In en, this message translates to:
  /// **'Delete Debug Logs'**
  String get deleteDebugLogs;

  /// No description provided for @conditionDesc.
  ///
  /// In en, this message translates to:
  /// **'When a connection does not have IP info, IP condition will be false and the rule will not match. Similarly, when a connection does not have domain info, domain condition will be false and the rule will not match.'**
  String get conditionDesc;

  /// No description provided for @lookupEch.
  ///
  /// In en, this message translates to:
  /// **'Lookup ECH'**
  String get lookupEch;

  /// No description provided for @lookupEchDesc.
  ///
  /// In en, this message translates to:
  /// **'If enabled and above ECH Config is empty, ECH config will be looked up from DNS server. If lookup success, use ECH, otherwise do not use ECH.'**
  String get lookupEchDesc;

  /// No description provided for @adWanted.
  ///
  /// In en, this message translates to:
  /// **'Publish Ads'**
  String get adWanted;

  /// No description provided for @basicQuickDeployTitle.
  ///
  /// In en, this message translates to:
  /// **'Two cores, four protocols'**
  String get basicQuickDeployTitle;

  /// No description provided for @basicQuickDeploySummary.
  ///
  /// In en, this message translates to:
  /// **'Deploy Xray, Hysteria cores and set nodes with four common protocols'**
  String get basicQuickDeploySummary;

  /// No description provided for @basicQuickDeployDetails.
  ///
  /// In en, this message translates to:
  /// **'Install Xray-core and Hysteria, and deploy the following four inbound. If the server has already installed Xray or Hysteria, the original configuration will be replaced. If the server has not enabled BBR, BBR will be enabled.'**
  String get basicQuickDeployDetails;

  /// No description provided for @basicQuickDeployContent1.
  ///
  /// In en, this message translates to:
  /// **'Vmess five random ports'**
  String get basicQuickDeployContent1;

  /// No description provided for @basicQuickDeployContent2.
  ///
  /// In en, this message translates to:
  /// **'Shadowsocks five random ports'**
  String get basicQuickDeployContent2;

  /// No description provided for @basicQuickDeployContent3.
  ///
  /// In en, this message translates to:
  /// **'Hysteria 443 port'**
  String get basicQuickDeployContent3;

  /// No description provided for @basicQuickDeployContent4.
  ///
  /// In en, this message translates to:
  /// **'Vless-XTLS-Vision 443 port'**
  String get basicQuickDeployContent4;

  /// No description provided for @masqueradeQuickDeployTitle.
  ///
  /// In en, this message translates to:
  /// **'Reality/XHTTP'**
  String get masqueradeQuickDeployTitle;

  /// No description provided for @masqueradeQuickDeploySummary.
  ///
  /// In en, this message translates to:
  /// **'Install Xray-core and deploy Reality/XHTTP inbound. If the server has already installed Xray, the original configuration will be replaced. If the server has not enabled BBR, BBR will be enabled.'**
  String get masqueradeQuickDeploySummary;

  /// No description provided for @masqueradeQuickDeployDetails.
  ///
  /// In en, this message translates to:
  /// **'Install Xray-core, and deploy Reality/XHTTP inbound. If the server has already installed Xray, the original configuration will be replaced. If the server has not enabled BBR, BBR will be enabled.'**
  String get masqueradeQuickDeployDetails;

  /// No description provided for @fatalError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please restart VX. Error: {error}'**
  String fatalError(String error);

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @selectAtleastOneSelector.
  ///
  /// In en, this message translates to:
  /// **'Select at least one selector'**
  String get selectAtleastOneSelector;

  /// No description provided for @addRouteMode.
  ///
  /// In en, this message translates to:
  /// **'Add Route Mode'**
  String get addRouteMode;

  /// No description provided for @setNameProxyApp.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get setNameProxyApp;

  /// No description provided for @setNameDirectApp.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get setNameDirectApp;

  /// No description provided for @defaultSelectorTag.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get defaultSelectorTag;

  /// No description provided for @selectAtleastOneNode.
  ///
  /// In en, this message translates to:
  /// **'Select at least one node'**
  String get selectAtleastOneNode;

  /// No description provided for @insertDefaultError.
  ///
  /// In en, this message translates to:
  /// **'Failed to insert default data, please restart VX and add them in the routing page. Reason: {error}'**
  String insertDefaultError(String error);

  /// No description provided for @pleaseSelectARoutingMode.
  ///
  /// In en, this message translates to:
  /// **'Please select a routing mode'**
  String get pleaseSelectARoutingMode;

  /// No description provided for @addRouteModeNotice.
  ///
  /// In en, this message translates to:
  /// **'Clicking the + button to add a routing mode.'**
  String get addRouteModeNotice;

  /// No description provided for @freeUserCannotUseCustomRoutingMode.
  ///
  /// In en, this message translates to:
  /// **'Free users cannot use custom routing modes. Please select a default routing mode. You can add default routing modes in the routing page.'**
  String get freeUserCannotUseCustomRoutingMode;

  /// No description provided for @defaultRouteModes.
  ///
  /// In en, this message translates to:
  /// **'Default modes'**
  String get defaultRouteModes;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @geositeUrlDesc.
  ///
  /// In en, this message translates to:
  /// **'If empty, the geosite.dat provided by LoyalSoldier will be used'**
  String get geositeUrlDesc;

  /// No description provided for @geoUrlDesc.
  ///
  /// In en, this message translates to:
  /// **'If empty, the geoip.dat provided by LoyalSoldier will be used'**
  String get geoUrlDesc;

  /// No description provided for @ruBlocked.
  ///
  /// In en, this message translates to:
  /// **'Russia Blocked'**
  String get ruBlocked;

  /// No description provided for @ruBlockedDesc.
  ///
  /// In en, this message translates to:
  /// **'Domains/IPs blocked in Russia go proxy, others go direct'**
  String get ruBlockedDesc;

  /// No description provided for @ruBlockedAll.
  ///
  /// In en, this message translates to:
  /// **'Russia Blocked(All)'**
  String get ruBlockedAll;

  /// No description provided for @ruBlockedAllDesc.
  ///
  /// In en, this message translates to:
  /// **'All domains/IPs known to be blocked in Russia go proxy, others go direct'**
  String get ruBlockedAllDesc;

  /// No description provided for @dnsServerProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy DNS Server'**
  String get dnsServerProxy;

  /// No description provided for @dnsServerDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct DNS Server'**
  String get dnsServerDirect;

  /// No description provided for @sniffDomainForIpConnection.
  ///
  /// In en, this message translates to:
  /// **'If a connection use IP target, sniff domain'**
  String get sniffDomainForIpConnection;

  /// No description provided for @resolveDomain.
  ///
  /// In en, this message translates to:
  /// **'For connections using domain targets, use DNS to resolve IPs. When each resolved IP make the IP condition true, the condition is true'**
  String get resolveDomain;

  /// No description provided for @skipSniff.
  ///
  /// In en, this message translates to:
  /// **'No Sniff'**
  String get skipSniff;

  /// No description provided for @resolve.
  ///
  /// In en, this message translates to:
  /// **'Resovle'**
  String get resolve;

  /// No description provided for @skipResolve.
  ///
  /// In en, this message translates to:
  /// **'No Resolve'**
  String get skipResolve;

  /// No description provided for @describeTheProblem.
  ///
  /// In en, this message translates to:
  /// **'Please describe the problem you encountered, if you have already contacted customer service, you can leave it blank'**
  String get describeTheProblem;

  /// No description provided for @debugLogNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Developer log function is not available in non-store version'**
  String get debugLogNotAvailable;

  /// No description provided for @useBloomFilter.
  ///
  /// In en, this message translates to:
  /// **'Use Bloom Filter in iOS'**
  String get useBloomFilter;

  /// No description provided for @useBloomFilterDesc.
  ///
  /// In en, this message translates to:
  /// **'Bloom Filter can reduce memory usage, however, there is a small chance (1%) of false positives: domains not in the set might be misclassified as in the set.'**
  String get useBloomFilterDesc;

  /// No description provided for @addFromClashRuleFiles.
  ///
  /// In en, this message translates to:
  /// **'Add from Files'**
  String get addFromClashRuleFiles;

  /// No description provided for @selectFromInstalledApps.
  ///
  /// In en, this message translates to:
  /// **'Select from Installed Apps'**
  String get selectFromInstalledApps;

  /// No description provided for @ipToDomainDesc.
  ///
  /// In en, this message translates to:
  /// **'IP -> Domain is got from the recent DNS history. Because many domains can have same IP, it can only be said that the connection is likely to have the domain, but not guaranteed.'**
  String get ipToDomainDesc;

  /// No description provided for @followingAiTranslated.
  ///
  /// In en, this message translates to:
  /// **'The following languages are translated by AI, which may not be accurate.'**
  String get followingAiTranslated;

  /// No description provided for @addToDefault.
  ///
  /// In en, this message translates to:
  /// **'Add to Default'**
  String get addToDefault;

  /// No description provided for @vxCore.
  ///
  /// In en, this message translates to:
  /// **'VX Core'**
  String get vxCore;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @uptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get uptime;

  /// No description provided for @outbound.
  ///
  /// In en, this message translates to:
  /// **'Outbound'**
  String get outbound;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @vxCoreConfig.
  ///
  /// In en, this message translates to:
  /// **'VX Core Config'**
  String get vxCoreConfig;

  /// No description provided for @selectorDesc1.
  ///
  /// In en, this message translates to:
  /// **'Selector is used to select nodes. The \"Proxy\" selector is a special selector because it supports manual selection, other selectors do not support this option.'**
  String get selectorDesc1;

  /// No description provided for @selectorDesc2.
  ///
  /// In en, this message translates to:
  /// **'Nodes selected by a selector will form a node chain with the nodes in Node Chain list of the selector. The last node in the Node Chain list is the landing node. [Your Traffic] -> [Node(s) selected by the selector] -> [First node in the Node Chain list] -> ... -> [Last node in the Node Chain list] -> [Final destination]'**
  String get selectorDesc2;

  /// No description provided for @balanceStrategyDesc.
  ///
  /// In en, this message translates to:
  /// **'When the select strategy is \"All\" or \"Usable\", multiple nodes will be selected, and all of them will be used at the same time. For a connection, which node to use will be determined by the balancing strategy: if the balancing strategy is \"Random\", a random node will be selected; if the balancing strategy is \"Memory\", the same node will be used for connections with the same root domain or from the same app.'**
  String get balanceStrategyDesc;

  /// No description provided for @inboundDesc1.
  ///
  /// In en, this message translates to:
  /// **'TUN mode will make all your network traffic handled by VX. This mode prevents DNS leaking'**
  String get inboundDesc1;

  /// No description provided for @inboundDesc2.
  ///
  /// In en, this message translates to:
  /// **'System Proxy mode will set proxy setting of your host. Some apps, such as browsers, respect that and their traffic will be handled by VX, however, some apps does not respect that and their traffic will not go thruogh VX'**
  String get inboundDesc2;

  /// No description provided for @fakeDnsDesc.
  ///
  /// In en, this message translates to:
  /// **'FakeDNS can reduce latency'**
  String get fakeDnsDesc;

  /// No description provided for @routeDesc.
  ///
  /// In en, this message translates to:
  /// **'VX will add one or more routing modes based on your device language. Routing modes can be added/deleted in the routing page'**
  String get routeDesc;

  /// No description provided for @transportConditionMatchAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Force the inbound connections to use this protocol. When enabled, inbound connections must use this protocol, otherwise the connection will fail, and there should only be one transport protocol. When disabled, this transport protocol will only be considered when the condition matches, if condition does not match, the next transport protocol will be considered, if no transport protocol matches, then the inbound conn will be handed to the upper layer'**
  String get transportConditionMatchAllDesc;

  /// No description provided for @transportConditionH2Desc.
  ///
  /// In en, this message translates to:
  /// **'Data starting with http2 preface. This should be checked for h2 protocols such as grpc or http'**
  String get transportConditionH2Desc;

  /// No description provided for @securityConditionMatchAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Force the inbound connections to use this security protocol. When enabled, inbound connections must use this security protocol, otherwise the connection will fail, and there should only be one security protocol. When disabled, this security protocol will only be considered when the condition matches, if condition does not match, the next security protocol will be considered, if no security protocol matches, then the inbound conn will be handed to the upper layer: Transport Protocol layer.'**
  String get securityConditionMatchAllDesc;

  /// No description provided for @allInOneQuickDeployTitle.
  ///
  /// In en, this message translates to:
  /// **'All in One'**
  String get allInOneQuickDeployTitle;

  /// No description provided for @allInOneQuickDeploySummary.
  ///
  /// In en, this message translates to:
  /// **'Install VX core (Open Source), deploy many protocols'**
  String get allInOneQuickDeploySummary;

  /// No description provided for @allInOneQuickDeployDetails.
  ///
  /// In en, this message translates to:
  /// **'Install VX core (Open Source), deploy a combination of: (Vmess, Trojan, Anytls)x(Websocket, gRPC)x(TLS, Reality) + Hysteria. If the server has not enabled BBR, BBR will be enabled'**
  String get allInOneQuickDeployDetails;

  /// No description provided for @addMulti.
  ///
  /// In en, this message translates to:
  /// **'Add Multi Inbound'**
  String get addMulti;

  /// No description provided for @addSingle.
  ///
  /// In en, this message translates to:
  /// **'Add Normal Inbound'**
  String get addSingle;

  /// No description provided for @multiDesc.
  ///
  /// In en, this message translates to:
  /// **'Multi inbound can use almost all protocols on a port. It is similar to Xray fallback. It supports fallback of all layers, which means you can set multiple proxy protocols, transport protocols and security protocols. Currently, UDP fallback is not supported, so the UDP port will only be used by one protocol, Hysteria will be preferred, if it is not available, the first protocol that supports UDP will use the UDP port.'**
  String get multiDesc;

  /// No description provided for @normalInboundDesc.
  ///
  /// In en, this message translates to:
  /// **'Normal inbound is similar to V2ray inbound, it supports fallback of proxy layer, you can set multiple proxy protocols, but it does not support fallback of transport layer and security layer (Multi inbound supports fallback of all layers).'**
  String get normalInboundDesc;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @allInOneRealityDesc.
  ///
  /// In en, this message translates to:
  /// **'Optional. If not filled, Reality inbound will not be added'**
  String get allInOneRealityDesc;

  /// No description provided for @allInOneCdnDesc.
  ///
  /// In en, this message translates to:
  /// **'Optional. The SSL/TLS encryption of CDN can be flexible/full. It is recommended to use full, because it will encrypt the traffic between CDN and your server'**
  String get allInOneCdnDesc;

  /// No description provided for @disableOSFirewall.
  ///
  /// In en, this message translates to:
  /// **'Disable OS Firewall'**
  String get disableOSFirewall;

  /// No description provided for @disableOSFirewallDesc.
  ///
  /// In en, this message translates to:
  /// **'Your VPS usually has two firewalls, one is OS firewall, the other is the firewall provided by the VPS provider. This option will ONLY disable the OS firewall. Many cloud providers such as GCP disable the OS firewall by default, but some do not. If your VPS has the OS firewall enabled, and the OS firewall does not allow inbound traffic on the above port, your nodes will be unusable until you manually configure the OS firewall to allow inbound traffic on the above port.'**
  String get disableOSFirewallDesc;

  /// No description provided for @vxNotRunning.
  ///
  /// In en, this message translates to:
  /// **'VX is not running'**
  String get vxNotRunning;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @installVXCoreFirst.
  ///
  /// In en, this message translates to:
  /// **'Install VX-Core (Open Source) first to configure it'**
  String get installVXCoreFirst;

  /// No description provided for @duplicateInboundTagName.
  ///
  /// In en, this message translates to:
  /// **'Duplicate inbound tag name'**
  String get duplicateInboundTagName;

  /// No description provided for @addToNodes.
  ///
  /// In en, this message translates to:
  /// **'Add to Nodes'**
  String get addToNodes;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @generateSelfSignedCert.
  ///
  /// In en, this message translates to:
  /// **'Generate Self-Signed Certificate'**
  String get generateSelfSignedCert;

  /// No description provided for @certToBeProvidedToPeer.
  ///
  /// In en, this message translates to:
  /// **'Certificate to be provided to peer'**
  String get certToBeProvidedToPeer;

  /// No description provided for @verifyPeerCertDesc.
  ///
  /// In en, this message translates to:
  /// **'Used to verify the certificate provided by the peer'**
  String get verifyPeerCertDesc;

  /// No description provided for @issueCADesc.
  ///
  /// In en, this message translates to:
  /// **'Used to issue certificates to peers in real time'**
  String get issueCADesc;

  /// No description provided for @generatePassword.
  ///
  /// In en, this message translates to:
  /// **'Generate Password'**
  String get generatePassword;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @clientOnly.
  ///
  /// In en, this message translates to:
  /// **'Client Only'**
  String get clientOnly;

  /// No description provided for @visionDesc.
  ///
  /// In en, this message translates to:
  /// **'Vision will reduce the characteristics of the connection and improve performance, expecially on Linux. If you enable this, the server must also have this enabled. (This feature originates from Vision-RPRX-XTLS of VLESS, and is roughly same as the basic mode of Vision-RPRX-XTLS)'**
  String get visionDesc;

  /// No description provided for @activeNodes.
  ///
  /// In en, this message translates to:
  /// **'Active Nodes'**
  String get activeNodes;

  /// No description provided for @activeNodesDesc.
  ///
  /// In en, this message translates to:
  /// **'Nodes that are currently being used'**
  String get activeNodesDesc;

  /// No description provided for @currentNodes.
  ///
  /// In en, this message translates to:
  /// **'Current Nodes'**
  String get currentNodes;

  /// No description provided for @currentNodesDesc.
  ///
  /// In en, this message translates to:
  /// **'Nodes that are selected'**
  String get currentNodesDesc;

  /// No description provided for @recommendedNodes.
  ///
  /// In en, this message translates to:
  /// **'Recommended Nodes'**
  String get recommendedNodes;

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// No description provided for @realtimeRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get realtimeRate;

  /// No description provided for @realtimeRateDesc.
  ///
  /// In en, this message translates to:
  /// **'Observerd rate of the node: speed of downloading 10KB data.'**
  String get realtimeRateDesc;

  /// No description provided for @realtimeLatency.
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get realtimeLatency;

  /// No description provided for @realtimeLatencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Observerd latency of the node: the time used to get a response'**
  String get realtimeLatencyDesc;

  /// No description provided for @realtimeSpeedSamplingInterval.
  ///
  /// In en, this message translates to:
  /// **'Realtime speed sampling interval'**
  String get realtimeSpeedSamplingInterval;

  /// No description provided for @realtimeSpeedSamplingSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second} other{{count} seconds}}'**
  String realtimeSpeedSamplingSeconds(int count);

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noData;

  /// No description provided for @autoTestNodes.
  ///
  /// In en, this message translates to:
  /// **'Nodes Test'**
  String get autoTestNodes;

  /// No description provided for @autoTestNodesDesc.
  ///
  /// In en, this message translates to:
  /// **'Periodically test nodes and automatically test new nodes'**
  String get autoTestNodesDesc;

  /// No description provided for @autoUpdateGeoFiles.
  ///
  /// In en, this message translates to:
  /// **'Auto Update Geo Files'**
  String get autoUpdateGeoFiles;

  /// No description provided for @autoUpdateGeoFilesDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically update geo files at the configured interval'**
  String get autoUpdateGeoFilesDesc;

  /// No description provided for @geoUpdateInterval.
  ///
  /// In en, this message translates to:
  /// **'Update Interval'**
  String get geoUpdateInterval;

  /// No description provided for @geoUpdateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get geoUpdateNow;

  /// No description provided for @geoRestoreToDefault.
  ///
  /// In en, this message translates to:
  /// **'Restore to Default'**
  String get geoRestoreToDefault;

  /// No description provided for @geoUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Geo update success'**
  String get geoUpdateSuccess;

  /// No description provided for @interval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get interval;

  /// No description provided for @shareWithVXclient.
  ///
  /// In en, this message translates to:
  /// **'Share with VX clients'**
  String get shareWithVXclient;

  /// No description provided for @shareWithOtherClients.
  ///
  /// In en, this message translates to:
  /// **'Share with Other Clients'**
  String get shareWithOtherClients;

  /// No description provided for @shareWithOtherClientsNotice.
  ///
  /// In en, this message translates to:
  /// **'There might be incompatibility issues'**
  String get shareWithOtherClientsNotice;

  /// No description provided for @homeEditStandardLayout.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get homeEditStandardLayout;

  /// No description provided for @homeEditCustomizableLayout.
  ///
  /// In en, this message translates to:
  /// **'Customizable'**
  String get homeEditCustomizableLayout;

  /// No description provided for @domainStrategyDesc.
  ///
  /// In en, this message translates to:
  /// **'Determine how to resolve domains when dialing. PreferIPv4: lookup both IPv4 and IPv6(if default nic support 6), wait for the two queries to complete, then try IPv4s, if failed, try IPv6s; PreferIPv6: lookup both IPv4 and IPv6(if default nic support 6), wait for the two queries to complete, then try IPv6s first, if failed, use IPv4; IPv4Only: only lookup IPv4; IPv6Only: only lookup IPv6; Speed: lookup both A and AAAA(if default nic support 6), use the first returned result (might be IPv4s or IPv6s), if failed, use the other IPs.'**
  String get domainStrategyDesc;

  /// No description provided for @uotDesc.
  ///
  /// In en, this message translates to:
  /// **'Use TCP to transport UDP (Sagernet UDP over TCP v2 protocol). The server must also support it'**
  String get uotDesc;

  /// No description provided for @maxConcurrency.
  ///
  /// In en, this message translates to:
  /// **'Max Concurrency'**
  String get maxConcurrency;

  /// No description provided for @maxConnection.
  ///
  /// In en, this message translates to:
  /// **'Max Connection'**
  String get maxConnection;

  /// No description provided for @vxNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'VX-core is not installed'**
  String get vxNotInstalled;

  /// No description provided for @vxVersionTooLow.
  ///
  /// In en, this message translates to:
  /// **'VX-core version is too low, please update to the latest version'**
  String get vxVersionTooLow;

  /// No description provided for @howToUseVX.
  ///
  /// In en, this message translates to:
  /// **'For instructions, check our YouTube channel'**
  String get howToUseVX;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to VX'**
  String get welcome;

  /// No description provided for @sourceCodeAvailable.
  ///
  /// In en, this message translates to:
  /// **'VX is a open-source proxy client powered by vx-core.'**
  String get sourceCodeAvailable;

  /// No description provided for @vxSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code of VX'**
  String get vxSourceCode;

  /// No description provided for @vxCoreSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code of VX-Core'**
  String get vxCoreSourceCode;

  /// No description provided for @windowsUpdateNotice1.
  ///
  /// In en, this message translates to:
  /// **'If you update to this app from a 2.x.x version, to reuse your previous database and preference, close the app, rename the following folder: '**
  String get windowsUpdateNotice1;

  /// No description provided for @windowsUpdateNotice2.
  ///
  /// In en, this message translates to:
  /// **'Then start app.'**
  String get windowsUpdateNotice2;

  /// No description provided for @copyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy Path'**
  String get copyPath;

  /// No description provided for @invalidFields.
  ///
  /// In en, this message translates to:
  /// **'Form contains invalid fields, please correct them first'**
  String get invalidFields;

  /// No description provided for @lruSizeDesc.
  ///
  /// In en, this message translates to:
  /// **'The number of fake DNS records to cache for each cidr. '**
  String get lruSizeDesc;

  /// No description provided for @cacheDuration.
  ///
  /// In en, this message translates to:
  /// **'Cache Duration'**
  String get cacheDuration;

  /// No description provided for @cacheDurationDesc.
  ///
  /// In en, this message translates to:
  /// **'How long to cache DNS record. If empty or 0, DNS records will cached until they expire'**
  String get cacheDurationDesc;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate This Device'**
  String get activate;

  /// No description provided for @activateDesc.
  ///
  /// In en, this message translates to:
  /// **'After activation, you can use most Pro features without logging in (except for cloud sync and cloud backup). Each account can activate up to 10 devices per year.'**
  String get activateDesc;

  /// No description provided for @activated.
  ///
  /// In en, this message translates to:
  /// **'Activated'**
  String get activated;

  /// No description provided for @myInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'My Invitation Code'**
  String get myInvitationCode;

  /// No description provided for @myInvitationCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Share this code to your friends, both sides will get 3 month of pro features for free'**
  String get myInvitationCodeDesc;

  /// No description provided for @useInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Use Invitation Code'**
  String get useInvitationCode;

  /// No description provided for @useInvitationCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Input other\'s invitation code to get 3 month of pro features for both!'**
  String get useInvitationCodeDesc;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @remainingTime.
  ///
  /// In en, this message translates to:
  /// **'Remaining Times'**
  String get remainingTime;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @deploySuccessWarnings.
  ///
  /// In en, this message translates to:
  /// **'Deploy nodes successfully, but these tasks failed: '**
  String get deploySuccessWarnings;

  /// No description provided for @subString.
  ///
  /// In en, this message translates to:
  /// **'Sub String'**
  String get subString;

  /// No description provided for @echDomain.
  ///
  /// In en, this message translates to:
  /// **'ECH Domain'**
  String get echDomain;

  /// No description provided for @generateEchConfig.
  ///
  /// In en, this message translates to:
  /// **'Generate ECH Config'**
  String get generateEchConfig;

  /// No description provided for @echDomainDesc.
  ///
  /// In en, this message translates to:
  /// **'Outer ClientHello SNI'**
  String get echDomainDesc;

  /// No description provided for @restoreSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Restore Successful'**
  String get restoreSuccessful;

  /// No description provided for @pleaseUseAnotherEmail.
  ///
  /// In en, this message translates to:
  /// **'Unsupported email, please use another email'**
  String get pleaseUseAnotherEmail;

  /// No description provided for @dbError.
  ///
  /// In en, this message translates to:
  /// **'Something wrong with database: {error}. Restart VX might help.'**
  String dbError(String error);

  /// No description provided for @dnsRecord.
  ///
  /// In en, this message translates to:
  /// **'DNS Record'**
  String get dnsRecord;

  /// No description provided for @addDnsRecord.
  ///
  /// In en, this message translates to:
  /// **'Add DNS Record'**
  String get addDnsRecord;

  /// No description provided for @internalDns.
  ///
  /// In en, this message translates to:
  /// **'Internal DNS Servers'**
  String get internalDns;

  /// No description provided for @fallback.
  ///
  /// In en, this message translates to:
  /// **'Fallback'**
  String get fallback;

  /// No description provided for @fallbackDesc.
  ///
  /// In en, this message translates to:
  /// **'If the handler picked for this rule failed, use the following fallbacks. Each fallback has a list of conditions, the fallback will be used only if any condition is true.'**
  String get fallbackDesc;

  /// No description provided for @rewriteIpToDomain.
  ///
  /// In en, this message translates to:
  /// **'Rewrite IP to Domain'**
  String get rewriteIpToDomain;

  /// No description provided for @rewriteIpToDomainDesc.
  ///
  /// In en, this message translates to:
  /// **'If the request address is IP, and there is sniffed domain, then use the sniffed domain as the request address. This is a measure for DNS pollution'**
  String get rewriteIpToDomainDesc;

  /// No description provided for @resultIpSet.
  ///
  /// In en, this message translates to:
  /// **'Result IP Set'**
  String get resultIpSet;

  /// No description provided for @resultIpSetDesc.
  ///
  /// In en, this message translates to:
  /// **'A/AAAA records whose IPs are not in the set will be dropped'**
  String get resultIpSetDesc;

  /// No description provided for @inverse.
  ///
  /// In en, this message translates to:
  /// **'Inverse'**
  String get inverse;

  /// No description provided for @automaticallyAddFallbackDomain.
  ///
  /// In en, this message translates to:
  /// **'Automatically Add Fallback Domain'**
  String get automaticallyAddFallbackDomain;

  /// No description provided for @automaticallyAddFallbackDomainDesc.
  ///
  /// In en, this message translates to:
  /// **'If a connection initially went direct but failed, then it fallbacked to proxy and succeeded, automatically add the domain into a domain set called \"Fallback\"'**
  String get automaticallyAddFallbackDomainDesc;

  /// No description provided for @fallbackTimeout.
  ///
  /// In en, this message translates to:
  /// **'Fallback Timeout'**
  String get fallbackTimeout;

  /// No description provided for @fallbackTimeoutDesc.
  ///
  /// In en, this message translates to:
  /// **'If a connection did not receive any data after the fallback timeout, this connection will start fallbacking and use the next handler to retry.'**
  String get fallbackTimeoutDesc;

  /// No description provided for @directDialingTimeout.
  ///
  /// In en, this message translates to:
  /// **'Direct Dialing Timeout'**
  String get directDialingTimeout;

  /// No description provided for @directDialingTimeoutHint.
  ///
  /// In en, this message translates to:
  /// **'The dial timeout for direct connection. If failed to establish TCP connection within this timeout, the connection will fail.'**
  String get directDialingTimeoutHint;

  /// No description provided for @globalDialTimeout.
  ///
  /// In en, this message translates to:
  /// **'Global Dial Timeout'**
  String get globalDialTimeout;

  /// No description provided for @globalDialTimeoutHint.
  ///
  /// In en, this message translates to:
  /// **'The dial timeout for all nodes. If failed to establish TCP connection within this timeout, the connection will fail.'**
  String get globalDialTimeoutHint;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will reset your preferences and database. Your existing data will be lost. This action cannot be undone.'**
  String get resetConfirmMessage;

  /// No description provided for @resetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetAction;

  /// No description provided for @resetCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset complete'**
  String get resetCompletedTitle;

  /// No description provided for @resetCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Database and preferences have been reset. Restart VX to continue.'**
  String get resetCompletedMessage;

  /// No description provided for @repairDbSchemaTitle.
  ///
  /// In en, this message translates to:
  /// **'Repair database schema'**
  String get repairDbSchemaTitle;

  /// No description provided for @repairDbSchemaAction.
  ///
  /// In en, this message translates to:
  /// **'Repair DB Schema'**
  String get repairDbSchemaAction;

  /// No description provided for @repairDbSchemaSuccess.
  ///
  /// In en, this message translates to:
  /// **'Database schema repaired successfully'**
  String get repairDbSchemaSuccess;

  /// No description provided for @repairDbSchemaFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to repair database schema: {error}'**
  String repairDbSchemaFailed(String error);

  /// No description provided for @resetFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset: {error}'**
  String resetFailed(String error);

  /// No description provided for @policyTimeout.
  ///
  /// In en, this message translates to:
  /// **'Policy Timeout'**
  String get policyTimeout;

  /// No description provided for @policyTimeoutNoTimeoutHint.
  ///
  /// In en, this message translates to:
  /// **'0 means no timeout'**
  String get policyTimeoutNoTimeoutHint;

  /// No description provided for @policyTcpIdleTimeout.
  ///
  /// In en, this message translates to:
  /// **'TCP Idle Timeout'**
  String get policyTcpIdleTimeout;

  /// No description provided for @policyTcpIdleTimeoutDesc.
  ///
  /// In en, this message translates to:
  /// **'If uplink or downlink data is absent during this period, the connection will be closed.'**
  String get policyTcpIdleTimeoutDesc;

  /// No description provided for @policyUdpIdleTimeout.
  ///
  /// In en, this message translates to:
  /// **'UDP Idle Timeout'**
  String get policyUdpIdleTimeout;

  /// No description provided for @policyUdpIdleTimeoutDesc.
  ///
  /// In en, this message translates to:
  /// **'If no uplink data is received during this period, the connection will be closed.'**
  String get policyUdpIdleTimeoutDesc;

  /// No description provided for @policyUpLinkOnlyTimeout.
  ///
  /// In en, this message translates to:
  /// **'UpLink Only Timeout'**
  String get policyUpLinkOnlyTimeout;

  /// No description provided for @policyUpLinkOnlyTimeoutDesc.
  ///
  /// In en, this message translates to:
  /// **'If a TCP connection\'s downlink stream is done, the idle timeout switches to this value.'**
  String get policyUpLinkOnlyTimeoutDesc;

  /// No description provided for @policyDownLinkOnlyTimeout.
  ///
  /// In en, this message translates to:
  /// **'DownLink Only Timeout'**
  String get policyDownLinkOnlyTimeout;

  /// No description provided for @policyDownLinkOnlyTimeoutDesc.
  ///
  /// In en, this message translates to:
  /// **'If a TCP connection\'s uplink stream is done, the idle timeout switches to this value.'**
  String get policyDownLinkOnlyTimeoutDesc;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorial;

  /// No description provided for @selectGroup.
  ///
  /// In en, this message translates to:
  /// **'Select Group'**
  String get selectGroup;

  /// No description provided for @addConcurrentDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Add Concurrent DNS Server'**
  String get addConcurrentDnsServer;

  /// No description provided for @addSerialDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Add Serial DNS Server'**
  String get addSerialDnsServer;

  /// No description provided for @concurrentDnsServerType.
  ///
  /// In en, this message translates to:
  /// **'Concurrent DNS Server'**
  String get concurrentDnsServerType;

  /// No description provided for @serialDnsServerType.
  ///
  /// In en, this message translates to:
  /// **'Serial DNS Server'**
  String get serialDnsServerType;

  /// No description provided for @useSystemDnsResolver.
  ///
  /// In en, this message translates to:
  /// **'Use system DNS resolver'**
  String get useSystemDnsResolver;

  /// No description provided for @alwaysReturnEmptyDnsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Always return empty DNS answer'**
  String get alwaysReturnEmptyDnsAnswer;

  /// No description provided for @dnsPool.
  ///
  /// In en, this message translates to:
  /// **'Pool'**
  String get dnsPool;

  /// No description provided for @dnsServers.
  ///
  /// In en, this message translates to:
  /// **'DNS Servers'**
  String get dnsServers;

  /// No description provided for @invalidInterval.
  ///
  /// In en, this message translates to:
  /// **'Invalid interval'**
  String get invalidInterval;

  /// No description provided for @addresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addresses;

  /// No description provided for @clientIp.
  ///
  /// In en, this message translates to:
  /// **'Client IP'**
  String get clientIp;

  /// No description provided for @lruSize.
  ///
  /// In en, this message translates to:
  /// **'LRU Size'**
  String get lruSize;

  /// No description provided for @useGoRuntimeDnsResolver.
  ///
  /// In en, this message translates to:
  /// **'Use Go runtime DNS resolver.'**
  String get useGoRuntimeDnsResolver;

  /// No description provided for @alwaysReturnEmptyDnsResponse.
  ///
  /// In en, this message translates to:
  /// **'Always returns empty response for DNS queries.'**
  String get alwaysReturnEmptyDnsResponse;

  /// No description provided for @dnsTypeFake.
  ///
  /// In en, this message translates to:
  /// **'Fake'**
  String get dnsTypeFake;

  /// No description provided for @dnsTypePlain.
  ///
  /// In en, this message translates to:
  /// **'UDP/TCP'**
  String get dnsTypePlain;

  /// No description provided for @dnsTypeDoh.
  ///
  /// In en, this message translates to:
  /// **'HTTPS'**
  String get dnsTypeDoh;

  /// No description provided for @dnsTypeTls.
  ///
  /// In en, this message translates to:
  /// **'TLS'**
  String get dnsTypeTls;

  /// No description provided for @dnsTypeQuic.
  ///
  /// In en, this message translates to:
  /// **'QUIC'**
  String get dnsTypeQuic;

  /// No description provided for @dnsTypeGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get dnsTypeGo;

  /// No description provided for @dnsTypeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get dnsTypeEmpty;

  /// No description provided for @reservedDnsServerName.
  ///
  /// In en, this message translates to:
  /// **'DNS server name \"hijack\" is reserved'**
  String get reservedDnsServerName;

  /// No description provided for @handlersInUseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 handler} other{{count} handlers}}'**
  String handlersInUseCount(int count);

  /// No description provided for @selectorHandlersInUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Handlers in use'**
  String get selectorHandlersInUseTitle;

  /// No description provided for @addFreeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add Free Subscription'**
  String get addFreeSubscription;

  /// No description provided for @resetSubscriptionLink.
  ///
  /// In en, this message translates to:
  /// **'Reset subscription link'**
  String get resetSubscriptionLink;

  /// No description provided for @addFreeSubscriptionDesc.
  ///
  /// In en, this message translates to:
  /// **'Once clicked, a subscription named \"{name}\" will be added. The subscription might not have available nodes at any time. The remaining traffic of the subscription will be updated daily.'**
  String addFreeSubscriptionDesc(String name);

  /// No description provided for @resetSubscriptionLinkDesc.
  ///
  /// In en, this message translates to:
  /// **'Once clicked, the subscription link will be reset. The new link will be used to fetch the subscription. This can be used to prevent leak of your subscription link.'**
  String get resetSubscriptionLinkDesc;

  /// No description provided for @maxUsersOnly.
  ///
  /// In en, this message translates to:
  /// **'These features are available to Max users only.'**
  String get maxUsersOnly;

  /// No description provided for @cnDomainsGoDirectRule.
  ///
  /// In en, this message translates to:
  /// **'CN domains go direct'**
  String get cnDomainsGoDirectRule;

  /// No description provided for @cnIpsGoDirectRule.
  ///
  /// In en, this message translates to:
  /// **'CN IPs go direct'**
  String get cnIpsGoDirectRule;

  /// No description provided for @cnExcludeGfwDomains.
  ///
  /// In en, this message translates to:
  /// **'CN Domains Exclude GFW'**
  String get cnExcludeGfwDomains;

  /// No description provided for @hysteriaRealm.
  ///
  /// In en, this message translates to:
  /// **'Hysteria Realm'**
  String get hysteriaRealm;

  /// No description provided for @enableRealmServer.
  ///
  /// In en, this message translates to:
  /// **'Enable Realm server'**
  String get enableRealmServer;

  /// No description provided for @enableRealmServerDesc.
  ///
  /// In en, this message translates to:
  /// **'Run a Hysteria Realm inbound while VX is connected'**
  String get enableRealmServerDesc;

  /// No description provided for @configureServerSettingsFirst.
  ///
  /// In en, this message translates to:
  /// **'Configure server settings first'**
  String get configureServerSettingsFirst;

  /// No description provided for @configureRealmSettings.
  ///
  /// In en, this message translates to:
  /// **'Configure realm settings below'**
  String get configureRealmSettings;

  /// No description provided for @enterDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Enter a device name'**
  String get enterDeviceName;

  /// No description provided for @configureValidRealmUrlFirst.
  ///
  /// In en, this message translates to:
  /// **'Configure a valid Realm URL first'**
  String get configureValidRealmUrlFirst;

  /// No description provided for @failedInboundToOutbound.
  ///
  /// In en, this message translates to:
  /// **'Failed to convert inbound config to outbound config'**
  String get failedInboundToOutbound;

  /// No description provided for @failedConvertToUrl.
  ///
  /// In en, this message translates to:
  /// **'Failed to convert to URL. {details}'**
  String failedConvertToUrl(String details);

  /// No description provided for @realmDeviceRegistered.
  ///
  /// In en, this message translates to:
  /// **'Device registered for other clients'**
  String get realmDeviceRegistered;

  /// No description provided for @realmUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String realmUploadFailed(String error);

  /// No description provided for @registerForOtherDevices.
  ///
  /// In en, this message translates to:
  /// **'Register for other devices'**
  String get registerForOtherDevices;

  /// No description provided for @registerForOtherDevicesDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload your device name and an encrypted Realm URL so your other VX clients can add this device via Nodes → Add → Realm device. Share the encryption password separately.'**
  String get registerForOtherDevicesDesc;

  /// No description provided for @realmDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get realmDeviceName;

  /// No description provided for @realmDeviceNameHint.
  ///
  /// In en, this message translates to:
  /// **'My phone'**
  String get realmDeviceNameHint;

  /// No description provided for @realmDeviceNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Label shown in the picker on your other devices'**
  String get realmDeviceNameHelper;

  /// No description provided for @uploadToCloud.
  ///
  /// In en, this message translates to:
  /// **'Upload to cloud'**
  String get uploadToCloud;

  /// No description provided for @realmServerConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Server configuration'**
  String get realmServerConfiguration;

  /// No description provided for @realmReadyToRun.
  ///
  /// In en, this message translates to:
  /// **'Ready to run'**
  String get realmReadyToRun;

  /// No description provided for @realmNeedsSetup.
  ///
  /// In en, this message translates to:
  /// **'Needs setup'**
  String get realmNeedsSetup;

  /// No description provided for @realmAuth.
  ///
  /// In en, this message translates to:
  /// **'Auth'**
  String get realmAuth;

  /// No description provided for @realmNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get realmNotSet;

  /// No description provided for @realmConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get realmConfigured;

  /// No description provided for @realmRendezvous.
  ///
  /// In en, this message translates to:
  /// **'Rendezvous'**
  String get realmRendezvous;

  /// No description provided for @realmId.
  ///
  /// In en, this message translates to:
  /// **'Realm ID'**
  String get realmId;

  /// No description provided for @realmUrl.
  ///
  /// In en, this message translates to:
  /// **'Realm URL'**
  String get realmUrl;

  /// No description provided for @realmNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get realmNotConfigured;

  /// No description provided for @realmLocalPort.
  ///
  /// In en, this message translates to:
  /// **'Local port'**
  String get realmLocalPort;

  /// No description provided for @realmTlsSni.
  ///
  /// In en, this message translates to:
  /// **'TLS SNI'**
  String get realmTlsSni;

  /// No description provided for @realmObfuscation.
  ///
  /// In en, this message translates to:
  /// **'Obfuscation'**
  String get realmObfuscation;

  /// No description provided for @salamander.
  ///
  /// In en, this message translates to:
  /// **'Salamander'**
  String get salamander;

  /// No description provided for @realmSection.
  ///
  /// In en, this message translates to:
  /// **'Realm'**
  String get realmSection;

  /// No description provided for @ignoreClientBandwidth.
  ///
  /// In en, this message translates to:
  /// **'Ignore Client Bandwidth'**
  String get ignoreClientBandwidth;

  /// No description provided for @realmUrlHint.
  ///
  /// In en, this message translates to:
  /// **'realm://public@realm.hy2.io/random-realm-id'**
  String get realmUrlHint;

  /// No description provided for @generateRealmUrl.
  ///
  /// In en, this message translates to:
  /// **'Generate Realm URL'**
  String get generateRealmUrl;

  /// No description provided for @autoConfigureRealmServer.
  ///
  /// In en, this message translates to:
  /// **'Auto-configure'**
  String get autoConfigureRealmServer;

  /// No description provided for @realmAutoConfigured.
  ///
  /// In en, this message translates to:
  /// **'Realm server configured'**
  String get realmAutoConfigured;

  /// No description provided for @realmAutoConfigureFailed.
  ///
  /// In en, this message translates to:
  /// **'Auto-configuration failed: {error}'**
  String realmAutoConfigureFailed(String error);

  /// No description provided for @realmLocalPortHelper.
  ///
  /// In en, this message translates to:
  /// **'Local UDP port for realm punch; empty uses random port'**
  String get realmLocalPortHelper;

  /// No description provided for @insecureRendezvous.
  ///
  /// In en, this message translates to:
  /// **'Insecure rendezvous'**
  String get insecureRendezvous;

  /// No description provided for @insecureRendezvousDesc.
  ///
  /// In en, this message translates to:
  /// **'Skip SNI verification for rendezvous server'**
  String get insecureRendezvousDesc;

  /// No description provided for @stunServers.
  ///
  /// In en, this message translates to:
  /// **'STUN servers'**
  String get stunServers;

  /// No description provided for @stunServersHint.
  ///
  /// In en, this message translates to:
  /// **'stun.l.google.com:19302'**
  String get stunServersHint;

  /// No description provided for @stunTimeoutSeconds.
  ///
  /// In en, this message translates to:
  /// **'STUN timeout (s)'**
  String get stunTimeoutSeconds;

  /// No description provided for @punchTimeoutSeconds.
  ///
  /// In en, this message translates to:
  /// **'Punch timeout (s)'**
  String get punchTimeoutSeconds;

  /// No description provided for @heartbeatIntervalSeconds.
  ///
  /// In en, this message translates to:
  /// **'Heartbeat interval (s)'**
  String get heartbeatIntervalSeconds;

  /// No description provided for @ipMode.
  ///
  /// In en, this message translates to:
  /// **'IP mode'**
  String get ipMode;

  /// No description provided for @portMappingUpnp.
  ///
  /// In en, this message translates to:
  /// **'Port mapping (UPnP/NAT-PMP)'**
  String get portMappingUpnp;

  /// No description provided for @mappingTimeoutSeconds.
  ///
  /// In en, this message translates to:
  /// **'Mapping timeout (s)'**
  String get mappingTimeoutSeconds;

  /// No description provided for @mappingLifetimeSeconds.
  ///
  /// In en, this message translates to:
  /// **'Mapping lifetime (s)'**
  String get mappingLifetimeSeconds;

  /// No description provided for @addRealmOutbound.
  ///
  /// In en, this message translates to:
  /// **'Add Realm Outbound'**
  String get addRealmOutbound;

  /// No description provided for @realmDevicePicker.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get realmDevicePicker;

  /// No description provided for @failedLoadRealmDevices.
  ///
  /// In en, this message translates to:
  /// **'Failed to load realm devices: {error}'**
  String failedLoadRealmDevices(String error);

  /// No description provided for @noRealmDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No other devices with Realm configured were found'**
  String get noRealmDevicesFound;

  /// No description provided for @invalidRealmUrlForDevice.
  ///
  /// In en, this message translates to:
  /// **'Invalid realm URL for selected device'**
  String get invalidRealmUrlForDevice;

  /// No description provided for @addedRealmDevice.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String addedRealmDevice(String name);

  /// No description provided for @realmServer.
  ///
  /// In en, this message translates to:
  /// **'Realm server'**
  String get realmServer;

  /// No description provided for @realmRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get realmRegistered;

  /// No description provided for @realmRegistering.
  ///
  /// In en, this message translates to:
  /// **'Registering…'**
  String get realmRegistering;

  /// No description provided for @realmPeersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 peer} other{{count} peers}}'**
  String realmPeersCount(int count);

  /// No description provided for @discoveringPublicAddresses.
  ///
  /// In en, this message translates to:
  /// **'Discovering public addresses…'**
  String get discoveringPublicAddresses;

  /// No description provided for @realmDevice.
  ///
  /// In en, this message translates to:
  /// **'Realm device'**
  String get realmDevice;

  /// No description provided for @realmCloudEncryptionPassword.
  ///
  /// In en, this message translates to:
  /// **'Cloud encryption password'**
  String get realmCloudEncryptionPassword;

  /// No description provided for @realmCloudEncryptionPasswordHelper.
  ///
  /// In en, this message translates to:
  /// **'Other devices need this password to decrypt the uploaded URL. It is never stored on the server.'**
  String get realmCloudEncryptionPasswordHelper;

  /// No description provided for @enterRealmCloudEncryptionPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a cloud encryption password'**
  String get enterRealmCloudEncryptionPassword;

  /// No description provided for @realmDecryptPassword.
  ///
  /// In en, this message translates to:
  /// **'Decryption password'**
  String get realmDecryptPassword;

  /// No description provided for @realmDecryptPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the password shared by the device owner to decrypt its Realm URL.'**
  String get realmDecryptPasswordDesc;

  /// No description provided for @realmDecryptFailed.
  ///
  /// In en, this message translates to:
  /// **'Wrong password or invalid encrypted Realm URL'**
  String get realmDecryptFailed;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
