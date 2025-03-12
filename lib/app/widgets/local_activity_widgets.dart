import 'package:app_usage/app_usage.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';

import '../models/local_activity_models.dart';

class AppSelectionBottomSheet extends StatefulWidget {
  final List<AppInfo> allApps;
  final Set<String> selectedApps;
  final Function(Set<String>) onSelectionChanged;

  const AppSelectionBottomSheet({
    super.key,
    required this.allApps,
    required this.selectedApps,
    required this.onSelectionChanged,
  });

  @override
  State<AppSelectionBottomSheet> createState() =>
      _AppSelectionBottomSheetState();
}

class _AppSelectionBottomSheetState extends State<AppSelectionBottomSheet> {
  late Set<String> _selected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedApps);
  }

  List<AppInfo> get _filteredApps {
    if (_searchQuery.isEmpty) {
      return widget.allApps;
    }

    return widget.allApps
        .where((app) =>
            (app.name.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              children: [
                const Text(
                  'Select Apps to Track',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SearchBar(
              hintText: 'Search apps...',
              leading: const Icon(Icons.search),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: _filteredApps.length,
              itemBuilder: (context, index) {
                final app = _filteredApps[index];
                final isSelected = _selected.contains(app.packageName);

                return ListTile(
                  leading: app.icon != null
                      ? Image.memory(app.icon!, width: 40, height: 40)
                      : Container(
                          width: 40,
                          height: 40,
                          color: colorScheme.surfaceContainerHighest,
                          child:
                              Icon(Icons.android, color: colorScheme.primary),
                        ),
                  title: Text(
                    app.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    app.packageName,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(app.packageName);
                        } else {
                          _selected.remove(app.packageName);
                        }
                      });
                      widget.onSelectionChanged(_selected);
                    },
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(app.packageName);
                      } else {
                        _selected.add(app.packageName);
                      }
                    });
                    widget.onSelectionChanged(_selected);
                  },
                );
              },
            ),
          ),
          // Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppUsageListView extends StatelessWidget {
  final List<AppUsageInfo> appUsageList;
  final Map<String, AppInfo?> appInfoCache;
  final Map<String, String> appCategories;
  final Future<AppInfo?> Function(String) getAppInfo;
  final List<AppInfo> allApps;
  final Function(AppUsageInfo) onAppTap;

  const AppUsageListView({
    super.key,
    required this.appUsageList,
    required this.appInfoCache,
    required this.appCategories,
    required this.getAppInfo,
    required this.onAppTap,
    required this.allApps,
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
      shrinkWrap: true,
      physics: const ScrollPhysics(),
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
                getBetterAppName(String packageName) {
                  var actual = allApps.where((app) =>
                      app.packageName == appsInCategory[appIndex].packageName);

                  if (actual.isEmpty) {
                    return "N/A";
                  }

                  return actual.first.name;
                }

                return AppUsageCard(
                  actualAppName:
                      getBetterAppName(appsInCategory[appIndex].packageName),
                  appInfo: appsInCategory[appIndex],
                  getAppInfo: getAppInfo,
                  onTap: () => onAppTap(appsInCategory[appIndex]),
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
  final String actualAppName;
  final Future<AppInfo?> Function(String) getAppInfo;
  final VoidCallback onTap;

  const AppUsageCard(
      {super.key,
      required this.appInfo,
      required this.getAppInfo,
      required this.onTap,
      required this.actualAppName});

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: AppIconWidget(
            packageName: appInfo.packageName,
            getAppInfo: getAppInfo,
          ),
          title: Text(
            actualAppName,
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppDetailsSheet extends StatelessWidget {
  final AppUsageInfo appUsageInfo;
  final AppInfo? appInfo;
  final String category;
  final List<AppInfo> allApps;

  const AppDetailsSheet({
    super.key,
    required this.appUsageInfo,
    required this.appInfo,
    required this.category,
    required this.allApps,
  });

  getBetterAppName(String packageName) {
    var actual = allApps
        .where((app) => app.packageName == (appInfo?.packageName ?? "..."));

    if (actual.isEmpty) {
      return "N/A";
    }

    return actual.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final duration = appUsageInfo.usage;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    String durationText = '';
    if (hours > 0) {
      durationText = '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    } else if (minutes > 0) {
      durationText = '$minutes min ${seconds > 0 ? '$seconds sec' : ''}';
    } else {
      durationText = '${duration.inSeconds} sec';
    }

    final startTime = appUsageInfo.startDate;
    final endTime = appUsageInfo.endDate;
    final formattedStartTime =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final formattedEndTime =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App header
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: appInfo?.icon != null
                          ? Image.memory(appInfo!.icon!)
                          : Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.android,
                                size: 36,
                                color: colorScheme.primary,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getBetterAppName(appInfo?.packageName ?? "..."),
                            style: Theme.of(context).textTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category, colorScheme)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getCategoryColor(category, colorScheme),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Text(
                            'Usage Statistics',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          'Total Usage Time',
                          durationText,
                          Icons.timer_outlined,
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          context,
                          'Started Using',
                          formattedStartTime,
                          Icons.play_circle_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          'Last Used',
                          formattedEndTime,
                          Icons.stop_circle_outlined,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Text(
                            'App Details',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          'Package Name',
                          appUsageInfo.packageName,
                          Icons.info_outline,
                        ),
                        if (appInfo?.versionName != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            'Version',
                            appInfo!.versionName,
                            Icons.new_releases_outlined,
                          ),
                        ],
                        if (appInfo?.installedTimestamp != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            'Installed On',
                            _formatDate(DateTime.fromMillisecondsSinceEpoch(
                                appInfo!.installedTimestamp)),
                            Icons.event_outlined,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Center(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Open App Settings'),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category, ColorScheme colorScheme) {
    switch (category) {
      case 'Social':
        return Colors.blue;
      case 'Games':
        return Colors.green;
      case 'Productivity':
        return Colors.purple;
      case 'Media':
        return Colors.red;
      default:
        return colorScheme.primary;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
