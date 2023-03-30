# Base image
FROM ubuntu:20.04

# Set noninteractive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# COPY sample_video.mp4 /sample_video.mp4Update repositories and install necessary tools
RUN apt-get update && \
    apt-get install -y \
    iperf3 \
    inetutils-ping \
    traceroute \
    mtr \
    ffmpeg \
    python3-pip \
    net-tools \
    curl \
    tcpdump \
    git

# Copy file
COPY input.mp4 /input.mp4

# Set entrypoint for the image
ENTRYPOINT ["sleep", "infinity"]

