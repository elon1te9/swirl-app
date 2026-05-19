import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScreenPlaceholder extends StatelessWidget {
  const ScreenPlaceholder({
    required this.title,
    required this.description,
    this.routeInfo,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String description;
  final String? routeInfo;
  final List<PlaceholderAction> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Text(description, style: textTheme.bodyLarge),
                    if (routeInfo != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        routeInfo!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            for (final action in actions) ...[
              FilledButton(
                onPressed: () => context.go(action.route),
                child: Text(action.label),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class PlaceholderAction {
  const PlaceholderAction({required this.label, required this.route});

  final String label;
  final String route;
}
