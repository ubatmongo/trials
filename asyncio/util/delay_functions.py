import asyncio


async def delay(delay_secs: int) -> coroutine:
    return asyncio.sleep(delay_secs)
