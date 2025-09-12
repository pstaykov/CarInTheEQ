import numpy as np
import sounddevice as sd
import pyqtgraph.opengl as gl
from PyQt5 import QtWidgets, QtCore
from PyQt5.QtWidgets import QFileDialog, QProgressBar, QPushButton
from pydub import AudioSegment
import sys, threading, json

# === Config ===
samplerate = 44100
blocksize = 1024
fft_size = 512
history = 100
num_bins = fft_size // 2
Z = np.zeros((history, num_bins))

x = np.linspace(0, samplerate / 2, num_bins)
y = np.linspace(0, history, history)

# === Qt App and GL View ===
app = QtWidgets.QApplication([])
window = QtWidgets.QMainWindow()
window.setWindowTitle("🎵 MP3 Visualizer")
window.setGeometry(100, 100, 1000, 600)

central_widget = QtWidgets.QWidget()
layout = QtWidgets.QVBoxLayout(central_widget)
window.setCentralWidget(central_widget)

# === Progress Bar ===
progress_bar = QProgressBar()
progress_bar.setRange(0, 1000)
progress_bar.setTextVisible(False)
layout.addWidget(progress_bar)

# === GL View ===
gl_widget = gl.GLViewWidget()
gl_widget.setBackgroundColor('k')
gl_widget.setCameraPosition(distance=150, elevation=30, azimuth=-135)
layout.addWidget(gl_widget)

# === Surface ===
surface = gl.GLSurfacePlotItem(
    x=x, y=y, z=Z.T,
    shader='heightColor',
    computeNormals=False,
    smooth=True
)
surface.scale(0.03, 1.0, 10.0)
surface.translate(-80, -50, 0)
gl_widget.addItem(surface)

# === Upload Button ===
btn = QPushButton("Upload MP3")
layout.addWidget(btn)

# === Playback State ===
stop_flag = False
total_samples = 1
playback_ptr = 0

# === Progress Timer ===
progress_timer = QtCore.QTimer()


def update_progress():
    if total_samples > 0:
        fraction = min(playback_ptr / total_samples, 1.0)
        progress_bar.setValue(int(fraction * 1000))


# === JSON export function ===
def audio_to_json(audio: np.ndarray, filename="spectrum.json",
                  samplerate=44100, fft_size=1024, bands=40,
                  max_freq=4000, step_ms=200):
    """Convert audio array into spectrum frames and save as JSON."""
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
            band_slice = spectrum[band_edges[i]:band_edges[i + 1]]
            band_vals.append(float(band_slice.mean()) if len(band_slice) > 0 else 0.0)
        frames.append(band_vals)

    data = {
        "samplerate": samplerate,
        "bands": bands,
        "step_ms": step_ms,
        "max_freq": max_freq,
        "frames": frames
    }

    with open(filename, "w") as f:
        json.dump(data, f)

    print(f"[✓] Saved {len(frames)} frames to {filename}")


# === Visualizer Thread ===
def run_visualizer(audio_data):
    global Z, stop_flag, playback_ptr, total_samples
    playback_ptr = 0
    total_samples = len(audio_data)
    chunk_size = blocksize

    while playback_ptr + chunk_size < total_samples and not stop_flag:
        chunk = audio_data[playback_ptr:playback_ptr + chunk_size]
        windowed = chunk * np.hanning(len(chunk))
        spectrum = np.abs(np.fft.rfft(windowed, n=fft_size))[:num_bins]
        spectrum = np.log1p(spectrum / (np.max(spectrum) + 1e-6))

        Z = np.roll(Z, -1, axis=0)
        Z[-1] = spectrum
        surface.setData(z=Z.T)

        playback_ptr += chunk_size
        sd.sleep(int(1000 * chunk_size / samplerate))

    progress_timer.stop()
    progress_bar.setValue(1000)


# === MP3 Upload Handler ===
def upload_mp3():
    global stop_flag, total_samples, playback_ptr
    stop_flag = True
    progress_timer.stop()
    progress_bar.setValue(0)

    filename, _ = QFileDialog.getOpenFileName(None, "Choose MP3", "", "Audio Files (*.mp3)")
    if not filename:
        return

    print(f"Loading {filename}...")
    song = AudioSegment.from_mp3(filename).set_channels(1).set_frame_rate(samplerate)
    audio = np.array(song.get_array_of_samples()).astype(np.float32) / (2 ** 15)

    # === JSON export here ===
    audio_to_json(audio, filename="spectrum.json")

    stop_flag = False
    thread = threading.Thread(target=run_visualizer, args=(audio,))
    thread.start()

    sd.play(audio, samplerate)
    progress_timer.start(100)


btn.clicked.connect(upload_mp3)
progress_timer.timeout.connect(update_progress)

# === Run App ===
window.show()
sys.exit(app.exec_())
