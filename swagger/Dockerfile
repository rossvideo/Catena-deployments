FROM swaggerapi/swagger-ui:latest

# Python + tools
RUN apk add --no-cache jq python3 py3-pip

COPY requirements.txt /opt/requirements.txt
COPY openapi_update.py /opt/openapi_update.py
COPY entrypoint-openapi.sh /docker-entrypoint.d/10-openapi-update.sh

ENV SWAGGER_JSON_URL=/openapi.yaml
# Build example:
# docker build --pull --rm -f 'Dockerfile' -t 'catenadeployments:latest' . 
# docker run --rm -it -p 80:80/tcp -p 8080:8080/tcp catenadeployments:latest
