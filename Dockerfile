FROM python:3.11-slim

# System dependencies — ffmpeg is required by file3_modulator
RUN apt-get update && apt-get install -y \
    ffmpeg \
    tesseract-ocr \
    tesseract-ocr-eng \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# HF Spaces runs as non-root user 1000
RUN useradd -m -u 1000 tarang
WORKDIR /app

# Install Python dependencies as root first
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY --chown=tarang:tarang . .

# Create storage directories with correct permissions
RUN mkdir -p storage/audio_cache storage/reports storage/analytics \
    storage/extracted storage/mcq \
    && chown -R tarang:tarang /app

# Switch to non-root user (HF requirement)
USER tarang

# HF Spaces MUST expose 7860
EXPOSE 7860

# Start bridge on port 7860
CMD ["uvicorn", "bridge:app", "--host", "0.0.0.0", "--port", "7860", \
     "--workers", "1", "--log-level", "info"]