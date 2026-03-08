FROM alpine:3.20 AS builder

RUN apk add --no-cache gettext
COPY --chmod=644 ./server/velocity.toml /velocity.toml
RUN envsubst < /velocity.toml > /velocity.toml.rendered && \
    mv /velocity.toml.rendered /velocity.toml

ARG TYPE=VELOCITY
ARG EULA=TRUE
FROM itzg/mc-proxy:latest

ENV TYPE=VELOCITY
ENV EULA=TRUE

WORKDIR /usr/src/init_data
COPY ./server .
COPY --from=builder /velocity.toml velocity.toml
# Set permissions for the server files (user's name is 
# bungeecord in the base image despite using Velocity)
RUN chown -R bungeecord:bungeecord . && \ 
    find . -type d -exec chmod 755 {} + && \
    find . -type f -exec chmod 644 {} +

VOLUME [ "/server" ]

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]