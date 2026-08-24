import { Module } from '@nestjs/common';
import { COMPETITION_REPOSITORY } from './application/ports/competition.repository';
import { ListCompetitionsUseCase } from './application/use-cases/list-competitions.use-case';
import { PostgresCompetitionRepository } from './infrastructure/persistence/postgres-competition.repository';
import { CompetitionsController } from './presentation/competitions.controller';

@Module({
  controllers: [CompetitionsController],
  providers: [
    ListCompetitionsUseCase,
    {
      provide: COMPETITION_REPOSITORY,
      useClass: PostgresCompetitionRepository,
    },
  ],
})
export class CompetitionsModule {}
