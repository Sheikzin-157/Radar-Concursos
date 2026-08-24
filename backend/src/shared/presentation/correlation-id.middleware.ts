import { Injectable, NestMiddleware } from '@nestjs/common';
import { randomUUID, validate as validateUuid } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';

@Injectable()
export class CorrelationIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction): void {
    const supplied = req.header('x-correlation-id');
    const correlationId = supplied && validateUuid(supplied) ? supplied : randomUUID();

    res.setHeader('X-Correlation-Id', correlationId);
    res.locals.correlationId = correlationId;
    next();
  }
}
