# claude-craft 🎧

> *"SCV good to go, sir."*

A tiny plugin marketplace for Claude Code. Right now it ships one thing:

### 🔊 claude-sfx

Turns your coding session into a StarCraft base. Claude gets to work and a SCV
pipes up — **"Roger."** on every prompt, **"Attack!"** before an edit, a
mournful **"Aaaaaugh."** when the session ends, and a triumphant **"Job's
finished!"** when it wraps. Errors get a very relatable **"This sucks."**

Cross-platform (macOS + Linux), zero required dependencies, and every clip is
shuffled so it never gets stale. Swap in your own sounds anytime.

## Install

In Claude Code, add this repo as a marketplace and install the plugin:

```
/plugin marketplace add /home/redcartel/code/ai/claude-craft
/plugin install claude-sfx@claude-craft
```

Once it's pushed to GitHub, others can grab it with:

```
/plugin marketplace add redcartel/claude-sfx
/plugin install claude-sfx@claude-craft
```

Restart your session and listen for the **"Ready."** 🫡

## Turn it down (or off)

```bash
SFX_DISABLE=1        # mute everything
SFX_VOLUME=30        # quieter (0–100)
SFX_OVERLAP_KILL=0   # let clips overlap instead of cutting off
```

**Silence one type of sound?** Just delete its clips from the `claude-sfx/sfx/`
directory. Clips are named `<category>_<label>.mp3`, so to mute, say, the
every-prompt chatter, nuke the `working_*` files:

```bash
rm claude-sfx/sfx/working_*.mp3   # no more "Roger." on every prompt
```

A category with no clips left simply plays nothing. Categories: `session-start`,
`session-end`, `working`, `run-command`, `edit-file`, `error`, `alert`,
`compact`, `done`.

Full docs, sound categories, and how to add your own clips live in
[`claude-sfx/README.md`](claude-sfx/README.md).

---

*Made with mineral patience and 8 supply. GLHF.*
