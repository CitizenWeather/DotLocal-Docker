FROM python:3.11-slim
WORKDIR /app
RUN pip install aiocoap
COPY coap_client.py .
CMD ["python", "coap_client.py"]