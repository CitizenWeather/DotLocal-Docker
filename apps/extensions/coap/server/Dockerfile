FROM python:3.11-slim
WORKDIR /app
RUN pip install aiocoap
COPY coap_server.py .
CMD ["python", "coap_server.py"]