## Test environments

- local macOS Tahoe 26.6 (arm64), R 4.6.1

## R CMD check results

The local source tarball completed `R CMD check --as-cran` with:

0 errors | 0 warnings | 2 notes

The notes are expected for a new submission and for local HTML-manual
validation being skipped because the installed HTML Tidy is not recent enough.
No package HTML error was reported.

The check included package installation, examples, deterministic tests,
vignette rebuilding, and PDF-manual generation.

All six official endpoints were also tested against the live API:
indicator, region, term, social-event, statistical-survey, and data retrieval.
Live API tests are opt-in through
`DASHBOARDAPI_RUN_LIVE_TESTS=true`; ordinary checks use deterministic fixtures
and do not contact the Statistics Dashboard.

## Submission

This would be the first submission of `dashboardapi`. It is an unofficial
client for the Statistics Dashboard Web API provided by the Statistics Bureau
of Japan. It offers metadata search, normalized long and wide data,
human-readable argument aliases, automatic batching beyond the documented
limits of five indicators and 50 regions, explicit request pacing, retries,
and bilingual documentation.

## Downstream dependencies

There are no downstream CRAN dependencies because this is a new package.
