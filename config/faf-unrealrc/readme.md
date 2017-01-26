Place the following files here:

ADD server.cert.pem /home/unreal/server.cert.pem
ADD server.key.pem /home/unreal/server.key.pem
RUN cp /home/unreal/server.cert.pem /home/unreal/unrealircd/conf/ssl/server.cert.pem
RUN cp /home/unreal/server.key.pem /home/unreal/unrealircd/conf/ssl/server.key.pem
