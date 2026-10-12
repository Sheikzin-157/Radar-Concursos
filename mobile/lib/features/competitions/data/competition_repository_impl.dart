import '../domain/competition.dart';
import '../domain/competition_repository.dart';
import 'competition_remote_data_source.dart';

class CompetitionRepositoryImpl implements CompetitionRepository {
  const CompetitionRepositoryImpl(this._remote);
  final CompetitionRemoteDataSource _remote;

  @override
  Future<CompetitionDetail> getById(String competitionId) => _remote.getById(competitionId);

  @override
  Future<List<CompetitionSummary>> list({int limit = 20, String? state, String? status}) => _remote.list(limit: limit, state: state, status: status);
}
