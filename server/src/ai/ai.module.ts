import { Module } from '@nestjs/common';
import { AiDemoController } from './ai-demo.controller';
import { AiDemoService, RECOMMENDATION_PROVIDER } from './ai-demo.service';
import { GeminiClient } from './gemini.client';

@Module({
  controllers: [AiDemoController],
  providers: [
    AiDemoService,
    { provide: RECOMMENDATION_PROVIDER, useFactory: () => new GeminiClient() },
  ],
})
export class AiModule {}
