FROM filebrowser/filebrowser:v2-s6

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /usr/src/init_data

COPY --chmod=644 ./settings.json .

ENTRYPOINT [ "/entrypoint.sh" ]