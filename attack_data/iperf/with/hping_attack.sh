#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <output_prefix>"
  exit 1
fi

OUTPUT_PREFIX="$1"

# Define array of hping3 options
declare -a HPING_OPTIONS=("fast" "faster" "flood")

# Start iperf3 server on ground
kubectl exec  ground -- iperf3 -s &> /dev/null &
pid_ground_server=$!

for opt in "${HPING_OPTIONS[@]}"; do
  # Remove the output file if it exists
  rm -f "${OUTPUT_PREFIX}_${opt}.txt"

  for i in {1..10}; do
    echo "Test $i" | tee -a "${OUTPUT_PREFIX}_${opt}.txt"

    # Test from drone1 to ground
    echo "drone1 to Ground (hping3 $opt)" | tee -a "${OUTPUT_PREFIX}_${opt}.txt"
    kubectl exec  drone1 -- iperf3 -c "$(kubectl get pod ground -o jsonpath='{.status.podIP}')" &>> "${OUTPUT_PREFIX}_${opt}.txt" &
    pid_ground=$!

    # Test from drone3 to drone1 to create congestion using hping3
    kubectl exec  drone3 -- hping3 "$(kubectl get pod drone1 -o jsonpath='{.status.podIP}')" -p 80 "--$opt" &>/dev/null &
    pid_drone1=$!

    # Wait for both tests to complete
    wait $pid_ground #$pid_drone1

    # Stop hping3 on drone3
    kubectl exec  drone3 -- pkill hping3

    # Sleep for 50 seconds between experiments
    sleep 50
  done
done

# Stop iperf3 server on ground
kubectl exec  ground -- pkill iperf3
wait $pid_ground_server
