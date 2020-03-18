![Ruby](https://github.com/kigster/githuh/workflows/Ruby/badge.svg)
![Coverage](docs/img/coverage.svg)

# Githuh — GitHub API client

As in... **git? huh?**.

Github API client wrapper on top of Octokit, that provides extensible command pattern for wrapping Github functionality.

At the moment two features are implemented:

 * Generating a list of org's (or personal) repositories and rending in either markdown or JSON
 * Printing info of the logged in user.

## Using `githuh`

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

#### Motivation 

This functionality was born out of the need to generate a brief but comprehensive, well-formatted list of prior inventions for a typical employment contract. 

> NOTE: nothing in this library constitutes a legal advice. Use it at your own risk. For more information, please see [WARRANTY](WARANTY.md).

Please watch the following Ascii Screen cast to see this command in action: 

[![asciicast](https://asciinema.org/a/CW8NbYfu9RsifQJVU6tKRtRkU.svg)](https://asciinema.org/a/CW8NbYfu9RsifQJVU6tKRtRkU)

#### Usage

```bash
❯ githuh repo list --help

Githuh CLI 0.1.2 — API client for Github.com.
© 2020 Konstantin Gredeskoul, All rights reserved.  MIT License.

Usage:
  githuh repo list

Description:
  List owned repositories and render the output in markdown or JSON
  Default output file is <username>.repositories.<format>

Options:
  --api-token=VALUE               	# Github API token; if not given, user.token is read from ~/.gitconfig
  --per-page=VALUE                	# Pagination page size for Github API, default: 20
  --[no-]info                     	# Print UI elements, like a the progress bar, default: true
  --[no-]verbose                  	# Print additional debugging info, default: false
  --file=VALUE                    	# Output file, overrides <username>.repositories.<format>
  --format=VALUE                  	# Output format: (markdown/json), default: "markdown"
  --forks=VALUE                   	# Include or exclude forks: (exclude/include/only), default: "exclude"
  --[no-]private                  	# If specified, returns only private repos for true, public for false
  --help, -h                      	# Print this help
```

#### Example

For instance, to generate a markdown list of all of your **public** repos that are also **not forks**, run the following:

```bash
$ githuh repo list --format=markdown --no-private --forks=exclude --file=repos.md
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
