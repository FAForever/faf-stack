env
cat >> /etc/mumble-server.ini <<EOF
dbDriver=QMYSQL
dbUsername=$DB_USER
dbPassword=$DB_PASSWORD
dbHost=$DB_PORT_3306_TCP_ADDR
dbPort=3306
dbPrefix=
dbOpts=
EOF
/usr/sbin/murmurd -supw $SUPERUSER_PASSWORD
while true
do
if pgrep -f murmurd 1> /dev/null;then
        sleep 1
else
        echo SERVER CRASHED
	/usr/sbin/murmurd -v -fg
fi
done
