import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/saved_provider.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../community/posted_recipes_screen.dart';
import '../generator/ingredient_input_screen.dart';
import '../saved/saved_recipes_screen.dart';
import '../settings/settings_screen.dart';

/// The screen shown after login: 4 tabs + bottom navigation.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Start listening to this user's saved recipes and the community feed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid != null) {
        context.read<SavedProvider>().listen(uid);
        context.read<CommunityProvider>().listen(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps each tab alive, so the ingredient form
      // is not wiped when you switch tabs.
      body: IndexedStack(
        index: _index,
        children: [
          const IngredientInputScreen(),
          SavedRecipesScreen(onGenerate: () => setState(() => _index = 0)),
          const PostedRecipesScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
