![Ruby](https://github.com/kigster/githuh/workflows/Ruby/badge.svg)

# Githuh — GitHub API client

As in... **git? huh?**.

Github API client wrapper on top of Octokit, that provides extensible command pattern for wrapping Github functionality.

At the moment two features are implemented:

 * Generating a list of org's (or personal) repositories and rending in either markdown or JSON
 * Printing info of the logged in user.

## Usage

Add your Github Token to the global config:

```bash
git config --global --set user.token <token>
```

After that:

```bash
❯ githuh
Commands:
  githuh repo [SUBCOMMAND]
  githuh user [SUBCOMMAND]
  githuh version                        # Print version
```

Githuh works by implement subcomands:

### `repo list`

This functionality was born out of the need to generate a brief but comprehensive, well-formatted list of prior inventions for a typical employment contract. 

> NOTE: nothing in this library constitutes a legal advice. Use it at your own risk. For more information, please see [WARRANTY](WARANTY.md).

```bash
 1 ❯ githuh repo list --help
Command:
  githuh repo list

Usage:
  githuh repo list

Description:
  List owned repositories and render the output in markdown or JSON

Options:
  --api-token=VALUE               	# Github API token; if not given, user.token is read from ~/.gitconfig
  --per-page=VALUE                	# Pagination page size for Github API, default: 50
  --[no-]verbose                  	# Print verbose info, default: true
  --file=VALUE                    	# Output file. If not provided, STDERR is used.
  --format=VALUE                  	# Output format: (markdown/json), default: "markdown"
  --forks=VALUE                   	# Include or exclude forks: (include/only/exclude), default: "include"
  --help, -h                      	# Print this help
```

### `user info`

This command prints the info about currently authenticated user.

```bash
❯ githuh user info
{
                  :login => "kigster",
                    :url => "https://api.github.com/users/kigster",
               :html_url => "https://github.com/kigster",
               ..............

```

## Copyright

© 2020 Konstantin Gredeskoul
