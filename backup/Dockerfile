FROM postgres:16-alpine

# Alpine package revisions move with the base image patch release; pinning them
# here would make rebuilds fail after the repository index advances.
# hadolint ignore=DL3018
RUN apk add --no-cache openssl tzdata

COPY backup.sh backup-loop.sh restore.sh /usr/local/bin/
RUN chmod 0555 /usr/local/bin/backup.sh \
    /usr/local/bin/backup-loop.sh \
    /usr/local/bin/restore.sh

ENTRYPOINT ["backup-loop.sh"]
