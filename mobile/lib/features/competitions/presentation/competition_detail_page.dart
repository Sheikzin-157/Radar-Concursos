import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../design_system/components/feedback_states.dart';
import '../application/competition_providers.dart';
import '../domain/competition.dart';

class CompetitionDetailPage extends ConsumerWidget {
  const CompetitionDetailPage({required this.competitionId, super.key});
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(competitionDetailProvider(competitionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do concurso')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => RadarErrorState(
            message: error is AppException ? error.message : 'Ocorreu um erro inesperado.',
            onRetry: () => ref.invalidate(competitionDetailProvider(competitionId)),
          ),
          data: (competition) => _DetailContent(
            competition: competition,
            onRefresh: () async {
              await ref.refresh(competitionDetailProvider(competitionId).future);
            },
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.competition, required this.onRefresh});
  final CompetitionDetail competition;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            competition.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            competition.organization.officialName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(_humanize(competition.currentStatus))),
              if (competition.organization.state != null)
                Chip(label: Text(competition.organization.state!)),
              if (competition.competitionType != null)
                Chip(label: Text(_humanize(competition.competitionType!))),
            ],
          ),
          if (competition.summary?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 24),
            _Section(title: 'Resumo', child: Text(competition.summary!)),
          ],
          const SizedBox(height: 24),
          _Section(
            title: 'Informações principais',
            child: Column(
              children: [
                _InfoRow(label: 'Vagas', value: competition.totalVacancies?.toString() ?? 'Não informado'),
                _InfoRow(label: 'Remuneração', value: _moneyRange(competition.salary, money)),
                _InfoRow(label: 'Banca', value: competition.examBoard?.officialName ?? 'Não informada'),
                _InfoRow(label: 'Carreira', value: competition.career?.name ?? 'Não informada'),
                _InfoRow(label: 'Taxa de inscrição', value: _moneyRange(competition.registrationFee, money)),
                _InfoRow(
                  label: 'Esfera',
                  value: competition.governmentSphere == null
                      ? 'Não informada'
                      : _humanize(competition.governmentSphere!),
                ),
              ],
            ),
          ),
          if (competition.lastOfficialUpdateAt != null || competition.lastValidatedAt != null) ...[
            const SizedBox(height: 24),
            _Section(
              title: 'Atualização dos dados',
              child: Column(
                children: [
                  if (competition.lastOfficialUpdateAt != null)
                    _InfoRow(
                      label: 'Atualização oficial',
                      value: DateFormat('dd/MM/yyyy HH:mm').format(competition.lastOfficialUpdateAt!.toLocal()),
                    ),
                  if (competition.lastValidatedAt != null)
                    _InfoRow(
                      label: 'Última validação',
                      value: DateFormat('dd/MM/yyyy HH:mm').format(competition.lastValidatedAt!.toLocal()),
                    ),
                ],
              ),
            ),
          ],
          if (competition.officialUrl?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 24),
            _Section(title: 'Fonte oficial', child: SelectableText(competition.officialUrl!)),
          ],
        ],
      ),
    );
  }

  String _moneyRange(MoneyRange range, NumberFormat formatter) {
    if (range.min == null && range.max == null) return 'Não informado';
    if (range.min != null && range.max != null && range.min != range.max) {
      return '${formatter.format(range.min)} – ${formatter.format(range.max)}';
    }
    return formatter.format(range.max ?? range.min);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String _humanize(String value) {
  final normalized = value.replaceAll('_', ' ').trim().toLowerCase();
  if (normalized.isEmpty) return value;
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}
