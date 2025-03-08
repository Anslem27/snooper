import 'package:flutter/material.dart';

Widget buildErrorCard(String message, BuildContext context) {
  return Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildLoadingCard(String message, BuildContext context) {
  return Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Text(message),
        ],
      ),
    ),
  );
}
