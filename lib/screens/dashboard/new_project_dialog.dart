import 'package:flutter/material.dart';

Future<String?> showNewProjectDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New project'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Project name'),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Create'),
        ),
      ],
    ),
  );
}
