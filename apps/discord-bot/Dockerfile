FROM python:3.10.7-alpine3.15

RUN apk update && apk upgrade
RUN pip3 install py-cord

WORKDIR /app
COPY . .

CMD python3 main.py
