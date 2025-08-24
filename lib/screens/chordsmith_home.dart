import 'package:flutter/material.dart';
import '../widgets/chordsmith_app_bar.dart';
import '../widgets/chordsmith_main_button.dart';
import 'search_screen.dart';
import 'create_chord_screen.dart';
import 'edit_chord_screen.dart';
import 'favorites_screen.dart';

class ChordsmithHome extends StatelessWidget {
  const ChordsmithHome({super.key});

  static const double horizontalMargin = 24.0;
  static const double buttonSpacing = 20.0;

  @override
  Widget build(BuildContext context) {
    final List<_MainAction> actions = [
      _MainAction(label: 'Search', icon: Icons.search, onTap: () {Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SearchScreen()));}),
      _MainAction(label: 'Create', icon: Icons.add, onTap: () {Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateChordScreen()));}),
      _MainAction(label: 'Edit', icon: Icons.edit, onTap: () {Navigator.push(context, MaterialPageRoute(builder: (_) => const EditChordScreen()));}),
      _MainAction(label: 'Share', icon: Icons.share, onTap: () {/* TODO */}),
      _MainAction(label: 'Favorites', icon: Icons.star, onTap: () {Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));}),
      _MainAction(label: 'Reports', icon: Icons.picture_as_pdf, onTap: () {/* TODO */}),
    ];

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: ChordsmithAppBar(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: horizontalMargin),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...actions.map((action) => Padding(
                padding: const EdgeInsets.only(bottom: buttonSpacing),
                child: ChordsmithMainButton(
                  label: action.label,
                  icon: action.icon,
                  onTap: action.onTap,
                ),
              )),
            ],
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
  _MainAction({required this.label, required this.icon, required this.onTap});
}
