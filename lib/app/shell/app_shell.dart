import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../theme/app_spacing.dart';

class _Destination {
  const _Destination(this.route, this.label, this.icon, this.selectedIcon);

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Destination(
    AppRoutes.dashboard,
    'Dashboard',
    Icons.space_dashboard_outlined,
    Icons.space_dashboard,
  ),
  _Destination(
    AppRoutes.applications,
    'Candidaturas',
    Icons.work_outline,
    Icons.work,
  ),
  _Destination(
    AppRoutes.followUps,
    'Acompanhamentos',
    Icons.notifications_none,
    Icons.notifications,
  ),
  _Destination(
    AppRoutes.settings,
    'Configurações',
    Icons.settings_outlined,
    Icons.settings,
  ),
];

/// Estrutura comum das páginas principais: navegação lateral + título +
/// conteúdo.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.child,
  });

  final String currentRoute;
  final String title;
  final Widget child;

  void _navigate(int index) {
    final route = _destinations[index].route;
    if (route != currentRoute) {
      Get.offNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _destinations.indexWhere(
      (d) => d.route == currentRoute,
    );
    final extended =
        MediaQuery.sizeOf(context).width >= AppSizes.extendedNavBreakpoint;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            selectedIndex: selectedIndex,
            onDestinationSelected: _navigate,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
