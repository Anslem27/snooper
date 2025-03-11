import 'package:app_usage/app_usage.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final String message;

  const EmptyStateView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.android,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppUsageListView extends StatelessWidget {
  final List<AppUsageInfo> appUsageList;
  final Map<String, AppInfo?> appInfoCache;
  final Map<String, String> appCategories;
  final Future<AppInfo?> Function(String) getAppInfo;

  const AppUsageListView({
    super.key,
    required this.appUsageList,
    required this.appInfoCache,
    required this.appCategories,
    required this.getAppInfo,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, List<AppUsageInfo>> groupedApps = {};

    for (final app in appUsageList) {
      final category = appCategories[app.packageName] ?? 'Other';
      if (!groupedApps.containsKey(category)) {
        groupedApps[category] = [];
      }
      groupedApps[category]!.add(app);
    }

    final preferredOrder = [
      'Productivity',
      'Social',
      'Media',
      'Games',
      'Other'
    ];
    final sortedCategories = groupedApps.keys.toList()
      ..sort((a, b) {
        final indexA = preferredOrder.indexOf(a);
        final indexB = preferredOrder.indexOf(b);
        return (indexA != -1 ? indexA : 999) - (indexB != -1 ? indexB : 999);
      });

    if (sortedCategories.isEmpty) {
      return EmptyStateView(message: 'No app usage data available');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final appsInCategory = groupedApps[category]!;

        if (appsInCategory.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CategoryHeader(category: category),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: appsInCategory.length,
              itemBuilder: (context, appIndex) {
                return AppUsageCard(
                  appInfo: appsInCategory[appIndex],
                  getAppInfo: getAppInfo,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class AppUsageCard extends StatelessWidget {
  final AppUsageInfo appInfo;
  final Future<AppInfo?> Function(String) getAppInfo;

  const AppUsageCard({
    super.key,
    required this.appInfo,
    required this.getAppInfo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final duration = appInfo.usage;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final durationText = minutes > 0
        ? '$minutes min ${seconds > 0 ? '$seconds sec' : ''}'
        : '${duration.inSeconds} sec';

    final timeAgo = DateTime.now().difference(appInfo.endDate);
    final timeAgoText =
        timeAgo.inMinutes < 1 ? 'just now' : '${timeAgo.inMinutes} min ago';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: colorScheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: AppIconWidget(
          packageName: appInfo.packageName,
          getAppInfo: getAppInfo,
        ),
        title: Text(
          appInfo.appName,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Used for $durationText',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            timeAgoText,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryHeader extends StatelessWidget {
  final String category;

  const CategoryHeader({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData getCategoryIcon() {
      switch (category) {
        case 'Productivity':
          return Icons.work_rounded;
        case 'Social':
          return Icons.people_rounded;
        case 'Media':
          return Icons.movie_rounded;
        case 'Games':
          return Icons.sports_esports_rounded;
        default:
          return Icons.apps_rounded;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(
            getCategoryIcon(),
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            category,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class AppIconWidget extends StatelessWidget {
  final String packageName;
  final Future<AppInfo?> Function(String) getAppInfo;

  const AppIconWidget({
    super.key,
    required this.packageName,
    required this.getAppInfo,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppInfo?>(
      future: getAppInfo(packageName),
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.icon != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Image.memory(
                snapshot.data!.icon!,
                fit: BoxFit.cover,
              ),
            ),
          );
        }

        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.android_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}
