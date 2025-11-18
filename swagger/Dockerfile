FROM swaggerapi/swagger-ui:latest

COPY sedstuff.sh /docker-entrypoint.d/sedstuff.sh
RUN apk add jq
ENV SWAGGER_JSON_URL=/openapi.yaml
#docker build --pull --rm -f 'Dockerfile' -t 'catenadeployments:latest' . ; docker run --rm -it -p 80:80/tcp -p 8080:8080/tcp catenadeployments:latest