import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/competition_remote_data_source.dart';
import '../data/competition_repository_impl.dart';
import '../domain/competition.dart';
import '../domain/competition_repository.dart';

class CompetitionFilters {
  const CompetitionFilters({
    this.state,
    this.status,
    this.organizationId,
    this.examBoardId,
  });

  final String? state;
  final String? status;
  final String? organizationId;
  final String? examBoardId;

  @override
  bool operator ==(Object other) =>
      other is CompetitionFilters &&
      state == other.state &&
      status == other.status &&
      organizationId == other.organizationId &&
      examBoardId == other.examBoardId;

  @override
  int get hashCode => Object.hash(state, status, organizationId, examBoardId);
}

final competitionFiltersProvider = StateProvider<CompetitionFilters>(
  (ref) => const CompetitionFilters(),
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final competitionRemoteDataSourceProvider =
    Provider<CompetitionRemoteDataSource>(
  (ref) => CompetitionRemoteDataSource(ref.watch(apiClientProvider)),
);

final competitionRepositoryProvider = Provider<CompetitionRepository>(
  (ref) => CompetitionRepositoryImpl(
    ref.watch(competitionRemoteDataSourceProvider),
  ),
);

final competitionListProvider =
    FutureProvider.autoDispose<List<CompetitionSummary>>((ref) {
  final filters = ref.watch(competitionFiltersProvider);
  return ref.watch(competitionRepositoryProvider).list(
        state: filters.state,
        status: filters.status,
        organizationId: filters.organizationId,
        examBoardId: filters.examBoardId,
      );
});

final competitionDetailProvider =
    FutureProvider.autoDispose.family<CompetitionDetail, String>(
  (ref, competitionId) =>
      ref.watch(competitionRepositoryProvider).getById(competitionId),
);
