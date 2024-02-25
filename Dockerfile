FROM ubuntu:focal

RUN apt-get update \
	&& apt-get install clang-format \
	httpie \
	jq -y

COPY ./entrypoint.sh /usr/local/bin/
ENTRYPOINT [ "entrypoint.sh" ]
