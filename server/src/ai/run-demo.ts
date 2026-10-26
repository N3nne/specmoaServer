import 'reflect-metadata';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { ConfigService } from '@nestjs/config';
import { HttpException } from '@nestjs/common';
import { parse } from 'dotenv';
import { AiDemoService } from './ai-demo.service';
import { DemoProfile } from './demo-recommendation-data';
import { GeminiClient } from './gemini.client';

async function run() {
  const profile = process.argv[2] ?? DemoProfile.BACKEND;
  if (
    !Object.values(DemoProfile).includes(profile as DemoProfile) ||
    process.argv.length > 3
  ) {
    throw new Error('Usage: npm run ai:demo -- backend|mobile|data');
  }
  const env = parse(readFileSync(resolve(__dirname, '../../.env')));
  const config = new ConfigService({
    ...env,
    ...process.env,
    AI_DEMO_ENABLED: 'true',
  });
  const ai = new AiDemoService(config, new GeminiClient());
  console.log(
    JSON.stringify(
      await ai.recommend(profile as DemoProfile, 'local-demo-cli'),
      null,
      2,
    ),
  );
}

void run().catch((error) => {
  // No stack trace, provider body, key, prompt or user record is logged.
  console.error(
    error instanceof HttpException
      ? error.message
      : 'AI demo failed. Check the command and server configuration.',
  );
  process.exitCode = 1;
});
