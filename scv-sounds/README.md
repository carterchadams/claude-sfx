# scv-sounds

A Claude Code plugin that plays shuffled sound effects as Claude works —
signalling startup, progress, alerts, errors, and completion. Cross-platform
across macOS and Linux; on Linux you need an mp3-capable player (see
[Players](#players-auto-detected-in-order)).

## How it works

Claude Code fires **hooks** on lifecycle events. Each hook runs `play.sh
<category>`, which picks a random clip from `sfx/` whose name starts with
`<category>_` and plays it in the background using whatever audio player the
OS has. The bundled clips are StarCraft SCV lines, but any audio works — swap
in whatever you like.

| Hook event         | Matcher            | Category        | Fires when                                    |
|--------------------|--------------------|-----------------|-----------------------------------------------|
| `SessionStart`     | —                  | `session-start` | A session begins                              |
| `SessionEnd`       | —                  | `session-end`   | A session ends                                |
| `UserPromptSubmit` | —                  | `working`       | You submit a prompt                           |
| `PreToolUse`       | `Bash`             | `run-command`   | Before a shell command runs                   |
| `PreToolUse`       | `Edit\|Write\|…`   | `edit-file`     | Before a file edit/write                      |
| `PostToolUse`      | —                  | `error`         | A tool call appears to have failed (heuristic)|
| `Notification`     | —                  | `alert`         | Claude needs permission / is waiting on you   |
| `PreCompact`       | —                  | `compact`       | Before the context window is compacted        |
| `Stop`             | —                  | `done`          | Claude finishes its turn                       |

Subagents stay silent: hooks also fire for their tool calls, so `play.sh`
skips any event whose payload carries an `agent_id`. Only the main session
makes noise.

The two noisiest triggers are `working` (every prompt) and `run-command` /
`edit-file` (every tool action). By default each new clip cuts off the last
(`SFX_OVERLAP_KILL` is on), so rapid events stay tidy rather than piling into a
chord. Set `SFX_OVERLAP_KILL=0` to let them overlap, or remove a category's
clips to silence it.

## Adding sounds

Drop audio files into `sfx/`, named `<category>_<label>.<ext>`:

```
sfx/  ->  alert_Ping.mp3  alert_Ping_Again.mp3  working_Yep.mp3
```

Every clip whose name starts with `<category>_` is **shuffled** automatically
(uniform random) — no config needed. One clip = that clip every time. The
`<label>` part is free-form; it just keeps names unique and readable.

- **Use `.wav`** for maximum portability (`afplay`, `paplay`, `aplay` all
  handle it). `.ogg/.mp3/.aiff/.flac` work only where the chosen player
  supports them.
- Keep clips **short** (< 1s) so rapid events don't stack up.

## Disabling a category

**Delete its `<category>_*` clips from `sfx/`.** A category with no clips
plays nothing. To disable globally without editing anything, set
`SFX_DISABLE=1`.

## Env toggles

| Variable            | Effect                                                    |
|---------------------|-----------------------------------------------------------|
| `SFX_DISABLE=1`     | Mute everything.                                          |
| `SFX_OVERLAP_KILL`  | Stop any still-playing clip before the next (default **on**; set `=0` to allow overlap). |
| `SFX_VOLUME=<0-100>`| Override the per-category volume for one call.            |

## Volume

Volume is set per category near the top of `play.sh`. Defaults: **`alert` and
`done` at 80%**, everything else at **50%**. Edit the `case` block to retune, or
set `SFX_VOLUME` to override. Note: the `aplay` (ALSA) fallback has no per-clip
volume and always plays at 100% — every other player honors the setting.

## Players (auto-detected, in order)

`afplay` (macOS, built in) → `paplay` (PulseAudio/PipeWire) → `ffplay` → `mpv`
→ `play` (sox) → `aplay` (ALSA, wav only).

The bundled clips are `.mp3`, which only `afplay`, `ffplay`, `mpv` and `play`
can decode — `paplay`/`aplay` are skipped for mp3. macOS always has `afplay`;
on Linux install ffmpeg, mpv, or sox, or the plugin plays nothing.

## Error detection

`PostToolUse` has no universal "failed" flag — `on-posttooluse.sh` uses a
best-effort heuristic (jq if available, else grep) over `tool_response`. Tune
the keys/pattern in that script for the tools you care about.
