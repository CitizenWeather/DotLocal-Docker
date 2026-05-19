#!/bin/bash
NEW_DNS=$1
sed -i "s/^DNS_APP=.*/DNS_APP=$NEW_DNS/" .env
make down && make up