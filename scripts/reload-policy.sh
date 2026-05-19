#!/bin/bash
curl -X PUT http://policy.net.local:8181/v1/policies -H "Content-Type: text/plain" --data-binary @./config/policy.rego