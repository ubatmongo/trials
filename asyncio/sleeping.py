import asyncio
import datetime

async def hello() -> None:
    await asyncio.sleep(1)
    return "Hello World!"


async def main() -> None:
    #print(f"here 1 {datetime.now}")
    message = await hello()
    print("here 2")
    print(message)


asyncio.run(main())
