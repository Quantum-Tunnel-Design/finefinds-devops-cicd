FROM sonarqube:9.11-community

# Create necessary directories for SonarQube with correct permissions
RUN mkdir -p /opt/sonarqube/data /opt/sonarqube/logs /opt/sonarqube/extensions /opt/sonarqube/temp && \
    chmod -R 777 /opt/sonarqube/data /opt/sonarqube/logs /opt/sonarqube/extensions /opt/sonarqube/temp

# Install additional diagnostic tools
RUN apt-get update && apt-get install -y \
    procps \
    curl \
    wget \
    htop \
    net-tools \
    netcat \
    dnsutils \
    lsof \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure Elasticsearch for container environments
ENV SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
    SONAR_WEB_JAVAADDITIONALOPTS="-Xmx1G -Xms1G" \
    SONAR_SEARCH_JAVAADDITIONALOPTS="-Xmx512m -Xms512m" \
    SONAR_CE_JAVAADDITIONALOPTS="-Xmx1G -Xms1G" \
    SONAR_JDBC_MAXACTIVE=20 \
    SONAR_JDBC_MAXIDLE=10 \
    SONAR_JDBC_MINIDLE=5 \
    SONAR_WEB_STARTUPGRACEPERIOD=300

# Copy health check and entrypoint scripts
COPY healthcheck.sh /opt/sonarqube/bin/healthcheck.sh
COPY entrypoint.sh /opt/sonarqube/bin/custom-entrypoint.sh
RUN chmod +x /opt/sonarqube/bin/healthcheck.sh /opt/sonarqube/bin/custom-entrypoint.sh

# Expose SonarQube port
EXPOSE 9000

# Increase health check timeout to accommodate longer startup
HEALTHCHECK --interval=30s --timeout=10s --retries=5 --start-period=180s \
  CMD /opt/sonarqube/bin/healthcheck.sh

# Define volumes for persistence
VOLUME ["/opt/sonarqube/data", "/opt/sonarqube/logs", "/opt/sonarqube/extensions", "/opt/sonarqube/temp"]

# Use our custom entrypoint
ENTRYPOINT ["/opt/sonarqube/bin/custom-entrypoint.sh"]