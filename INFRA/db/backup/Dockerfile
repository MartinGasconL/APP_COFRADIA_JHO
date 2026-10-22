FROM mysql:8.0

RUN microdnf install -y cronie && microdnf clean all

COPY backup.sh /usr/local/bin/backup.sh
COPY crontab /etc/cron.d/backup

RUN chmod +x /usr/local/bin/backup.sh \
    && chmod 0644 /etc/cron.d/backup \
    && crontab /etc/cron.d/backup

ENTRYPOINT ["/usr/sbin/crond", "-n"]
