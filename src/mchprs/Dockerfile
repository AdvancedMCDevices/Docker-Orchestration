# Stage 1: Use a base image (e.g., BusyBox, which is designed for static building) to get a shell binary
FROM busybox:1.35.0-uclibc AS busybox-stage

FROM stackdoubleflow/mchprs

COPY --from=busybox-stage /bin/sh /bin/sh
COPY --from=busybox-stage /bin/chmod /bin/chmod
COPY --from=busybox-stage /bin/sed /bin/sed
COPY --from=busybox-stage /bin/echo /bin/echo

# Use entrypoint to inject secrets at runtime for "better" security
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /data

COPY /Config.toml .

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
