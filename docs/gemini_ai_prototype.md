# Gemini AI prototype

Updated: 2026-10-26 (Asia/Seoul)

## Scope

This is a developer-only AI demo connected to the Flutter exploration tab.
The user explicitly opens `AI 추천 시연`; merely opening exploration or refreshing
the normal feed never starts generation. Real user profiles, the existing rules-v2
comparison, PostgreSQL schema, Render and APKs are unchanged.

- Three authored fictional profiles: `backend`, `mobile`, `data`.
- The Flutter demo currently uses the clearly labeled backend fixture only. No profile-selection screen was invented without a Stitch source; CLI still supports all three fixtures.
- Nine currently open representative fictional postings from `DemoJobSource`.
- Up to three AI-ordered recommendations, with exact spec/job quotes and short Korean explanations.
- Each recommendation also includes the existing server-generated rules-v2 comparison.
- No pass probability, population percentile, official verification, AI eligibility decision or fabricated score.
- No repositories or user-data services are injected into the AI module. The authenticated caller ID is used only for local request limits and is never sent to Google.
- The HTTP body accepts only a fixed profile enum. It cannot accept user IDs, profile text, job text, arbitrary prompts or provider URLs. Query parameters are rejected.

## Configuration

Add the key to `C:\app_project\server\.env`, never to Flutter or Git:

```dotenv
GEMINI_API_KEY=your_private_key
GEMINI_MODEL=gemini-3.5-flash-lite
AI_DEMO_ENABLED=false
```

The model defaults to `gemini-3.5-flash-lite` without an env override.
`gemini-3.1-flash-lite` and `gemini-3.8-flash` are explicitly selectable alternatives,
not automatic fallbacks. Flash-Lite uses MINIMAL thinking; 3.8 Flash uses LOW.
The Gemini key and model list were checked without printing the key.
Model listing does not prove generation quota, free-tier eligibility or model capacity.
Google documents free input/output tiers for these models, but the project's actual
billing status and quotas must be checked in AI Studio. The code cannot guarantee
zero charges for an already billed project.

### Local CLI

Run from the server directory:

```powershell
cd C:\app_project\server
npm run ai:demo -- backend
```

Replace `backend` with `mobile` or `data` to select another fictional profile.
One invocation makes at most one generation request. It does not start Nest,
connect to PostgreSQL, register users or seed data. It reads the server .env
and explicitly opts into the local demo for that process only. It refuses production mode.
Do not run this command in a loop; its in-memory limits reset on each invocation.

### Optional Local HTTP Test

The endpoint stays off when `AI_DEMO_ENABLED` is absent or false. To test it locally,
set it to `true` and restart the development server. Production mode always refuses it,
even if this flag and the key are present. No production AI rollout is implemented.
The ignored local `.env` was enabled for this synthetic demo; the committed example
remains off by default. The private key was not changed or printed.

Authenticated `GET /ai/demo/status` reports availability and the fixture label, never
the key. Older, offline or disabled servers keep the ordinary job feed usable.

```http
POST /ai/demo/recommendations
Authorization: Bearer <access token>
Content-Type: application/json

{"profile":"backend"}
```

The existing global auth guard validates the access token and active refresh session.
Responses carry `Cache-Control: no-store`. All generated content is explicitly marked
`synthetic: true`, with `method: gemini-demo-v1` and a developer-demo notice.
Posting identifiers remain fixture external IDs. The app resolves them through
authenticated `GET /jobs/demo/:externalId`, verifies source/synthetic identity, then
opens the existing job-detail screen with the actual local DB UUID. The resolver
only serves synthetic `demo` rows in demo-source mode. Missing rows are reported;
no fake detail is manufactured and no data is seeded automatically.

## Flutter Behavior

- Reuses the original Stitch quick-chip, blue summary and 290px carousel layout.
- Displays the fictional profile, real generation time in KST, recommendation count,
  AI explanation, spec/job quotes and cautions returned by the server.
