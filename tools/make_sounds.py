"""Generates the game's sound effects (assets/audio/*.wav).

Run:  python3 tools/make_sounds.py
All sounds are synthesized here, so there are no licensing concerns.
"""
import math
import struct
import wave
from pathlib import Path

import numpy as np

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def note(freq, dur, vol=0.5, attack=0.005, decay=6.0, harmonics=(1.0, 0.35, 0.12), drop=0.0):
    """A soft bell-like tone. [drop] slides the pitch down by that fraction."""
    t = np.arange(int(RATE * dur)) / RATE
    f = freq * (1 - drop * t / dur)
    phase = 2 * np.pi * np.cumsum(f) / RATE
    wave_ = sum(a * np.sin(phase * (i + 1)) for i, a in enumerate(harmonics))
    env = np.minimum(t / attack, 1) * np.exp(-decay * t)
    return vol * wave_ * env / sum(harmonics)


def seq(notes, gap):
    """Plays notes one after another, each starting [gap] seconds apart (overlapping)."""
    total = int(RATE * (gap * (len(notes) - 1) + max(len(n) / RATE for n in notes))) + 1
    out = np.zeros(total)
    for i, n in enumerate(notes):
        start = int(RATE * gap * i)
        out[start:start + len(n)] += n
    return out


def save(name, samples):
    samples = np.clip(samples, -1, 1)
    # Short fade-out so nothing clicks at the end.
    fade = min(len(samples), int(RATE * 0.01))
    samples[-fade:] *= np.linspace(1, 0, fade)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32000)) for s in samples))


C5, E5, G5, A5 = 523.25, 659.25, 783.99, 880.0
C6, E6, G6, C7 = 1046.5, 1318.5, 1568.0, 2093.0

# Placing a piece: short wooden "tock".
save("place", note(330, 0.09, vol=0.6, decay=45, harmonics=(1, 0.5, 0.2), drop=0.25))
# Tap on buttons.
save("tap", note(900, 0.04, vol=0.35, decay=90, harmonics=(1, 0.2)))
# Clearing a line: bright up-chime.
save("clear", seq([note(f, 0.35, vol=0.4, decay=9) for f in (C6, E6, G6)], 0.05))
# Combo: faster, higher sparkle.
save("combo", seq([note(f, 0.35, vol=0.38, decay=10) for f in (E6, G6, C7, G6 * 2)], 0.04))
# Classic game over: gentle falling notes.
save("game_over", seq([note(f, 0.6, vol=0.45, decay=4) for f in (G5, E5, C5)], 0.18))
# Level complete: little fanfare.
save("win", seq([note(f, 0.6, vol=0.42, decay=4.5) for f in (C5, E5, G5, C6)], 0.11)
     + np.pad(note(E6, 0.9, vol=0.25, decay=3), (int(RATE * 0.33), 0))[: int(RATE * (0.11 * 3 + 0.6)) + 1])
# Level failed: two soft low notes.
save("lose", seq([note(f, 0.55, vol=0.45, decay=5) for f in (A5 / 2, 392 / 2)], 0.22))

for f in sorted(OUT.glob("*.wav")):
    print(f.name, f.stat().st_size, "bytes")
