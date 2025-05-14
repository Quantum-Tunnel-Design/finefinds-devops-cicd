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

# Check system status via API
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9000/api/system/status)
if [ "$HTTP_CODE" -ne 200 ]; then
  log "ERROR: SonarQube API returned HTTP code $HTTP_CODE"
  
  # Log more diagnostics
  log "Memory usage: $(free -h)"
  log "Disk space: $(df -h /opt/sonarqube)"
  log "Recent logs:"
  tail -n 50 /opt/sonarqube/logs/sonar.log | tee -a "$LOG_FILE"
  
  exit 1
fi

# Check system status for "UP" state
STATUS=$(curl -s http://localhost:9000/api/system/status | grep -o '"status":"[^"]*"' | cut -d':' -f2 | tr -d '"')
if [ "$STATUS" != "UP" ]; then
  log "ERROR: SonarQube system status is $STATUS, expected UP"
  
  # Log more diagnostics
  log "Memory usage: $(free -h)"
  log "Disk space: $(df -h /opt/sonarqube)"
  log "Recent logs:"
  tail -n 50 /opt/sonarqube/logs/sonar.log | tee -a "$LOG_FILE"
  
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