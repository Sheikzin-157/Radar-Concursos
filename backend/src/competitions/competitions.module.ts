import { Module } from '@nestjs/common';
import { COMPETITION_REPOSITORY } from './application/ports/competition.repository';
import { GetCompetitionUseCase } from './application/use-cases/get-competition.use-case';
import { ListCompetitionsUseCase } from './application/use-cases/list-competitions.use-case';
import { PostgresCompetitionRepository } from './infrastructure/persistence/postgres-competition.repository';
import { CompetitionsController } from './presentation/competitions.controller';

@Module({
  controllers: [CompetitionsController],
  providers: [
    GetCompetitionUseCase,
    ListCompetitionsUseCase,
    {
      provide: COMPETITION_REPOSITORY,
      useClass: PostgresCompetitionRepository,
    },
  ],
})
export class CompetitionsModule {}
