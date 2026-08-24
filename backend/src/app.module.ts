import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { CompetitionsModule } from './competitions/competitions.module';
import { HealthController } from './health/health.controller';
import { DatabaseModule } from './shared/infrastructure/database/database.module';
import { CorrelationIdMiddleware } from './shared/presentation/correlation-id.middleware';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DatabaseModule,
    CompetitionsModule,
  ],
  controllers: [HealthController],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(CorrelationIdMiddleware).forRoutes('*');
  }
}
