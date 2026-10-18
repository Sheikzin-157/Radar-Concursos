import type { MiddlewareConsumer } from '@nestjs/common';
import { AppModule } from './app.module';
import { CorrelationIdMiddleware } from './shared/presentation/correlation-id.middleware';

describe('AppModule middleware configuration', () => {
  it('uses a named wildcard compatible with NestJS 11', () => {
    const forRoutes = jest.fn();
    const apply = jest.fn().mockReturnValue({ forRoutes });
    const consumer = { apply } as unknown as MiddlewareConsumer;

    new AppModule().configure(consumer);

    expect(apply).toHaveBeenCalledWith(CorrelationIdMiddleware);
    expect(forRoutes).toHaveBeenCalledWith('{*path}');
  });
});
