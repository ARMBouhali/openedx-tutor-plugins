FROM {{ PARAGON_BUILDER_IMAGE }}

WORKDIR /brand-builder

COPY entrypoint.sh /entrypoint.sh

RUN apk add --no-cache git && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