- The original fake matching percentages, applicant percentiles, upgrade claims,
  detailed filters and bookmarks remain absent. The four-tab navigation is unchanged.
- Empty results are real empty states, not filled with hard-coded recommendations.
- Loading disables repeated calls. Refresh retains the last result; errors do not
  clear successful cards or their original timestamp. Cached results are labeled.
- Account/client/auth-generation changes invalidate pending responses and actions.
- Evidence whitespace is normalized only for display; long-press/hover tooltips
  retain the original quotes. Job detail still uses the existing user-specific
  rules comparison, not the fictional profile and not AI probabilities.
- Only exploration and its new local component were visually changed. No new
  detail screen, popup, theme or global navigation design was invented.

## Reliability And Safety

- Native server-side REST `generateContent`, matching the project's existing fetch pattern; no SDK dependency or client-side key.
- Fixed Google endpoint, API key in header, redirects refused, 45-second request/body timeout.
- Only compact condition/status summaries are sent alongside the fictional evidence; full rules-v2 explanations remain on the server.
- Input JSON capped at 32 KB, response at 64 KB, output generation at 4,096 tokens.
- JSON Schema output plus independent validation: reject unexpected fields, duplicates, unknown job/spec IDs, invented quotes, empty reasons and percentage/probability claims.
- Each reason must quote an existing field on both the supplied spec and the chosen job. This checks evidence existence, not the truth of the model's interpretation; explanations can still be wrong.
- Blocked, truncated, malformed and tool-call responses are errors, not partial recommendations.
- Normal `thoughtSignature` metadata is accepted but never displayed. Reasoning parts are excluded from final-text parsing, and signature-only parts do not invalidate valid JSON output.
- Degree/language-only overlap cannot create unrelated recommendations: a retained item must include project/activity skill, keyword or description evidence. Remaining items keep the AI order and are renumbered without filling empty slots.
- No automatic retries, paid-model substitution, search tools or fabricated fallback recommendations.
- Same-profile requests share in-flight work and a 15-minute cache, timed from completion. Cache copies cannot be mutated by callers.
- One external generation at a time; at most 10 attempted requests per KST day/process and three per caller/day/process. Failures count too. Upstream 429 adds a shared 60-second cooldown from receipt of the error, not the request start.
- These are local prototype safeguards, not durable billing/quota enforcement. They reset on restart and do not coordinate multiple replicas. Public deployment requires persistent shared limits and budget controls.
- Upstream response bodies, keys, prompts and real user records are not logged or forwarded by application code. Errors are sanitized into 429/502/503 responses.
- No database migration or changes to existing user records.

## Before Real User Analysis

Google's unpaid-service terms prohibit submitting sensitive, confidential or personal
information and allow inputs/outputs to be used for improvement and reviewed by people.
Removing names alone does not turn a real education/employment profile into safe synthetic data.
Do not connect the unpaid demo to the user's actual specs.

Before enabling actual personalized analysis, resolve provider/data-use terms,
appropriate billing/service settings, privacy notice and consent, data minimization,
retention, deletion and audience restrictions. Google's terms prohibit API clients
directed toward or likely accessed by under-18s. Do not assume a nominal age checkbox
alone resolves that restriction.

No real-user AI route, document upload, OCR, vector DB, model training, auto-application
or pass-probability prediction is implemented by this change.

## Verification

- `npm run build`.
- `npm test`: includes isolated transport, output, cache, quota, authentication and payload tests; no Google calls.
- `$env:RUN_DB_TESTS='true'; npm test`: also runs existing tests against randomly named scratch local PostgreSQL databases and drops those scratch databases afterward.
- Live generation is an explicit CLI/browser check, not part of automated tests.

2026-10-26 results:

