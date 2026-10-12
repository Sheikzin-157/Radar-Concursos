import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/competition_remote_data_source.dart';
import '../data/competition_repository_impl.dart';
import '../domain/competition.dart';
import '../domain/competition_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final competitionRemoteDataSourceProvider = Provider<CompetitionRemoteDataSource>((ref) => CompetitionRemoteDataSource(ref.watch(apiClientProvider)));
final competitionRepositoryProvider = Provider<CompetitionRepository>((ref) => CompetitionRepositoryImpl(ref.watch(competitionRemoteDataSourceProvider)));
final competitionListProvider = FutureProvider.autoDispose<List<CompetitionSummary>>((ref) => ref.watch(competitionRepositoryProvider).list());
final competitionDetailProvider = FutureProvider.autoDispose.family<CompetitionDetail, String>((ref, competitionId) => ref.watch(competitionRepositoryProvider).getById(competitionId));
