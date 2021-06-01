import asyncio
from asyncio import CancelledError


async def delay(delay_secs: int) -> None:
    print(f"waiting for {delay_secs}")
    await asyncio.sleep(delay_secs)
    print(f"done waiting for {delay_secs}")


async def main():
    long_task = asyncio.create_task(delay(10))

    seconds_elapsed = 0

    while not long_task.done():
        print('Task not finished, checking again in a second.')
        await asyncio.sleep(1)
        seconds_elapsed = seconds_elapsed + 1
        if seconds_elapsed == 5:
            long_task.cancel()

    try:
        await long_task
    except CancelledError:
        print('Our task was cancelled')


asyncio.run(main())
