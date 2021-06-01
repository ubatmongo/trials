import asyncio

async def delay(delay_secs: int) -> None:
    print(f"waiting for {delay_secs}")
    await asyncio.sleep(delay_secs)
    print(f"done waiting for {delay_secs}")


async def hello_every_second():
    for i in range(3):
        await asyncio.sleep(1)
        print("I'm running other code while I'm waiting!")


async def main():
    first_delay = asyncio.create_task(delay(4))
    second_delay = asyncio.create_task(delay(4))
    await hello_every_second()
    await first_delay
    await second_delay


asyncio.run(main())
