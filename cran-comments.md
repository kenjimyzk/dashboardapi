## Resubmission

This is a resubmission. In response to the CRAN review, I replaced the
relative `README.ja.md` link in `README.md` with an absolute GitHub URL. This
prevents the link from being interpreted as the invalid URI
`http://readme.ja.md/`.

## Test environments

- local macOS Tahoe 26.6 (arm64), R 4.6.1

## R CMD check results

The rebuilt source tarball completed `R CMD check --as-cran`, including CRAN
incoming feasibility and remote URL checks, with:

0 errors | 0 warnings | 2 notes

The notes are:

- the expected `New submission` note for version 0.1.0;
- local HTML validation was skipped because the installed HTML Tidy is too old.

The invalid README file URI reported in the previous review no longer appears.

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
