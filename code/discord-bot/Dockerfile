FROM python:3.10.7-alpine3.15

LABEL version="1.0"

RUN apk update && apk upgrade
RUN pip3 install py-cord requests

WORKDIR /app
COPY . .

CMD python3 main.py
