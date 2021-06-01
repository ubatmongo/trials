import os
import threading

print(f'running thread with pid: {os.getpid()}')

total_thread = threading.active_count()
thread_name = threading.current_thread().getName()

print(f'no of threads {total_thread}')
print(f'curent thread {thread_name}')
