#!/bin/bash

RECEIVER_IP=$(kubectl get pod ground -o jsonpath='{.status.podIP}')
DRONE1_IP=$(kubectl get pod drone1 -o jsonpath='{.status.podIP}')
IFACE="eth0"  # Replace this with the appropriate network interface on the ground pod if necessary
DURATION=60  # Duration in seconds for each test

# Remove any existing .pcap files from the ground pod before starting the experiment
kubectl exec -it ground --  rm -f *.pcap

# Stop the video streaming on drone1 and iperf server
kubectl exec -it drone1 -- pkill -f "ffmpeg\|iperf3"

# Stop the iperf client on drone3
kubectl exec -it drone3 -- pkill iperf3

for i in {1..10}; do
    echo "Running experiment $i"

    # Start iperf3 server on drone1
    kubectl exec -it drone1 -- iperf3 -s &

    # Start iperf3 client on drone3 with 128 parallel connections
    kubectl exec -it drone3 -- iperf3 -u -b 0 -c $DRONE1_IP -P 128 &

    # Start the video streaming on drone1
    kubectl exec -it drone1 -- ffmpeg -i input.mp4 -f mpegts udp://$RECEIVER_IP:4444 &
    sleep 5

    # Start tcpdump on ground and save the output to a file
    OUTPUT_FILE="tcpdump_output_$i.pcap"
    kubectl exec -it ground -- timeout $DURATION tcpdump -s 0 -i $IFACE -w $OUTPUT_FILE

    # Wait for the specified duration before stopping the ffmpeg and iperf processes
    sleep $DURATION

    # Stop the video streaming on drone1 and iperf server
    kubectl exec -it drone1 -- pkill -f "ffmpeg\|iperf3"

    # Stop the iperf client on drone3
    kubectl exec -it drone3 -- pkill iperf3

    

    # Download the output file to the local machine
    kubectl cp ground:$OUTPUT_FILE $OUTPUT_FILE

    # Remove the .pcap file from the ground pod after downloading it to the local machine
    kubectl exec -it ground --  rm -f $OUTPUT_FILE

    sleep 60
done
