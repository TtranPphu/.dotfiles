#!/usr/bin/env python3
"""Run yazi in a relay pty that answers its DA1 probe.

Under tmux (popups especially) the terminal never replies to yazi's DA1
query, so yazi's startup probe stays pending and every quit blocks ~5s in
probe.wait(). This proxy intercepts the DA1 request and answers it, making
the probe complete immediately. Everything else is relayed untouched.
"""
import fcntl
import os
import pty
import re
import select
import signal
import struct
import sys
import termios

CSI = re.compile(rb"\x1b\[([0-?;<>]*)([!-~])")

pid, master = pty.fork()
if pid == 0:
    os.execvp("yazi", ["yazi", *sys.argv[1:]])


def set_winsize():
    try:
        size = fcntl.ioctl(0, termios.TIOCGWINSZ, b"\0" * 8)
        fcntl.ioctl(master, termios.TIOCSWINSZ, size)
    except OSError:
        pass


set_winsize()
signal.signal(signal.SIGWINCH, lambda *_: set_winsize())

old_tty = termios.tcgetattr(0)
raw = termios.tcgetattr(0)
raw[0] &= ~(termios.IGNBRK | termios.BRKINT | termios.PARMRK | termios.ISTRIP
            | termios.INLCR | termios.IGNCR | termios.ICRNL | termios.IXON)
raw[3] &= ~(termios.ECHO | termios.ECHONL | termios.ICANON | termios.ISIG | termios.IEXTEN)
raw[6][termios.VMIN] = 1
raw[6][termios.VTIME] = 0
termios.tcsetattr(0, termios.TCSANOW, raw)


def scan(data):
    """Relay yazi output, answering any DA1 (``ESC [ 0 c``) query in place."""
    out = bytearray()
    pos = 0
    while pos < len(data):
        nxt = data.find(b"\x1b[", pos)
        if nxt == -1:
            out += data[pos:]
            return bytes(out), b""
        out += data[pos:nxt]
        m = CSI.match(data, nxt)
        if not m:
            out += data[nxt:nxt + 1]
            pos = nxt + 1
            continue
        params, final = m.group(1), m.group(2)
        if final == b"c" and params.translate(None, b"?:<>;") in (b"", b"0"):
            os.write(master, b"\x1b[?1;2c")
        out += m.group(0)
        pos = m.end()
    return bytes(out), b""


buf = b""
try:
    while True:
        r, _, _ = select.select([master, 0], [], [])
        if master in r:
            try:
                data = os.read(master, 65536)
            except OSError:
                break
            if not data:
                break
            chunk, buf = scan(buf + data)
            os.write(1, chunk)
        if 0 in r:
            try:
                keys = os.read(0, 65536)
            except OSError:
                break
            if not keys:
                break
            os.write(master, keys)
finally:
    termios.tcsetattr(0, termios.TCSANOW, old_tty)
    try:
        os.kill(pid, signal.SIGTERM)
    except OSError:
        pass
    try:
        os.waitpid(pid, 0)
    except OSError:
        pass
