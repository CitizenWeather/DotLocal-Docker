#!/usr/bin/env python3
import time
import random
import paho.mqtt.client as mqtt

MQTT_HOST = "mosquitto"
MQTT_PORT = 1883
TOPIC = "application/device/+/rx"

client = mqtt.Client()
client.connect(MQTT_HOST, MQTT_PORT)

while True:
    payload = {
        "devEUI": "00-00-00-00-00-00-00-01",
        "fPort": 1,
        "data": f"temperature={random.uniform(20,30):.1f}"
    }
    client.publish(TOPIC, str(payload))
    time.sleep(60)