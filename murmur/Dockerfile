FROM ubuntu:trusty
RUN apt-get update
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:mumble/release
RUN apt-get update
RUN apt-get install -y mumble-server libmysqlclient-dev mysql-client-5.6
RUN dpkg-reconfigure mumble-server
ADD mumble-server.ini /etc/mumble-server.ini
ADD run_mumble.sh /tmp/run_mumble.sh
RUN chmod +x /tmp/run_mumble.sh
CMD bash -c /tmp/run_mumble.sh
EXPOSE 64738
