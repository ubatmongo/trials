import asyncio
# from util import delay
from datetime import datetime

async def main():
    sleep_for_three = asyncio.create_task(asyncio.sleep(3))
    sleep_again = asyncio.create_task(asyncio.sleep(3))
    sleep_once_more = asyncio.create_task(asyncio.sleep(3))
    print(f"1 {datetime.now()}")
    await sleep_for_three
    print(f"2 {datetime.now()}")
    await sleep_again
    print(f"3 {datetime.now()}")
    await sleep_once_more
    print(f"4 {datetime.now()}")


asyncio.run(main())
