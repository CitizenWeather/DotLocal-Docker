FROM varnish:7.4

COPY default.vcl.template /etc/varnish/default.vcl.template

CMD sh -c "envsubst < /etc/varnish/default.vcl.template > /etc/varnish/default.vcl && \
           varnishd -F -f /etc/varnish/default.vcl -s malloc=${VARNISH_SIZE:-256M} -a :80 -T 0.0.0.0:6082"