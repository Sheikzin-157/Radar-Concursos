import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../domain/competition.dart';
import 'competition_dto.dart';

class CompetitionRemoteDataSource {
  const CompetitionRemoteDataSource(this._client);
  final ApiClient _client;

  Future<List<CompetitionSummary>> list({int limit = 20, String? state, String? status}) async {
    final response = await _client.getMap(
      '/competitions',
      queryParameters: {
        'limit': limit,
        'state': ?state,
        'status': ?status,
      },
    );
    final rawItems = response['items'];
    if (rawItems is! List) {
      throw const AppException(
        code: 'INVALID_RESPONSE',
        message: 'A lista de concursos recebida é inválida.',
      );
    }
    return rawItems
        .map((item) => competitionSummaryFromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  Future<CompetitionDetail> getById(String competitionId) async {
    final response = await _client.getMap('/competitions/$competitionId');
    return competitionDetailFromJson(response);
  }
}
