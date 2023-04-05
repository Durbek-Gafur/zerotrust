#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <filename_prefix>"
  exit 1
fi

PREFIX="$1"
RECEIVER_IP=$(kubectl get pod drone1 -o jsonpath='{.status.podIP}')
IFACE="eth0"  # Replace this with the appropriate network interface on the drone1 pod if necessary
DURATION=50  # Duration in seconds for each test
VIDEO_PORT=4444  # Port used by ffmpeg
HPING_PORT=5555  # Port used by hping3

# Remove any existing .pcap files from the drone1 pod before starting the experiment
kubectl exec  drone1 --  rm -f *.pcap

declare -a HPING_OPTIONS=("fast" "faster" "flood")

for opt in "${HPING_OPTIONS[@]}"; do
    for i in {1..3}; do
        echo "Running experiment with hping3 $opt, iteration $i"

        # Start the video streaming on ground
        kubectl exec  ground -- sh -c 'ffmpeg -i input.mp4 -f mpegts udp://'"$RECEIVER_IP"':'"$VIDEO_PORT"' >/dev/null 2>&1 &' &
        sleep 2

        # Start tcpdump on drone1 and save the output to a file
        OUTPUT_FILE="${PREFIX}_tcpdump_output_${opt}_${i}.pcap"
        kubectl exec  drone1 -- timeout $DURATION tcpdump -s 0 -i $IFACE "udp port $VIDEO_PORT" -w $OUTPUT_FILE &
        pid_tcpdump=$!
        sleep 10
        
        # Start hping3 on drone3 to send packets to drone1
        kubectl exec  drone3 -- hping3 "$(kubectl get pod drone1 -o jsonpath='{.status.podIP}')" --udp -p $HPING_PORT "--$opt" &>/dev/null &
        pid_hping3=$!

        # Wait for the specified duration before stopping the tcpdump process
        sleep $DURATION

        # Stop tcpdump on drone1
        kubectl exec  drone1 -- pkill tcpdump
        wait $pid_tcpdump

        # Stop the video streaming on ground
        kubectl exec  ground -- pkill ffmpeg

        # Stop hping3 on drone3
        kubectl exec  drone3 -- pkill hping3

        # Download the output file to the local machine
        kubectl cp drone1:$OUTPUT_FILE "${PREFIX}_tcpdump_output_${opt}_${i}.pcap"

        # Remove the output file from the drone1 pod
        kubectl exec  drone1 -- rm -f $OUTPUT_FILE

        # Sleep for 50 seconds before starting the next iteration
        sleep 50
    done
done
