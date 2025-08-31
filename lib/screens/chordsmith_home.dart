import 'package:flutter/material.dart';

import '../widgets/chordsmith_app_bar.dart';
import '../widgets/chordsmith_main_button.dart';
import 'search_screen.dart';
import 'create_chord_screen.dart';
import 'edit_chord_screen.dart';
import 'favorites_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import '../generated/l10n.dart';

class ChordsmithHome extends StatelessWidget {
  final void Function(Locale locale, bool darkMode)? onSettingsChanged;
  final bool isLoggedIn;
  final String? loggedInUsername;
  final void Function(String username)? onLoginSuccess;

  const ChordsmithHome({
    super.key,
    this.onSettingsChanged,
    this.isLoggedIn = false,
    this.loggedInUsername,
    this.onLoginSuccess,
  });

  static const double horizontalMargin = 24.0;
  static const double buttonSpacing = 20.0;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);

    final List<_MainAction> actions = [
      _MainAction(
        label: strings.search,
        icon: Icons.search,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SearchScreen()));
        },
      ),
      _MainAction(
        label: strings.create,
        icon: Icons.add,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateChordScreen()));
        },
      ),
      _MainAction(
        label: strings.edit,
        icon: Icons.edit,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditChordScreen()));
        },
      ),
      _MainAction(
        label: strings.share,
        icon: Icons.share,
        onTap: () {
          // TODO: implement share action
        },
      ),
      _MainAction(
        label: strings.favorites,
        icon: Icons.star,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen()));
        },
      ),
      _MainAction(
        label: strings.reports,
        icon: Icons.picture_as_pdf,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
        },
      ),
    ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: horizontalMargin),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...actions.map(
                      (action) => Padding(
                    padding: const EdgeInsets.only(bottom: buttonSpacing),
                    child: ChordsmithMainButton(
                      label: action.label,
                      icon: action.icon,
                      onTap: action.onTap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  _MainAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
