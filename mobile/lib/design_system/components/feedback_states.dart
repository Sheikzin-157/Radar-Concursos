import 'package:flutter/material.dart';

class RadarErrorState extends StatelessWidget {
  const RadarErrorState({required this.message, required this.onRetry, super.key});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 96),
          Icon(Icons.cloud_off_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('Não foi possível carregar', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Center(child: FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente'))),
        ],
      ),
    );
  }
}

class RadarEmptyState extends StatelessWidget {
  const RadarEmptyState({required this.title, required this.message, super.key});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 96),
        const Icon(Icons.search_off_outlined, size: 48),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
