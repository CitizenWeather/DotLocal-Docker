import asyncio
from aiocoap import Context, Message, Code

async def main():
    context = await Context.create_server_context()
    print("CoAP server listening on port 5683 (UDP)")

    @context.site.add_resource('.well-known/core')
    class WellKnownCore:
        async def render_get(self, request):
            return Message(payload=b'</sensors/temp>,</actuators/light>')

    @context.site.add_resource('sensors/temp')
    class Temperature:
        async def render_get(self, request):
            import random
            temp = random.uniform(20, 30)
            return Message(payload=f"{temp:.1f}".encode())

    await asyncio.get_running_loop().create_future()

if __name__ == "__main__":
    asyncio.run(main())