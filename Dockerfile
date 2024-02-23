FROM ubuntu:focal

RUN apt-get update \
	&& apt-get install clang-format \
	vim -y

WORKDIR /app
COPY ./main.cpp ./entrypoint.sh /app/
ENTRYPOINT [ "./entrypoint.sh" ]
