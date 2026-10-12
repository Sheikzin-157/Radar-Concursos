import 'competition.dart';

abstract interface class CompetitionRepository {
  Future<List<CompetitionSummary>> list({
    int limit = 20,
    String? search,
    String? state,
    String? status,
    String? organizationId,
    String? examBoardId,
  });

  Future<CompetitionDetail> getById(String competitionId);
}
