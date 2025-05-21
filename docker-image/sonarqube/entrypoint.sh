#!/bin/bash
set -e

# Custom entrypoint script for SonarQube in ECS environment
echo "Starting SonarQube with custom entrypoint"

# Create necessary directories 
mkdir -p /opt/sonarqube/data /opt/sonarqube/logs /opt/sonarqube/extensions /opt/sonarqube/temp
chmod -R 777 /opt/sonarqube/data /opt/sonarqube/logs /opt/sonarqube/extensions /opt/sonarqube/temp

# Print environment for debugging (exclude sensitive info)
echo "=== SonarQube Environment Settings ==="
env | grep -v PASSWORD | grep -v JDBC_URL | grep SONAR
echo "===================================="

# Check if PostgreSQL is accessible before starting
if [[ -n "$SONAR_JDBC_URL" && "$SONAR_JDBC_URL" == *"postgresql"* ]]; then
  echo "Checking PostgreSQL connection..."
  
  # Extract host and port from JDBC URL
  # Example format: jdbc:postgresql://hostname:port/database
  if [[ "$SONAR_JDBC_URL" =~ jdbc:postgresql://([^:/]+)(:([0-9]+))? ]]; then
    PG_HOST="${BASH_REMATCH[1]}"
    PG_PORT="${BASH_REMATCH[3]:-5432}"
    
    echo "Waiting for PostgreSQL at $PG_HOST:$PG_PORT..."
    
    # Wait for PostgreSQL to be available
    for i in {1..30}; do
      if timeout 5 bash -c "</dev/tcp/$PG_HOST/$PG_PORT" &>/dev/null; then
        echo "PostgreSQL is available!"
        break
      fi
      
      if [ $i -eq 30 ]; then
        echo "ERROR: PostgreSQL at $PG_HOST:$PG_PORT is not available after 30 attempts"
        exit 1
      fi
      
      echo "Waiting for PostgreSQL to become available (attempt $i/30)..."
      sleep 10
    done
  else
    echo "WARNING: Could not parse PostgreSQL host and port from JDBC URL"
  fi
fi

# Adjust system settings for container environment
echo "Adjusting system settings..."
sysctl -w vm.max_map_count=262144 || echo "WARNING: Could not set vm.max_map_count (not running as root or in privileged mode)"
ulimit -n 65536 || echo "WARNING: Could not set file descriptor limit"

# Start SonarQube with original entrypoint
echo "Executing SonarQube..."
exec /opt/sonarqube/bin/run.sh "$@" 