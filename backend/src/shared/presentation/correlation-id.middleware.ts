import { Injectable, NestMiddleware } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

@Injectable()
export class CorrelationIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction): void {
    const supplied = req.header('x-correlation-id');
    const correlationId = supplied && UUID_PATTERN.test(supplied) ? supplied : randomUUID();

    res.setHeader('X-Correlation-Id', correlationId);
    res.locals.correlationId = correlationId;
    next();
  }
}
