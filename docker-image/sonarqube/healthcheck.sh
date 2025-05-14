#!/bin/bash

# This script is used for health checking SonarQube and providing better diagnostics
# when issues occur in container environments like ECS

# Log file for debugging
LOG_FILE="/opt/sonarqube/logs/healthcheck.log"

# Function to log with timestamp
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

# Create log directory if it doesn't exist
mkdir -p /opt/sonarqube/logs

# Get container uptime in seconds
UPTIME_SECONDS=$(cat /proc/uptime | awk '{print int($1)}')

# During startup phase, be more lenient with health checks
# Allow 3 minutes (180 seconds) for startup
if [ $UPTIME_SECONDS -lt 180 ]; then
  log "Container uptime is ${UPTIME_SECONDS}s. In startup grace period, passing health check."
  exit 0
fi

# Check if SonarQube web server is running
PID_WEB=$(pgrep -f "org.sonar.server.app.WebServer" || echo "")
if [ -z "$PID_WEB" ]; then
  log "ERROR: SonarQube web server is not running"
  exit 1
fi

# Check if Elasticsearch is running
PID_ES=$(pgrep -f "org.sonar.search.SearchServer" || echo "")
if [ -z "$PID_ES" ]; then
  log "ERROR: Elasticsearch is not running"
  exit 1
fi

# Check if Compute Engine is running
PID_CE=$(pgrep -f "org.sonar.ce.app.CeServer" || echo "")
if [ -z "$PID_CE" ]; then
  log "ERROR: Compute Engine is not running"
  exit 1
fi

# Try API check up to 3 times with brief pauses
for i in {1..3}; do
  # Check system status via API
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9000/api/system/status)
  if [ "$HTTP_CODE" -eq 200 ]; then
    break
  fi
  
  if [ $i -eq 3 ]; then
    log "ERROR: SonarQube API returned HTTP code $HTTP_CODE after 3 retries"
    
    # Log more diagnostics
    log "Memory usage:"
    free -h >> "$LOG_FILE" 2>&1
    log "Disk space:"
    df -h /opt/sonarqube >> "$LOG_FILE" 2>&1
    log "Process status:"
    ps aux | grep -i sonar >> "$LOG_FILE" 2>&1
    log "Recent logs:"
    tail -n 50 /opt/sonarqube/logs/sonar.log >> "$LOG_FILE" 2>&1
    
    exit 1
  fi
  
  log "Warning: SonarQube API returned HTTP code $HTTP_CODE, retrying in 5 seconds (attempt $i/3)"
  sleep 5
done

# Check system status for "UP" state
STATUS=$(curl -s http://localhost:9000/api/system/status | grep -o '"status":"[^"]*"' | cut -d':' -f2 | tr -d '"')
if [ "$STATUS" != "UP" ]; then
  log "ERROR: SonarQube system status is $STATUS, expected UP"
  
  # Log more diagnostics
  log "Memory usage:"
  free -h >> "$LOG_FILE" 2>&1
  log "Disk space:"
  df -h /opt/sonarqube >> "$LOG_FILE" 2>&1
  log "Process status:"
  ps aux | grep -i sonar >> "$LOG_FILE" 2>&1
  log "Recent logs:"
  tail -n 50 /opt/sonarqube/logs/sonar.log >> "$LOG_FILE" 2>&1
  
  exit 1
fi

# Check database connectivity
DB_STATUS=$(curl -s http://localhost:9000/api/system/status | grep -o '"db":{"status":"[^"]*"' | cut -d':' -f3 | tr -d '"')
if [ "$DB_STATUS" != "UP" ]; then
  log "ERROR: Database status is $DB_STATUS, expected UP"
  exit 1
fi

log "SonarQube is healthy"
exit 0 