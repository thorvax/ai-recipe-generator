import 'package:flutter/material.dart';

import '../../shared/widgets/app_bottom_nav.dart';
import '../generator/ingredient_input_screen.dart';
import '../settings/settings_screen.dart';
import 'coming_soon_tab.dart';

/// The screen shown after login: 4 tabs + bottom navigation.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps each tab alive, so the ingredient form
      // is not wiped when you switch tabs.
      body: IndexedStack(
        index: _index,
        children: const [
          IngredientInputScreen(),
          ComingSoonTab(
            icon: Icons.bookmark_border,
            title: 'Saved recipes',
            message: 'Your saved recipes will show up here (Step 6).',
          ),
          ComingSoonTab(
            icon: Icons.groups_outlined,
            title: 'Community',
            message: 'Recipes shared by other cooks will show up here (Step 7).',
          ),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
