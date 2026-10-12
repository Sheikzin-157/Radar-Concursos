import 'competition.dart';

abstract interface class CompetitionRepository {
  Future<List<CompetitionSummary>> list({int limit = 20, String? state, String? status});
  Future<CompetitionDetail> getById(String competitionId);
}
