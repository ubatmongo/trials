import asyncio
from asyncio import CancelledError


async def delay(delay_secs: int) -> None:
    print(f"waiting for {delay_secs}")
    await asyncio.sleep(delay_secs)
    print(f"done waiting for {delay_secs}")


async def main():
    delay_task = asyncio.create_task(delay(2))
    try:
        result = await asyncio.wait_for(delay_task, timeout=1)
        print(result)
    except asyncio.exceptions.TimeoutError:
        print('Got a timeout!')

    print(f'Was the task cancelled? {delay_task.cancelled()}')


asyncio.run(main())
