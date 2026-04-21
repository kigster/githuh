# Githuh — GitHub API Client

[![Ruby](https://github.com/kigster/githuh/workflows/Ruby/badge.svg)](https://github.com/kigster/githuh/actions?query=workflow%3ARuby)
![Coverage](docs/img/badge.svg)

As in... *git? huh?*

Githuh is a GitHub API client wrapper built on top of [Octokit](https://github.com/octokit/octokit.rb), using an extensible `dry-cli` command pattern. It is designed as a batteries-included CLI for tasks that are tedious to do through the GitHub web UI — exporting issues, generating repository listings, and (now) LLM-summarizing READMEs into human-readable descriptions.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Authentication](#authentication)
- [Commands](#commands)
  - [`githuh version`](#githuh-version)
  - [`githuh user info`](#githuh-user-info)
  - [`githuh repo list`](#githuh-repo-list)
  - [`githuh issue export`](#githuh-issue-export)
- [Global Options](#global-options)
- [LLM Support](#llm-support)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Repository listing** in Markdown or JSON, with fork/private filtering
- **LLM-generated descriptions** — fetch each repo's README and summarize it into a flowing 5–6 sentence blurb using either Anthropic (Claude) or OpenAI
- **Issue export** to JSON or [Pivotal Tracker-compatible CSV](https://www.pivotaltracker.com/help/articles/csv_import_export), with configurable label → point mapping
- **User info** for the currently-authenticated GitHub user
- **In-process architecture** — every command is also runnable inside another Ruby process for scripting and testing (~89% test coverage via Aruba in-process)

## Installation

```bash
gem install githuh
```

Or add it to your `Gemfile`:

```ruby
gem 'githuh'
```

## Authentication

Githuh reads your GitHub token, in priority order, from:

1. The `--api-token=<token>` CLI flag
1. The `GITHUB_TOKEN` environment variable
1. `user.token` in your global git config

To set the token globally in git (recommended):

```bash
git config --global --add user.token <your-github-pat>
```

To set it for a single session:

```bash
export GITHUB_TOKEN=<your-github-pat>
```

Alternatively, use a local `.env` file (see [LLM Support](#llm-support) below — Githuh auto-loads `.env` from the current directory and from `$HOME`).

## Commands

All invocations assume `githuh` is on your `PATH`. If running from a source checkout use `bundle exec exe/githuh` instead.

### `githuh version`

Print the current version string (no color, no banner — scriptable):

```bash
githuh version
# => 0.4.0
```

Aliases: `githuh v`, `githuh -v`, `githuh --version`.

______________________________________________________________________

### `githuh user info`

Print information about the currently authenticated user.

```
Command:
  githuh user info

Options:
  --api-token=VALUE   # Github API token; if not given, user.token is read from ~/.gitconfig
  --per-page=VALUE    # Pagination page size for Github API, default: 20
  --[no-]info         # Print UI elements, like the progress bar, default: true
  --[no-]verbose      # Print additional debugging info, default: false
  --help, -h          # Print this help
```

#### Examples

```bash
# Default invocation (uses token from git config or GITHUB_TOKEN)
githuh user info

# Supply the token explicitly
githuh user info --api-token=ghp_XXXXXXXXXXXXXXXXXXXX

# Suppress the summary box (handy for piping)
githuh user info --no-info

# Verbose, for debugging auth/permissions issues
githuh user info --verbose
```

______________________________________________________________________

### `githuh repo list`

List the authenticated user's owned repositories and render them as Markdown or JSON. The default output file is `<username>.repositories.<format>`.

```
Command:
  githuh repo list

Options:
  --api-token=VALUE   # Github API token; if not given, user.token is read from ~/.gitconfig
  --per-page=VALUE    # Pagination page size for Github API, default: 20
  --[no-]info         # Print UI elements, like the progress bar, default: true
  --[no-]verbose      # Print additional debugging info, default: false
  --file=VALUE        # Output file, overrides <username>.repositories.<format>
  --format=VALUE      # Output format: (markdown/json), default: "markdown"
  --forks=VALUE       # Include or exclude forks: (exclude/include/only), default: "exclude"
  --[no-]private      # If specified, returns only private repos for true, public for false
  --[no-]llm          # Use LLM (ANTHROPIC_API_KEY or OPENAI_API_KEY) to summarize README, default: false
  --help, -h          # Print this help
```

#### Examples

Default Markdown output with forks excluded, saved to `<username>.repositories.md`:

```bash
githuh repo list
```

Public repos only, custom output file:

```bash
githuh repo list --no-private --file=my-public-repos.md
```

JSON output for programmatic consumption:

```bash
githuh repo list --format=json --file=repos.json
```

Only forks — useful for auditing what you've forked vs. maintained:

```bash
githuh repo list --forks=only
```

Include everything, private + public + forks:

```bash
githuh repo list --forks=include --private
```

Bump the API page size (GitHub allows up to 100):

```bash
githuh repo list --per-page=100
```

Quiet mode (no progress bars, for scripting):

```bash
githuh repo list --no-info --no-verbose
```

LLM-summarized descriptions (see [LLM Support](#llm-support)):

```bash
githuh repo list --llm
```

All options combined — public repos, Markdown format, LLM summaries, verbose:

```bash
githuh repo list \
  --format=markdown \
  --no-private \
  --forks=exclude \
  --llm \
  --verbose \
  --file=portfolio.md
```

______________________________________________________________________

### `githuh issue export`

Export issues for a given repository into JSON or [Pivotal Tracker-compatible CSV](https://www.pivotaltracker.com/help/articles/csv_import_export). The default output file is `<username>.<repo>.issues.<format>`.

```
Command:
  githuh issue export REPO

Arguments:
  REPO                 # REQUIRED Name of the repo, eg "rails/rails"

Options:
  --api-token=VALUE    # Github API token; if not given, user.token is read from ~/.gitconfig
  --per-page=VALUE     # Pagination page size for Github API, default: 20
  --[no-]info          # Print UI elements, like the progress bar, default: true
  --[no-]verbose       # Print additional debugging info, default: false
  --file=VALUE         # Output file, overrides <username>.<repo>.issues.<format>
  --format=VALUE       # Output format: (json/csv), default: "csv"
  --mapping=VALUE      # YAML file with label to estimates mapping
  --help, -h           # Print this help
```

#### Label-to-Estimate Mapping

When exporting to Pivotal Tracker CSV, GitHub labels can be mapped to point estimates. Create a YAML file like this:

```yaml
---
label-to-estimates:
  Large: 5
  Medium: 3
  Small: 1
```

…and pass it via `--mapping=<path>`. Any label listed in the file is converted to its numeric estimate; other labels pass through unchanged in the `Labels` column.

#### Examples

Export all open issues from `rails/rails` as CSV:

```bash
githuh issue export rails/rails
```

Explicit format and output file:

```bash
githuh issue export rails/rails --format=json --file=rails-issues.json
```

Pivotal Tracker CSV with a label mapping:

```bash
githuh issue export kigster/githuh --mapping=config/label-mapping.yml
```

Quiet, scripted invocation with an explicit token:

```bash
githuh issue export kigster/githuh \
  --api-token=ghp_XXXXXXXXXXXXXXXXXXXX \
  --no-info \
  --no-verbose \
  --file=issues.csv
```

______________________________________________________________________

## Global Options

The following options are available on every subcommand (`user info`, `repo list`, `issue export`):

| Option | Default | Description |
| --- | --- | --- |
| `--api-token=VALUE` | _(from env / git config)_ | GitHub personal access token |
| `--per-page=VALUE` | `20` | Pagination page size for the GitHub API |
| `--[no-]info` | `true` | Print UI elements like the progress bar and info boxes |
| `--[no-]verbose` | `false` | Print additional debugging info |
| `--help, -h` | — | Print contextual help and exit |

## LLM Support

When you pass `--llm` to `repo list`, Githuh fetches each repo's README via the GitHub API and asks an LLM to summarize it into a 5–6 sentence description. This is far more informative than GitHub's single-line description field, especially for portfolios or internal directories.

### Configuration

Set one of the following in your environment or in a `.env` file at the project root or `$HOME`:

```bash
# Preferred (uses claude-haiku-4-5-20251001)
ANTHROPIC_API_KEY=sk-ant-...

# Fallback (uses gpt-4o-mini)
OPENAI_API_KEY=sk-...
```

If both are set, Anthropic is preferred. If `--llm` is set but neither key is available, the command exits with a clear error.

A `.env` parser is built in (no `dotenv` gem required). `.env` is also in `.gitignore` by default to keep secrets out of commits.

### Behavior

On `repo list --llm` you will see:

1. An info box announcing LLM summarization (provider + model)
1. The regular `Format / File / Forks` info box
1. The pagination progress bar (magenta)
1. An LLM progress bar — **yellow for Anthropic**, **green for OpenAI** — advancing once per repo
1. A success box with the total record count

Each repo's description in the output is replaced with the LLM-generated summary. On any per-repo failure (README fetch error, LLM timeout, auth failure, etc.) the command falls back silently to GitHub's original description — use `--verbose` to see why.

### Cost & Performance

For 30–50 repos, expect:

- **Wall-clock**: ~45–90 seconds (sequential — one README fetch + one LLM call per repo)
- **Cost**: roughly $0.01–$0.05 per run with the default models

### Example

```bash
# Complete portfolio run
githuh repo list \
  --format=markdown \
  --no-private \
  --forks=exclude \
  --llm \
  --file=portfolio.md
```

## Contributing

Pull requests welcome at <https://github.com/kigster/githuh/pulls>.

Development setup:

```bash
git clone git@github.com:kigster/githuh.git
cd githuh
bundle install
just test      # run the rspec suite
just lint      # run rubocop
just format    # auto-correct rubocop offenses
```

## License

© 2020–present Konstantin Gredeskoul, released under the [MIT License](LICENSE.txt).
