# scv-sounds 🎧

> *"SCV good to go, sir."*

A Claude Code plugin (and its own one-plugin marketplace) that turns your
coding session into a StarCraft base. Claude gets to work and a SCV
pipes up — **"Roger."** on every prompt, **"Attack!"** before an edit, a
mournful **"Aaaaaugh."** when the session ends, and a triumphant **"Job's
finished!"** when it wraps. Errors get a very relatable **"This sucks."**

Cross-platform (macOS + Linux), and every clip is shuffled so it never gets
stale. Swap in your own sounds anytime.

## Install

### Just for you (all your projects)

In Claude Code, add this repo as a marketplace and install the plugin:

```
/plugin marketplace add carterchadams/scv-sounds
/plugin install scv-sounds@scv-sounds
```

Hacking on a local clone? Point the marketplace at the checkout instead:
`/plugin marketplace add /path/to/scv-sounds`.

Restart your session and listen for the **"Ready."** 🫡

### For everyone on a project

Commit this to the project's `.claude/settings.json`. Teammates are prompted to
install the marketplace and plugin when they trust the folder:

```json
{
  "extraKnownMarketplaces": {
    "scv-sounds": {
      "source": { "source": "github", "repo": "carterchadams/scv-sounds" }
    }
  },
  "enabledPlugins": {
    "scv-sounds@scv-sounds": true
  }
}
```

### Requirements

- **macOS:** nothing — `afplay` is built in.
- **Linux:** the bundled clips are `.mp3`, which `paplay`/`aplay` can't decode,
  so you need one of `ffplay` (ffmpeg), `mpv`, or `play` (sox). Without one the
  plugin stays silent rather than erroring.

## Turn it down (or off)

```bash
SFX_DISABLE=1        # mute everything
SFX_VOLUME=30        # quieter (0–100)
SFX_OVERLAP_KILL=0   # let clips overlap instead of cutting off
```

**Silence one type of sound?** Just delete its clips from the `scv-sounds/sfx/`
directory. Clips are named `<category>_<label>.mp3`, so to mute, say, the
every-prompt chatter, nuke the `working_*` files:

```bash
rm scv-sounds/sfx/working_*.mp3   # no more "Roger." on every prompt
```

A category with no clips left simply plays nothing. Categories: `session-start`,
`session-end`, `working`, `run-command`, `edit-file`, `error`, `alert`,
`compact`, `done`, and `subagent` (subagent tool calls; ships empty, so
subagents are silent until you add `subagent_*` clips).

Full docs, sound categories, and how to add your own clips live in
[`scv-sounds/README.md`](scv-sounds/README.md).

---

*Made with mineral patience and 8 supply. GLHF.*
