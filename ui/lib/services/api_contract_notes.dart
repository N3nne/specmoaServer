// This file intentionally contains lightweight API contract notes rather than
// a concrete HTTP implementation. Add an HTTP client after the Nest DTOs settle.
//
// Expected Nest resources:
// - GET /certifications
// - GET /certifications/:id
// - GET /study-tasks/today
// - PATCH /study-tasks/:id/complete
// - GET /study-sessions/today
// - POST /study-sessions
//
// Flutter screens should eventually call repository classes, not ApiPaths
// directly. Keep the current mock data isolated until the server is ready.
