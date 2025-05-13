#!/bin/sh
set -e

# Display Node.js version and architecture
echo "Node.js $(node -v)"
echo "Architecture: $(uname -m)"

# First argument is Node or npm command
if [ "${1#-}" != "${1}" ] || [ -z "$(command -v "${1}")" ]; then
  set -- node "$@"
fi

exec "$@" 