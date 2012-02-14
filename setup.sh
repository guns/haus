#!/bin/sh

if ! command -v ruby &>/dev/null; then
    echo 'Could not find `ruby` in your PATH! Haus requires Ruby version 1.8.6+'
    exit 1
fi

BASE="$(cd "$(dirname "$0")"; pwd)"
echo "Running \`$BASE/bin/haus link $@\`"
exec "$BASE/bin/haus" link "$@"
