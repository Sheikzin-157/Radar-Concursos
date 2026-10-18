import '../domain/competition.dart';
import '../domain/competition_repository.dart';
import 'competition_remote_data_source.dart';

class CompetitionRepositoryImpl implements CompetitionRepository {
  const CompetitionRepositoryImpl(this._remote);
  final CompetitionRemoteDataSource _remote;

  @override
  Future<CompetitionDetail> getById(String competitionId) =>
      _remote.getById(competitionId);

  @override
  Future<List<CompetitionSummary>> list({
    int limit = 20,
    String? search,
    String? state,
    String? status,
    String? organizationId,
    String? examBoardId,
  }) =>
      _remote.list(
        limit: limit,
        search: search,
        state: state,
        status: status,
        organizationId: organizationId,
        examBoardId: examBoardId,
      );
}
