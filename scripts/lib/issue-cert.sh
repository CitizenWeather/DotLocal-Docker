#!/bin/bash
DOMAIN=$1
step-cli ca certificate $DOMAIN $DOMAIN.crt $DOMAIN.key --ca-url https://ca.${NETLOCAL_ROOT_DOMAIN:-net.local} --root ./ca.crt