- Nest build and 56 server tests passed, including both isolated PostgreSQL suites.
- Flutter 107 tests passed, including 14 new AI model/API/widget tests. Static analysis passed.
- Earlier models/calls encountered Google 503 and timeouts. A 3.1 Flash-Lite CLI call succeeded, but subsequent browser calls were intermittent. No automatic retries or paid fallback were added.
- The currently selected 3.5 Flash-Lite model was verified in CLI and in the actual Flutter app through Nest. The real HTTP response was 200 and retained one backend recommendation with quoted project evidence, without padding the result to three.
- The actual card opened the correct demo DB posting and existing detail comparison. A browser refresh of the AI result returned cached=true with the same generation timestamp.
- Captured actual Flutter rendering at 320/390/1280px; widget tests also cover larger text and dark mode. Final capture names are recorded in `.stitch/designs/ai-explore-analysis.md`.
- The real 503 UI was also exercised: no fake recommendation cards were displayed and ordinary job browsing stayed available.
- Final actual-app captures include dark mode and the corrected action gradient/quote layout. No JavaScript page errors occurred; a QA login re-entry produced one expected 401 resource log.
- Both temporary QA accounts and their authentication sessions were removed after checking that they had no specs or study sessions. Existing user data was not deleted.
- Web release build passed with the pre-existing CupertinoIcons font-lookup warning; this screen uses verified Material icons. Android/iOS native builds were not run for this increment.
- No Render/Supabase/APK deployment occurred. A passing test suite does not remove future quota/capacity risks or authorize transmitting actual user data.

## Files In This Increment

- Server: `src/ai/gemini.client.ts`, `ai-demo.service.ts`, `ai-demo.controller.ts`, `demo-recommendation-data.ts`.
- Job resolution: `src/jobs/jobs.controller.ts`, `jobs.service.ts`.
- Configuration: `.env.example`; only the synthetic-demo flag was added to the ignored local `.env`.
- Server tests: `test/ai.test.ts`, `test/postgres-jobs.test.ts`.
- Flutter: `lib/screens/explore_screen.dart`, `lib/services/job_api_client.dart`.
- New Flutter components/models: `lib/widgets/job_ai_demo_section.dart`, `lib/models/ai_demo_data.dart`.
- Flutter tests: `test/job_ai_demo_test.dart`, `test/fixtures/ai_demo_fixture.dart`, `test/job_explore_test.dart`.
- Documentation: this file, `job_data_implementation.md`, `.stitch/designs/ai-explore-analysis.md` and the referenced original/verification captures.

Reused components: existing exploration header/search/chip style, `ResponsivePage`,
`AuthenticatedClient`, `JobComparison`, `JobDetailScreen`, `compareJob`, and `DemoJobSource`.
New UI components are `JobAiDemoSection` and its private `_RecommendationCard`;
no unrelated screens, global themes or business modules were redesigned.

Local preview: `http://127.0.0.1:8111` with the separate local API on port `3112`.
Log in with an existing local account, open exploration, then select `AI 추천 시연`.

## User Data Preparation Follow-Up (2026-10-26)

The separate `CareerModule` now stores desired occupations and prepares the current
user's eight spec types for server-internal analysis. See
`career_analysis_preparation.md` for the authenticated API and data contract.
It does not import or call the Gemini demo service. Actual user profiles still do
not enter the demo prompt, and editing real specs does not personalize its result.
The preference UI is deferred until the user supplies the Stitch source; real-user
external AI transmission remains disabled pending a separate data-handling decision.

The server suite now has 62 passing tests, including three isolated PostgreSQL
suites. No Flutter, cloud deployment or APK changes were made in this follow-up.

## Official References

- [API key setup](https://ai.google.dev/gemini-api/docs/api-key)
- [REST generateContent reference](https://ai.google.dev/api/generate-content)
- [Structured output](https://ai.google.dev/gemini-api/docs/structured-output)
- [Pricing and free-tier distinctions](https://ai.google.dev/gemini-api/docs/pricing)
- [Project rate limits](https://ai.google.dev/gemini-api/docs/rate-limits)
- [Terms: unpaid data use and age restrictions](https://ai.google.dev/gemini-api/terms)
- [Model availability/deprecation notes](https://ai.google.dev/gemini-api/docs/deprecations)
