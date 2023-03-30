#!/bin/bash

RECEIVER_IP=$(kubectl get pod ground -o jsonpath='{.status.podIP}')
IFACE="eth0"  # Replace this with the appropriate network interface on the ground pod if necessary
DURATION=100  # Duration in seconds for each test

# Remove any existing .pcap files from the ground pod before starting the experiment
kubectl exec -it ground -- rm -f *.pcap

for i in {1..10}; do
    echo "Running experiment $i"

    # Start the video streaming on drone1
    kubectl exec -it drone1 -- ffmpeg -i input.mp4 -f mpegts udp://$RECEIVER_IP:4444 &
    sleep 5
    # Start tcpdump on ground and save the output to a file
    OUTPUT_FILE="tcpdump_output_$i.pcap"
    kubectl exec -it ground -- timeout $DURATION tcpdump -s 0 -i $IFACE -w $OUTPUT_FILE

    # Wait for the specified duration before stopping the ffmpeg process
    sleep $DURATION

    # Stop the video streaming on drone1
    kubectl exec -it drone1 -- pkill ffmpeg
    sleep 5  # Wait a few seconds before starting the next experiment
done

# Download the output files to the local machine
for i in {1..10}; do
    kubectl cp ground:tcpdump_output_$i.pcap tcpdump_output_$i.pcap
done

# Remove all .pcap files from the ground pod after downloading them to the local machine
kubectl exec -it ground --  rm -f *.pcap
