FROM couchbase:community-3.1.3

MAINTAINER Sean Dowd <dowds@avalonconsult.com>

RUN apt-get update && apt-get install -y netcat
ADD cbinit-entrypoint.sh /
ENTRYPOINT /cbinit-entrypoint.sh
