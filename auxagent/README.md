# auxagent

A tiny, reliable remote-exec and file-transfer agent for **A/UX** machines,
built to replace the fragile telnet/ftp automation we were using to drive the
QEMU A/UX build guest and the real SE/30.

It speaks **AAP (A/UX Agent Protocol)** — not a new wire format, just a thin
set of conventions layered on **HTTP/1.0**. The agent is a ~300-line C program
that compiles with the modernized A/UX gcc (2.7.2.3) and Berkeley sockets; the
client is plain `curl` on your Mac (wrapped by `auxctl` for convenience).

## Why this exists

Driving A/UX over telnet is unreliable for automation:

- **No framing** — telnet is a raw cooked-terminal byte stream; you can't tell
  "command running" from "command done" without bolting on sentinels.
- **A/UX telnetd flush-lag** — output isn't flushed until the next input byte,
  so every command appears to hang.
- **Input corruption** — terminal line-discipline / option negotiation can drop
  or mangle bytes under load.
- **Leaky sessions** — each telnet/ftp connection spawns login/getty/ftpd
  processes that linger, exhaust login slots, and can wedge the box.

AAP fixes all of that the way HTTP already does: **every operation is one
request with an explicit `Content-Length`**, so completion is unambiguous;
connections are **one-shot and stateless**, so nothing accumulates; and each
transfer carries a **CRC-32** for integrity.

## Protocol (AAP/1.0)

Transport: HTTP/1.0 over TCP. One request per connection; the agent closes the
socket after responding. All bodies are length-delimited by `Content-Length`.

| Method & path            | Body            | Response body        | Key response headers              |
|--------------------------|-----------------|----------------------|-----------------------------------|
| `GET /ping`              | —               | `auxagent <ver>`     | —                                 |
| `POST /exec`             | shell command   | merged stdout+stderr | `X-Exit-Code: N`                  |
| `GET /file/<abspath>`    | —               | file bytes           | `X-Aap-Sum: <crc32-hex>`, `X-Exit-Code` |
| `PUT /file/<abspath>`    | file bytes      | empty                | `X-Exit-Code` (0=ok), `X-Aap-Sum` |

Conventions ("the protocol"):

- **`/file/<abspath>`** maps directly to an absolute filesystem path on the
  target: `GET /file/usr/local/x` ⇒ the file `/usr/local/x`. Paths are
  URL-decoded (`%XX`, `+`).
- **`X-Exit-Code`** carries the shell exit status of `/exec`, or `0`/`1`
  success/failure for `/file` writes.
- **`X-Aap-Sum`** is the CRC-32 (IEEE 802.3, hex) of the file body, so the
  client can detect truncation/corruption. `auxctl` verifies it automatically.
- **`X-Aap-Token`** — optional shared-secret auth (see Security).

`/exec` runs the command via `sh -c "(cmd) 2>&1"`, capturing stdout and stderr
together, so a single response gives you the full output and the exit code.

## Repository layout

```
auxagent/
  src/
    aap.h, aap.c     protocol pure-logic (parsing, URL-decode, CRC-32) - no I/O
    auxagent.c       the HTTP server (sockets, dispatch, exec, file I/O)
  tests/
    test_aap.c       unit tests for aap.c (run on the host)
  client/
    auxctl           Mac-side client (curl + crc verify; also `admin` subcommand)
  admin/
    auxadmin         A/UX settings manager (runs on the target; extensible)
  install/
    bootstrap.sh     run on the A/UX target: fetch + compile + install service
    install.sh       install/refresh the boot service (inittab respawn) - idempotent
    uninstall.sh     remove the boot service
  Makefile           `make test` (host), `make agent-host` (compile check)
  README.md
```

The logic that's worth testing (HTTP parsing, header lookup, URL-decode, CRC)
lives in `aap.c` as pure functions with no platform dependencies, so it's unit-
tested on a modern host while the agent runs on A/UX.

## Build & test (on your Mac)

