import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radar_concursos/features/competitions/application/competition_providers.dart';

void main() {
  test('applies and clears server-side catalog filters', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(competitionFiltersProvider).state, isNull);

    container.read(competitionFiltersProvider.notifier).apply(
          const CompetitionFilters(
            state: 'PI',
            status: 'inscricoes_abertas',
          ),
        );

    final applied = container.read(competitionFiltersProvider);
    expect(applied.state, 'PI');
    expect(applied.status, 'inscricoes_abertas');

    container.read(competitionFiltersProvider.notifier).apply(
          const CompetitionFilters(),
        );

    final cleared = container.read(competitionFiltersProvider);
    expect(cleared.state, isNull);
    expect(cleared.status, isNull);
  });

  test('filter value equality permits stable provider dependencies', () {
    expect(
      const CompetitionFilters(state: 'PI', status: 'edital_publicado'),
      const CompetitionFilters(state: 'PI', status: 'edital_publicado'),
    );
  });
}
