# If the image changed, the second stage image should be changed too
FROM node:20-bookworm-slim AS base2-slim
ARG TARGETPLATFORM

RUN echo "deb http://deb.debian.org/debian testing main" >> /etc/apt/sources.list && \
    apt update && \
    apt --yes --no-install-recommends -t testing install apprise sqlite3 ca-certificates && \
    apt --yes --no-install-recommends -t stable install  \
        iputils-ping  \
        util-linux  \
        dumb-init  \
        curl  \
        sudo \
        nscd && \
    rm -rf /var/lib/apt/lists/* && \
    apt --yes autoremove


# Install cloudflared
RUN curl https://pkg.cloudflare.com/cloudflare-main.gpg --output /usr/share/keyrings/cloudflare-main.gpg && \
    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared bullseye main' | tee /etc/apt/sources.list.d/cloudflared.list && \
    apt update && \
    apt install --yes --no-install-recommends -t stable cloudflared && \
    cloudflared version && \
    rm -rf /var/lib/apt/lists/* && \
    apt --yes autoremove

# MariaDB, Chromium and fonts
FROM base2-slim AS base2
ENV UPTIME_KUMA_ENABLE_EMBEDDED_MARIADB=1
RUN apt update && \
    apt --yes --no-install-recommends install chromium fonts-indic fonts-noto fonts-noto-cjk mariadb-server && \
    rm -rf /var/lib/apt/lists/* && \
    apt --yes autoremove && \
    chown -R node:node /var/lib/mysql

RUN mkdir /app/
COPY WEB.tar.gz /tmp
RUN tar xvf /tmp/WEB.tar.gz -C /app/


WORKDIR /app/WEB

RUN rm -rf /tmp/*.tar.gz

EXPOSE 3000 3001

CMD ["node","server/server.js"]
