import 'package:flutter/material.dart';

class SnooperM3Bar extends StatelessWidget {
  final List<NavItemWidget> navItems;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final IconData fabIcon;
  final VoidCallback onFabPressed;

  const SnooperM3Bar({
    super.key,
    required this.navItems,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.fabIcon,
    required this.onFabPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(
              navItems.length,
              (index) => M3NavItem(
                icon: index == selectedIndex
                    ? navItems[index].selectedIcon
                    : navItems[index].icon,
                label: navItems[index].label,
                isSelected: selectedIndex == index,
                onTap: () => onItemSelected(index),
                colorScheme: colorScheme,
                customWidget: navItems[index].customWidget,
                isUsingCustomWidget: navItems[index].customWidget != null,
              ),
            ),
          ),

          // Floating action button
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: onFabPressed,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              elevation: 2,
              child: Icon(fabIcon),
            ),
          ),
        ],
      ),
    );
  }
}

class M3NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final Widget? customWidget;
  final bool isUsingCustomWidget;

  const M3NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    this.customWidget,
    this.isUsingCustomWidget = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 16 : 12,
                  vertical: isSelected ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.secondaryContainer.withValues(alpha: 0.4)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: isUsingCustomWidget
                    ? customWidget
                    : Icon(
                        icon,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItemWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget? customWidget;

  NavItemWidget({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.customWidget,
  });
}
