import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/session.dart';
import '../notifications/notification_event.dart';

/// App bar bell showing a badge for unread deadline notifications fired by
/// the watchdog while the app has been open, with a dropdown listing them.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final count = session.unreadNotificationCount;

    return PopupMenuButton<void>(
      tooltip: 'Notifications',
      offset: const Offset(0, 48),
      itemBuilder: (context) => [
        if (session.notifications.isEmpty)
          const PopupMenuItem(
            enabled: false,
            child: Text('No notifications yet'),
          )
        else ...[
          for (final event in session.notifications.take(20))
            PopupMenuItem(
              enabled: false,
              child: _NotificationTile(event: event),
            ),
          const PopupMenuDivider(),
          PopupMenuItem(
            child: const Text('Clear all'),
            onTap: () => context.read<Session>().clearNotifications(),
          ),
        ],
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: const Icon(Icons.notifications_outlined),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationEvent event;

  const _NotificationTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = event.type == NotificationEventType.overdue;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isOverdue ? Icons.error_outline : Icons.schedule_outlined,
            size: 18,
            color: isOverdue ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.taskTitle,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${event.projectName} — ${event.describeRelativeDue()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