```sh
cd auxagent
make test          # builds tests/test_aap and runs the unit tests
```

Expected: `NN tests, 0 failures`.

## Build & run on A/UX

The agent binary is compiled **on the target** (m68k COFF). Given the three
source files on the box and the modern gcc:

```sh
/usr/local/gcc-2.7.2.3/gcc -B/usr/local/gcc-2.7.2.3/ \
    -o /usr/local/auxagent /usr/local/auxagent.c /usr/local/aap.c -lbsd
nohup /usr/local/auxagent 8377 > /usr/local/auxagent.log 2>&1 &
```

`install/bootstrap.sh` automates exactly this (fetching the sources via
`httpget` first).

## Bootstrapping (getting the agent onto a fresh box)

Chicken-and-egg: you need *some* channel to place the first files. Two cases:

**QEMU build guest (already has `httpget`):**
1. On the Mac, serve the sources: copy `src/aap.h src/aap.c src/auxagent.c` and
   `install/bootstrap.sh` into the dir served by `python3 -m http.server 8000`.
2. On the guest (one telnet session is enough), run:
   `httpget <MAC_IP> 8000 /bootstrap.sh /usr/local/bootstrap.sh && sh /usr/local/bootstrap.sh`
3. From then on, drive everything from the Mac with `auxctl` (no more telnet).

**The SE/30 (no `httpget` yet):** first get the ~50-line `httpget.c` onto it
(over its existing telnet via a `cat > httpget.c <<'EOF'` heredoc, or ftp),
compile it (`gcc -B... -o /usr/local/httpget httpget.c -lbsd`), then follow the
guest steps above. Alternatively, since A/UX m68k binaries are portable across
the 68030/68040, you can build `auxagent` once on the QEMU guest and copy the
**binary** to the SE/30 (see "Installing on the SE/30" below).

## Boot persistence (install as a service)

On A/UX, the agent is registered with `init` via an `/etc/inittab` **respawn**
entry. That does two things: it starts the agent at **every boot** (run level 2,
after networking comes up), and init **automatically restarts** it if it ever
exits or crashes. `bootstrap.sh` runs this for you; you can also run it directly:

```sh
sh install/install.sh [AGENT_PORT] [AAP_TOKEN]   # as root on the target
```

`install.sh` is **idempotent** and needs no reboot:

1. adds the inittab entry `ax:2:respawn:/usr/local/auxagent <port> >>...log 2>&1`
   (backing up `/etc/inittab` to `/etc/inittab.bak.auxagent` first; it skips the
   edit if an auxagent entry is already present),
2. kills any hand-launched instance so init owns the single canonical copy,
3. runs `telinit q` so init re-reads inittab and starts the agent immediately,
4. verifies exactly one instance is running.

The running agent ends up with **PPID 1 (init)**. To confirm respawn works:
`kill -9 <agent-pid>` and within a few seconds init relaunches it with a new pid.

Remove the service with `sh install/uninstall.sh` (strips the inittab line,
re-reads inittab, kills the running agent). The binary/source stay in place.

The agent sets `SO_REUSEADDR`, so the kill-and-restart in step 2/3 rebinds the
port cleanly even if a previous connection is still in `TIME_WAIT`.

## Installing on the SE/30

A/UX 68k binaries are portable across the 68030/68040, so the simplest path is
**build once on the QEMU guest, copy the binary to the SE/30, install the
service there** - no toolchain needed on the SE/30:

1. On the guest, build the binary (or reuse the one bootstrap.sh built):
   `/usr/local/auxagent`.
2. Copy three files to the SE/30's `/usr/local`: the `auxagent` **binary**,
   `install/install.sh`, and `install/uninstall.sh`. Use whatever channel you
   have to the SE/30 for this first copy (its existing telnet/ftp, or - if the
   guest agent can already reach the SE/30 - `auxctl put`). Once the agent is up
   on the SE/30 you never need telnet to it again.
