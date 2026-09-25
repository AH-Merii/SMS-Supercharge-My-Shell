# An interactive fish on a pty in the current directory, a dirty repo on branch main;
# argv[1] is what git_status renders for the tree, GIT_CALLS the log of git's arguments.
import os
import pty
import re
import select
import signal
import sys
import time

AT_ONCE = 1.0   # seconds; the git shim sleeps 1.5 s on each read of the tree
GIVE_UP_AFTER = 20.0

dirty = sys.argv[1].encode()
pid, fd = pty.fork()
if pid == 0:
    os.execvpe("fish", ["fish", "-i"], dict(os.environ, TERM="xterm-256color"))

transcript = b""
mark = 0   # where the last match ended; what came after it is still to be examined
failures = []


def expect(what, needle, within):
    global transcript, mark
    start = time.monotonic()
    while time.monotonic() - start < within:
        if needle in transcript[mark:]:
            mark = transcript.index(needle, mark) + len(needle)
            print(f"{what} after {(time.monotonic() - start) * 1000:.0f} ms")
            return True
        ready, _, _ = select.select([fd], [], [], 0.05)
        if not ready:
            continue
        try:
            chunk = os.read(fd, 65536)
        except OSError:
            break
        # fish waits ten seconds for these replies unless something answers.
        if b"\x1b[0c" in chunk:
            os.write(fd, b"\x1b[?62;c")
        if b"\x1b[6n" in chunk:
            os.write(fd, b"\x1b[1;1R")
        transcript += chunk
    failures.append(f"{what}: not within {within:.0f} s")
    return False


def tree_reads():
    with open(os.environ["GIT_CALLS"], "rb") as log:
        return sum(1 for line in log if re.search(rb"(^| )(status|diff)( |$)", line))


expect("prompt usable", "❯".encode(), AT_ONCE)
expect("branch shown", b"main", GIVE_UP_AFTER)

os.write(fd, b"false\n")
expect("failure shown, in red", "\x1b[1;31m❯".encode(), AT_ONCE)
# The render that command started is still reading the tree; let it finish.
reads = -1
while reads != tree_reads():
    reads = tree_reads()
    time.sleep(2)
os.write(fd, b"\x1b")
expect("vi normal mode shown", "❮".encode(), AT_ONCE)
time.sleep(0.5)
if tree_reads() != reads:
    failures.append("a mode change read the tree again")
os.write(fd, b"i")
expect("vi insert mode shown", "❯".encode(), AT_ONCE)

os.kill(pid, signal.SIGKILL)
os.waitpid(pid, 0)
plain = re.sub(rb"\x1b\[[0-9;?>]*[A-Za-z]|\x1bP[^\x1b]*\x1b\\|\x1b\][^\x07\x1b]*(\x07|\x1b\\)|\x1b[=>]|\r", b"", transcript)
if dirty not in plain:
    failures.append("the prompt never showed the dirty tree: " + repr(dirty))
for failure in failures:
    print(failure)
if failures:
    print("--- transcript")
    sys.stdout.buffer.write(plain)
    sys.exit(1)
