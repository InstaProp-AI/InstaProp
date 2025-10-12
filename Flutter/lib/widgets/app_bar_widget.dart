import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Property Flipper',
        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.surface),
      ),
      backgroundColor: AppColors.primary,
      elevation: 0,
      actions: [
        Consumer<AppState>(
          builder: (context, appState, child) {
            if (appState.isLoggedIn) {
              return PopupMenuButton<String>(
                icon: const Icon(
                  Icons.account_circle,
                  color: AppColors.surface,
                ),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await appState.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/auth');
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 8),
                        Text(appState.user?.fullName ?? 'Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/auth');
                },
                child: const Text(
                  'Login',
                  style: TextStyle(color: AppColors.surface),
                ),
              );
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
