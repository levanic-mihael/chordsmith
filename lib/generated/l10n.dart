// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Chordsmith`
  String get appTitle {
    return Intl.message('Chordsmith', name: 'appTitle', desc: '', args: []);
  }

  /// `Search`
  String get search {
    return Intl.message('Search', name: 'search', desc: '', args: []);
  }

  /// `Create`
  String get create {
    return Intl.message('Create', name: 'create', desc: '', args: []);
  }

  /// `Edit`
  String get edit {
    return Intl.message('Edit', name: 'edit', desc: '', args: []);
  }

  /// `Share`
  String get share {
    return Intl.message('Share', name: 'share', desc: '', args: []);
  }

  /// `Favorites`
  String get favorites {
    return Intl.message('Favorites', name: 'favorites', desc: '', args: []);
  }

  /// `Reports`
  String get reports {
    return Intl.message('Reports', name: 'reports', desc: '', args: []);
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Dark Mode`
  String get darkMode {
    return Intl.message('Dark Mode', name: 'darkMode', desc: '', args: []);
  }

  /// `Save Settings`
  String get saveSettings {
    return Intl.message(
      'Save Settings',
      name: 'saveSettings',
      desc: '',
      args: [],
    );
  }

  /// `Settings saved`
  String get settingsSaved {
    return Intl.message(
      'Settings saved',
      name: 'settingsSaved',
      desc: '',
      args: [],
    );
  }

  /// `Please set chord fingers on fretboard`
  String get pleaseSetChordFingers {
    return Intl.message(
      'Please set chord fingers on fretboard',
      name: 'pleaseSetChordFingers',
      desc: '',
      args: [],
    );
  }

  /// `Enter custom chord name`
  String get enterCustomChordName {
    return Intl.message(
      'Enter custom chord name',
      name: 'enterCustomChordName',
      desc: '',
      args: [],
    );
  }

  /// `Custom chord saved.`
  String get customChordSaved {
    return Intl.message(
      'Custom chord saved.',
      name: 'customChordSaved',
      desc: '',
      args: [],
    );
  }

  /// `Select tone, mode, and type.`
  String get selectToneModeType {
    return Intl.message(
      'Select tone, mode, and type.',
      name: 'selectToneModeType',
      desc: '',
      args: [],
    );
  }

  /// `Standard chord not found.`
  String get standardChordNotFound {
    return Intl.message(
      'Standard chord not found.',
      name: 'standardChordNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Alternative chord saved.`
  String get alternativeChordSaved {
    return Intl.message(
      'Alternative chord saved.',
      name: 'alternativeChordSaved',
      desc: '',
      args: [],
    );
  }

  /// `Create Chord`
  String get createChord {
    return Intl.message(
      'Create Chord',
      name: 'createChord',
      desc: '',
      args: [],
    );
  }

  /// `New Chord`
  String get newChord {
    return Intl.message('New Chord', name: 'newChord', desc: '', args: []);
  }

  /// `Alternative`
  String get alternative {
    return Intl.message('Alternative', name: 'alternative', desc: '', args: []);
  }

  /// `Enter name for new chord:`
  String get enterNameForNewChord {
    return Intl.message(
      'Enter name for new chord:',
      name: 'enterNameForNewChord',
      desc: '',
      args: [],
    );
  }

  /// `Chord name`
  String get enterChordNameHint {
    return Intl.message(
      'Chord name',
      name: 'enterChordNameHint',
      desc: '',
      args: [],
    );
  }

  /// `Select chord to create alternative for:`
  String get selectChordToCreateAlternative {
    return Intl.message(
      'Select chord to create alternative for:',
      name: 'selectChordToCreateAlternative',
      desc: '',
      args: [],
    );
  }

  /// `Save Chord`
  String get saveChord {
    return Intl.message('Save Chord', name: 'saveChord', desc: '', args: []);
  }

  /// `Delete Chord`
  String get deleteChord {
    return Intl.message(
      'Delete Chord',
      name: 'deleteChord',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete "{chordName}"?`
  String confirmDeleteChord(Object chordName) {
    return Intl.message(
      'Are you sure you want to delete "$chordName"?',
      name: 'confirmDeleteChord',
      desc: '',
      args: [chordName],
    );
  }

  /// `No`
  String get no {
    return Intl.message('No', name: 'no', desc: '', args: []);
  }

  /// `Yes`
  String get yes {
    return Intl.message('Yes', name: 'yes', desc: '', args: []);
  }

  /// `Chord saved.`
  String get chordSaved {
    return Intl.message('Chord saved.', name: 'chordSaved', desc: '', args: []);
  }

  /// `Edit Alternative Chord`
  String get editAlternativeChord {
    return Intl.message(
      'Edit Alternative Chord',
      name: 'editAlternativeChord',
      desc: '',
      args: [],
    );
  }

  /// `Edit Custom Chord`
  String get editCustomChord {
    return Intl.message(
      'Edit Custom Chord',
      name: 'editCustomChord',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Edit Chords`
  String get editChords {
    return Intl.message('Edit Chords', name: 'editChords', desc: '', args: []);
  }

  /// `Standard Chords`
  String get standardChords {
    return Intl.message(
      'Standard Chords',
      name: 'standardChords',
      desc: '',
      args: [],
    );
  }

  /// `Alternative Chords`
  String get alternativeChords {
    return Intl.message(
      'Alternative Chords',
      name: 'alternativeChords',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get unknown {
    return Intl.message('Unknown', name: 'unknown', desc: '', args: []);
  }

  /// `Mark as Favorite`
  String get markFavorite {
    return Intl.message(
      'Mark as Favorite',
      name: 'markFavorite',
      desc: '',
      args: [],
    );
  }

  /// `Unmark Favorite`
  String get unmarkFavorite {
    return Intl.message(
      'Unmark Favorite',
      name: 'unmarkFavorite',
      desc: '',
      args: [],
    );
  }

  /// `Edit Chord`
  String get editChord {
    return Intl.message('Edit Chord', name: 'editChord', desc: '', args: []);
  }

  /// `this chord`
  String get thisChord {
    return Intl.message('this chord', name: 'thisChord', desc: '', args: []);
  }

  /// `Custom Chord`
  String get customChord {
    return Intl.message(
      'Custom Chord',
      name: 'customChord',
      desc: '',
      args: [],
    );
  }

  /// `Chord`
  String get chord {
    return Intl.message('Chord', name: 'chord', desc: '', args: []);
  }

  /// `No favorites yet`
  String get noFavoritesYet {
    return Intl.message(
      'No favorites yet',
      name: 'noFavoritesYet',
      desc: '',
      args: [],
    );
  }

  /// `Standard`
  String get standard {
    return Intl.message('Standard', name: 'standard', desc: '', args: []);
  }

  /// `Custom`
  String get custom {
    return Intl.message('Custom', name: 'custom', desc: '', args: []);
  }

  /// `Select Tone:`
  String get selectTone {
    return Intl.message('Select Tone:', name: 'selectTone', desc: '', args: []);
  }

  /// `Select Mode:`
  String get selectMode {
    return Intl.message('Select Mode:', name: 'selectMode', desc: '', args: []);
  }

  /// `Select Chord Type:`
  String get selectChordType {
    return Intl.message(
      'Select Chord Type:',
      name: 'selectChordType',
      desc: '',
      args: [],
    );
  }

  /// `Show Chord`
  String get showChord {
    return Intl.message('Show Chord', name: 'showChord', desc: '', args: []);
  }

  /// `No such chord found`
  String get noSuchChordFound {
    return Intl.message(
      'No such chord found',
      name: 'noSuchChordFound',
      desc: '',
      args: [],
    );
  }

  /// `Custom Chords`
  String get customChords {
    return Intl.message(
      'Custom Chords',
      name: 'customChords',
      desc: '',
      args: [],
    );
  }

  /// `No custom chords yet`
  String get noCustomChordsYet {
    return Intl.message(
      'No custom chords yet',
      name: 'noCustomChordsYet',
      desc: '',
      args: [],
    );
  }

  /// `Alt`
  String get alt {
    return Intl.message('Alt', name: 'alt', desc: '', args: []);
  }

  /// `Account`
  String get account {
    return Intl.message('Account', name: 'account', desc: '', args: []);
  }

  /// `Create new report`
  String get createNewReport {
    return Intl.message(
      'Create new report',
      name: 'createNewReport',
      desc: '',
      args: [],
    );
  }

  /// `No reports yet`
  String get noReportsYet {
    return Intl.message(
      'No reports yet',
      name: 'noReportsYet',
      desc: '',
      args: [],
    );
  }

  /// `Generate PDF`
  String get generate {
    return Intl.message('Generate PDF', name: 'generate', desc: '', args: []);
  }

  /// `Report generated on:`
  String get generatedOn {
    return Intl.message(
      'Report generated on:',
      name: 'generatedOn',
      desc: '',
      args: [],
    );
  }

  /// `Please enter all fields`
  String get pleaseEnterAllFields {
    return Intl.message(
      'Please enter all fields',
      name: 'pleaseEnterAllFields',
      desc: '',
      args: [],
    );
  }

  /// `This username is already taken`
  String get usernameTaken {
    return Intl.message(
      'This username is already taken',
      name: 'usernameTaken',
      desc: '',
      args: [],
    );
  }

  /// `Failed to create account`
  String get errorCreatingAccount {
    return Intl.message(
      'Failed to create account',
      name: 'errorCreatingAccount',
      desc: '',
      args: [],
    );
  }

  /// `Account created`
  String get accountCreated {
    return Intl.message(
      'Account created',
      name: 'accountCreated',
      desc: '',
      args: [],
    );
  }

  /// `Create Account`
  String get createAccount {
    return Intl.message(
      'Create Account',
      name: 'createAccount',
      desc: '',
      args: [],
    );
  }

  /// `First Name`
  String get firstName {
    return Intl.message('First Name', name: 'firstName', desc: '', args: []);
  }

  /// `Last Name`
  String get lastName {
    return Intl.message('Last Name', name: 'lastName', desc: '', args: []);
  }

  /// `Date of Birth`
  String get dateOfBirth {
    return Intl.message(
      'Date of Birth',
      name: 'dateOfBirth',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get username {
    return Intl.message('Username', name: 'username', desc: '', args: []);
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Logout`
  String get logout {
    return Intl.message('Logout', name: 'logout', desc: '', args: []);
  }

  /// `Failed to save changes`
  String get errorSavingChanges {
    return Intl.message(
      'Failed to save changes',
      name: 'errorSavingChanges',
      desc: '',
      args: [],
    );
  }

  /// `Changes saved`
  String get changesSaved {
    return Intl.message(
      'Changes saved',
      name: 'changesSaved',
      desc: '',
      args: [],
    );
  }

  /// `New Password`
  String get newPassword {
    return Intl.message(
      'New Password',
      name: 'newPassword',
      desc: '',
      args: [],
    );
  }

  /// `Leave blank to keep current`
  String get leaveBlankToKeep {
    return Intl.message(
      'Leave blank to keep current',
      name: 'leaveBlankToKeep',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'hr'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
