import asyncio
from aiocoap import Context, Message, Code

async def main():
    context = await Context.create_client_context()
    request = Message(code=Code.GET, uri="coap://coap-server/sensors/temp")
    response = await context.request(request).response
    print(f"Temperature: {response.payload.decode()}")

if __name__ == "__main__":
    asyncio.run(main())