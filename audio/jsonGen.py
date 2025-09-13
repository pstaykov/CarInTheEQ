import numpy as np
import json
from pydub import AudioSegment
import os

def audio_to_json(
    mp3_file,
    filename=None,
    samplerate=44100,
    fft_size=1024,
    bands=80,          # try 40 or 80
    max_freq=4000,
    step_ms=200        # always 200ms for car sync
):
    # Load song
    song = AudioSegment.from_mp3(mp3_file).set_channels(1).set_frame_rate(samplerate)
    audio = np.array(song.get_array_of_samples()).astype(np.float32) / (2**15)

    step_size = int(samplerate * step_ms / 1000)
    freqs = np.fft.rfftfreq(fft_size, 1 / samplerate)
    valid_bins = freqs <= max_freq
    freqs = freqs[valid_bins]

    band_edges = np.linspace(0, len(freqs), bands + 1, dtype=int)
    frames = []

    for start in range(0, len(audio) - step_size, step_size):
        chunk = audio[start:start + step_size]
        windowed = chunk * np.hanning(len(chunk))
        spectrum = np.abs(np.fft.rfft(windowed, n=fft_size))[valid_bins]
        spectrum = np.log1p(spectrum)

        band_vals = []
        for i in range(bands):
            s = spectrum[band_edges[i]:band_edges[i+1]]
            band_vals.append(float(s.mean()) if s.size > 0 else 0.0)
        frames.append(band_vals)

    data = {
        "samplerate": samplerate,
        "bands": bands,
        "step_ms": step_ms,
        "max_freq": max_freq,
        "frames": frames
    }

    if filename is None:
        base = os.path.splitext(os.path.basename(mp3_file))[0]
        filename = os.path.join("json", base + ".json")

    # Ensure output folder exists
    os.makedirs(os.path.dirname(filename), exist_ok=True)

    with open(filename, "w") as f:
        json.dump(data, f)

    print(f"[✓] Saved {len(frames)} frames → {filename} (bands={bands}, step={step_ms}ms)")


if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    json_dir = os.path.join(current_dir, "json")
    os.makedirs(json_dir, exist_ok=True)

    # loop through all mp3s in current folder
    for file in os.listdir(current_dir):
        if file.lower().endswith(".mp3"):
            mp3_path = os.path.join(current_dir, file)
            audio_to_json(mp3_path, filename=os.path.join(json_dir, file.replace(".mp3", ".json")))
