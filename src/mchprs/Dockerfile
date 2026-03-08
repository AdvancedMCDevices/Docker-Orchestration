FROM alpine:3.20 AS builder

RUN apk add --no-cache gettext

ENV POSTGRES_USER=bioopjpoajsd
ENV POSTGRES_DB=bob
ENV POSTGRES_PASSWORD=booop

ENV VELOCITY_SECRET=supersecretkey

COPY --chmod=644 ./Config.toml /data/Config.toml
RUN envsubst < /data/Config.toml > /data/Config.toml.rendered \
	&& mv /data/Config.toml.rendered /data/Config.toml

FROM stackdoubleflow/mchprs

COPY --from=builder --chmod=644 /data/Config.toml /data/Config.toml