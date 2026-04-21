set shell := ["bash", "-lc"]

rbenv := 'eval "$(rbenv init -)"'

[no-exit-message]
recipes:
    @just --choose

# Sync all dependencies
install:
    {{rbenv}} && bundle install -j 12

upgrade:
    {{rbenv}} && bundle update --bundler
    {{rbenv}} && bundle update

# Lint and reformat files
lint-fix *args:
    {{rbenv}} && bundle exec rubocop -a
    {{rbenv}} && bundle exec rubocop --auto-gen-config
    git add .

alias format := lint-fix

# Lint and reformat files
lint:
    {{rbenv}} && bundle exec rubocop

# Run all the tests
test *args: 
    #!/usr/bin/env bash
    {{rbenv}} && RAILS_ENV=test GITHUB_TOKEN=$(git config user.token) bundle exec rspec {{args}}

# Run tests with coverage
test-coverage: test
    open coverage/index.html

doc:
    {{rbenv}} && bundle exec rake doc
    open doc/index.html
    
clean:
    #!/usr/bin/env bash
    find . -name .DS_Store -delete -print || true
    rm -rf tmp/*

# Run all lefthook pre-commit hooks
ci:
    {{rbenv}} && lefthook run pre-commit --all-files

changelog:
    #!/usr/bin/env bash
    export CHANGELOG_GITHUB_TOKEN=$(git config user.token)
    command -v github_changelog_generator >/dev/null || brew install github_changelog_generator
    github_changelog_generator --user kigster --repo githuh