3. On the SE/30, as root: `chmod +x /usr/local/auxagent install.sh && sh install.sh`
4. From the Mac: `curl http://10.1.1.214:8377/ping` (the SE/30's address).

If you prefer to compile on the SE/30 instead, install the gcc-2.7.2.3 toolchain
there and use `bootstrap.sh` exactly as on the guest.

## Client usage (`auxctl`, on the Mac)

```sh
export AAP_TOKEN=...                         # only if the agent requires one
client/auxctl ping 10.1.1.20:8377
client/auxctl exec 10.1.1.20:8377 "uname -a; ls /usr/local"
client/auxctl get  10.1.1.20:8377 /usr/local/xcb/xc/lib/X11/libX11.6.0_s ./libX11.6.0_s
client/auxctl put  10.1.1.20:8377 ./buildlib.sh /usr/local/buildlib.sh
```

`exec` exits with the remote command's exit code; `get`/`put` verify the CRC-32
and fail loudly on mismatch.

Or use `curl` directly:

```sh
curl -s -X POST --data-binary 'ls -l /usr/local' http://10.1.1.20:8377/exec -D -
curl -s http://10.1.1.20:8377/file/usr/local/x -o x
```

## Settings / administration (`auxadmin`)

Beyond raw exec/file, auxagent grows an **administration layer** for making
A/UX easier to manage remotely. The unit is a **setting**: a named piece of
host configuration with uniform `get`/`set` semantics, regardless of the messy
mechanism behind it (a Mac preference file, `/etc/inittab`, a text config...).

`admin/auxadmin` runs on the target (installed to `/usr/local/auxadmin`) and is
driven from the Mac with `auxctl admin`:

```sh
client/auxctl admin 10.1.1.20:8377 list                 # all settings + values
client/auxctl admin 10.1.1.20:8377 get  autologin
client/auxctl admin 10.1.1.20:8377 set  autologin off   # disable auto-login
client/auxctl admin 10.1.1.20:8377 set  autologin root  # auto-login as root
client/auxctl admin 10.1.1.20:8377 describe session
client/auxctl admin 10.1.1.20:8377 set  session mac32
```

Settings available today:

| Setting     | Values                | What it controls |
|-------------|-----------------------|------------------|
| `autologin` | `off` or `<username>` | Whether A/UX boots straight into a session or shows the **login window**. Backed by the Login pref `/mac/sys/Login System Folder/Preferences/Autologin`; `off` renames it to `Autologin.off` (reversible). |
| `session`   | `mac32`, `console`, `x11` | The default login **session type** stored in `/.aux_prefs` (`session type:<v>`). The login-window picker is authoritative; this reads/sets the stored default. |

**Adding a setting** (no recompile - it's shell): in `admin/auxadmin`, add a
`get_<name>()` function, an optional `set_<name>()` function, and one line to
`registry()`. That's the whole extension point.

Note: `auxadmin` is plain Bourne shell because A/UX's `/bin/sh` is ancient -
in particular it does **not** restore the caller's positional parameters after
a function call, so arguments are captured into named variables before any
function is invoked. Keep that constraint in mind when extending it.

## Security

`/exec` runs arbitrary commands as the user that launched the agent — normally
**root**. This is a deliberate lab tool for **your own A/UX machines on a
trusted LAN**, not something to expose to untrusted networks.

- Set `AAP_TOKEN` in the agent's environment to require a matching
  `X-Aap-Token` header on every request:
  `AAP_TOKEN=somesecret nohup /usr/local/auxagent 8377 ...`
- Bind to a specific interface if needed: `auxagent 8377 10.1.1.20`.
- There is no TLS (A/UX-era box); keep it on the local segment.

## Limitations

- One connection at a time (sequential accept loop) — fine for build
  automation; not a high-concurrency server.
- HTTP/1.0 only, no chunked encoding — every body is `Content-Length`-framed.
- A `READ_TIMEOUT` (default 180s) drops stuck connections so one bad client
  can't block the agent.
