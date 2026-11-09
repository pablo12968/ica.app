"""Generate short original UI tones; no external audio files or licenses."""
import math
import struct
import wave
from pathlib import Path

folder = Path(__file__).resolve().parents[1] / 'frontend/assets/sounds'
folder.mkdir(parents=True, exist_ok=True)
rate = 44100
for name, notes in {
    'tap': [(780, 0.045)],
    'add': [(660, 0.065), (990, 0.09)],
    'success': [(523.25, 0.10), (659.25, 0.10), (783.99, 0.18)],
}.items():
    samples = []
    for frequency, duration in notes:
        count = int(rate * duration)
        for i in range(count):
            t = i / rate
            envelope = min(1, t / .008) * max(0, 1 - t / duration) ** 2
            samples.append(int(11000 * envelope * math.sin(2 * math.pi * frequency * t)))
    with wave.open(str(folder / f'{name}.wav'), 'wb') as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(rate)
        sound.writeframes(struct.pack(f'<{len(samples)}h', *samples))
