import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final currentIndex = appProvider.currentPageIndex;
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationDrawer(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        appProvider.setCurrentPageIndex(index);
        Navigator.of(context).pop();
      },
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.grid_on,
                size: 48,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 12),
              Text(
                '拼豆设计器',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Perler Bead Designer',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
              ),
            ],
          ),
        ),
        ...AppPage.values.map((page) {
          return NavigationDrawerDestination(
            icon: Icon(page.icon),
            selectedIcon: Icon(page.selectedIcon),
            label: Text(page.label),
          );
        }),
        const Divider(indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '版本 1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
