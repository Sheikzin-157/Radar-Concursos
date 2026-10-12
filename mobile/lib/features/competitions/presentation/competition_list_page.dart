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
      appBar: AppBar(
        title: const Text('Concursos'),
        actions: [
          IconButton(
            tooltip: 'Minha conta',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _CatalogSearchBar(filters: ref.watch(competitionFiltersProvider)),
            _CatalogFiltersBar(filters: ref.watch(competitionFiltersProvider)),
            Expanded(child: competitions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => RadarErrorState(
            message: error is AppException ? error.message : 'Ocorreu um erro inesperado.',
            onRetry: () => ref.invalidate(competitionListProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return RadarEmptyState(
                title: 'Nenhum concurso encontrado',
                message: ref.watch(competitionFiltersProvider).search != null ||
                        ref.watch(competitionFiltersProvider).state != null ||
                        ref.watch(competitionFiltersProvider).status != null
                    ? 'Nenhum concurso corresponde aos filtros selecionados.'
                    : 'Assim que houver concursos disponíveis, eles aparecerão aqui.',
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(competitionListProvider);
                await ref.read(competitionListProvider.future);
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _CompetitionCard(competition: items[index]),
              ),
            );
          },
            )),
          ],
        ),
      ),
    );
  }
}

class _CatalogSearchBar extends ConsumerStatefulWidget {
  const _CatalogSearchBar({required this.filters});

  final CompetitionFilters filters;

  @override
  ConsumerState<_CatalogSearchBar> createState() => _CatalogSearchBarState();
}

class _CatalogSearchBarState extends ConsumerState<_CatalogSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.filters.search);
  }

  @override
  void didUpdateWidget(covariant _CatalogSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters.search != widget.filters.search &&
        _controller.text.trim() != (widget.filters.search ?? '')) {
      _controller.text = widget.filters.search ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final search = _controller.text.trim();
    if (search.isNotEmpty && search.length < 2) return;
    ref.read(competitionFiltersProvider.notifier).apply(
      CompetitionFilters(
        search: search.isEmpty ? null : search,
        state: widget.filters.state,
        status: widget.filters.status,
        organizationId: widget.filters.organizationId,
        examBoardId: widget.filters.examBoardId,
      ),
    );
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _controller,
        maxLength: 100,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'Pesquisar concursos',
          hintText: 'Título do concurso ou órgão',
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            tooltip: 'Pesquisar',
            onPressed: _submit,
            icon: const Icon(Icons.arrow_forward),
          ),
        ),
      ),
    );
  }
}

class _CatalogFiltersBar extends ConsumerWidget {
  const _CatalogFiltersBar({required this.filters});

  final CompetitionFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = filters.search != null || filters.state != null || filters.status != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showFilters(context, ref),
              icon: const Icon(Icons.tune),
              label: Text(active ? 'Filtros ativos' : 'Filtrar concursos'),
            ),
          ),
          if (active) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Limpar filtros',
              onPressed: () => ref
                  .read(competitionFiltersProvider.notifier)
                  .apply(const CompetitionFilters()),
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showFilters(BuildContext context, WidgetRef ref) async {
    String? state = filters.state;
    final statusController = TextEditingController(text: filters.status);
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(
              20, 12, 20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filtros do catálogo',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: state,
                    decoration: const InputDecoration(
                      labelText: 'UF do órgão',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Todas as UFs'),
                      ),
                      for (final uf in _ufs)
                        DropdownMenuItem(value: uf, child: Text(uf)),
                    ],
                    onChanged: (value) => setSheetState(() {
                      state = value == null || value.isEmpty ? null : value;
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: statusController,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(
                      labelText: 'Código da situação (opcional)',
                      hintText: 'Ex.: inscricoes_abertas',
                      helperText: 'Filtra pela situação exata publicada pela API.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      final status = statusController.text.trim();
                      ref.read(competitionFiltersProvider.notifier).apply(
                        CompetitionFilters(
                          search: filters.search,
                          state: state,
                          status: status.isEmpty ? null : status,
                        ),
                      );
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Aplicar filtros'),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(competitionFiltersProvider.notifier).apply(
                        const CompetitionFilters(),
                      );
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Limpar filtros'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      statusController.dispose();
    }
  }
}

const _ufs = [
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
  'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
  'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
];

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
