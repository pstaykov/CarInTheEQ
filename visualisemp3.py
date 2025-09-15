import numpy as np
import sounddevice as sd
import pyqtgraph.opengl as gl
from PyQt5 import QtWidgets, QtCore
from PyQt5.QtWidgets import QFileDialog, QProgressBar, QPushButton
from pydub import AudioSegment
import sys
import threading
import json

# === Config ===
samplerate = 44100
blocksize = 1024
fft_size = 512
full_bins = fft_size // 2
target_bins = 40
max_freq = 4000.0
history = 100
frame_interval = 0.8  # seconds between JSON frames

# frequency axis
freqs = np.linspace(0, samplerate / 2, full_bins)
cutoff_index = np.argmax(freqs > max_freq)  # index of first bin > 4000 Hz
if cutoff_index == 0:
    cutoff_index = full_bins  # fallback

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
Z = np.zeros((history, target_bins))
x = np.linspace(0, max_freq, target_bins)
y = np.linspace(0, history, history)

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
last_saved_time = 0.0
json_data = {"frames": [], "bands": target_bins}

# === Progress Timer ===
progress_timer = QtCore.QTimer()

def update_progress():
    if total_samples > 0:
        fraction = min(playback_ptr / total_samples, 1.0)
        progress_bar.setValue(int(fraction * 1000))

# === Helper: downsample FFT spectrum to 40 bins (0–4000 Hz) ===
def compress_spectrum(spectrum: np.ndarray) -> list:
    band_edges = np.linspace(0, cutoff_index, target_bins + 1, dtype=int)
    out = []
    for i in range(target_bins):
        start, end = band_edges[i], band_edges[i + 1]
        if end > start:
            out.append(float(np.mean(spectrum[start:end])))
        else:
            out.append(0.0)
    return out

# === Visualizer Thread ===
def run_visualizer(audio_data):
    global Z, stop_flag, playback_ptr, total_samples, last_saved_time, json_data
    playback_ptr = 0
    total_samples = len(audio_data)
    chunk_size = blocksize
    last_saved_time = 0.0
    json_data = {"frames": [], "bands": target_bins}

    while playback_ptr + chunk_size < total_samples and not stop_flag:
        chunk = audio_data[playback_ptr:playback_ptr + chunk_size]
        windowed = chunk * np.hanning(len(chunk))
        spectrum = np.abs(np.fft.rfft(windowed, n=fft_size))[:full_bins]
        spectrum = np.log1p(spectrum / (np.max(spectrum) + 1e-6))

        # compress to 40 bins, 0–4000 Hz
        spectrum40 = compress_spectrum(spectrum)

        # update visualization
        Z = np.roll(Z, -1, axis=0)
        Z[-1] = spectrum40
        surface.setData(z=Z.T)

        # save frame to JSON only every 0.8s
        current_time = playback_ptr / samplerate
        if current_time - last_saved_time >= frame_interval:
            json_data["frames"].append(spectrum40)
            last_saved_time = current_time

        playback_ptr += chunk_size
        sd.sleep(int(1000 * chunk_size / samplerate))

    # save JSON after playback
    with open("spectrum.json", "w") as f:
        json.dump(json_data, f)

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
