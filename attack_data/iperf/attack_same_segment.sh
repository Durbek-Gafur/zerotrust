#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <output_file>"
  exit 1
fi

OUTPUT_FILE="$1"

# Remove the output file if it exists
if [ -f "$OUTPUT_FILE" ]; then
  rm "$OUTPUT_FILE"
fi

RECEIVER_IP_GROUND=$(kubectl get pod ground -o jsonpath='{.status.podIP}')
RECEIVER_IP_drone4=$(kubectl get pod drone4 -o jsonpath='{.status.podIP}')

# Kill any instances of iperf3
kubectl exec -it drone4 -- pkill iperf3
kubectl exec -it drone3 -- pkill iperf3
kubectl exec -it ground -- pkill iperf3

echo "Test results:" > "$OUTPUT_FILE"
for i in {1..10}; do
  echo "Test $i" | tee -a "$OUTPUT_FILE"
  
  # Start iperf3 server on ground
  kubectl exec -it ground -- iperf3 -s &> /dev/null &
  pid_ground_server=$!

  # Start iperf3 server on drone4
  kubectl exec -it drone4 -- iperf3 -s &> /dev/null &
  pid_drone4_server=$!
  
  # Wait for servers to start
  sleep 2

  # Test from drone4 to ground
  echo "drone4 to Ground" | tee -a "$OUTPUT_FILE"
  kubectl exec -it drone4 -- iperf3 -c $RECEIVER_IP_GROUND &>> "$OUTPUT_FILE" &
  pid_ground=$!

  # Test from drone3 to drone4 to create congestion
  kubectl exec -it drone3 -- iperf3 -c $RECEIVER_IP_drone4 -P 128 -t 10 >/dev/null 2>&1 &
  pid_drone4=$!

  # Wait for both tests to complete
  wait $pid_ground
  wait $pid_drone4

  # Stop iperf3 server on ground
  kubectl exec -it ground -- pkill iperf3
  wait $pid_ground_server

  # Stop iperf3 server on drone4
  kubectl exec -it drone4 -- pkill iperf3
  wait $pid_drone4_server

  # Sleep for 50 seconds between experiments
  sleep 50
done
