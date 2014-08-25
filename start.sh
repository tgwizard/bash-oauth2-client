set -e

while true ; do netcat -l -p 8998 -e ./server.sh; test $? -gt 128 && break ; done
