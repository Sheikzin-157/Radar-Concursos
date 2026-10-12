import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../design_system/components/feedback_states.dart';
import '../application/competition_providers.dart';
import '../domain/competition.dart';

class CompetitionListPage extends ConsumerWidget {
  const CompetitionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(competitionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Concursos')),
      body: SafeArea(
        child: competitions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => RadarErrorState(
            message: error is AppException ? error.message : 'Ocorreu um erro inesperado.',
            onRetry: () => ref.invalidate(competitionListProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const RadarEmptyState(
                title: 'Nenhum concurso publicado',
                message: 'Assim que houver concursos disponíveis, eles aparecerão aqui.',
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                await ref.refresh(competitionListProvider.future);
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _CompetitionCard(competition: items[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  const _CompetitionCard({required this.competition});
  final CompetitionSummary competition;

  @override
  Widget build(BuildContext context) {
    final organization = competition.organization.acronym?.isNotEmpty == true
        ? competition.organization.acronym!
        : competition.organization.officialName;

    return Semantics(
      button: true,
      label: '${competition.title}, $organization',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/competitions/${competition.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        competition.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Chip(visualDensity: VisualDensity.compact, label: Text(_humanize(competition.currentStatus))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  organization,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _MetaItem(
                      icon: Icons.groups_2_outlined,
                      value: competition.totalVacancies == null
                          ? 'Vagas não informadas'
                          : '${competition.totalVacancies} vagas',
                    ),
                    _MetaItem(icon: Icons.payments_outlined, value: _formatMoneyRange(competition.salary)),
                    if (competition.organization.state != null)
                      _MetaItem(icon: Icons.location_on_outlined, value: competition.organization.state!),
                  ],
                ),
                if (competition.lastOfficialUpdateAt != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Atualizado em ${DateFormat('dd/MM/yyyy').format(competition.lastOfficialUpdateAt!.toLocal())}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(value)],
    );
  }
}

String _formatMoneyRange(MoneyRange range) {
  final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
  if (range.min == null && range.max == null) return 'Remuneração não informada';
  if (range.min != null && range.max != null && range.min != range.max) {
    return '${formatter.format(range.min)} – ${formatter.format(range.max)}';
  }
  return formatter.format(range.max ?? range.min);
}

String _humanize(String value) {
  final normalized = value.replaceAll('_', ' ').trim().toLowerCase();
  if (normalized.isEmpty) return value;
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}
