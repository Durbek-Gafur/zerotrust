#!/bin/bash

rm $1
RECEIVER_IP_GROUND=$(kubectl get pod ground -o jsonpath='{.status.podIP}')
RECEIVER_IP_DRONE1=$(kubectl get pod drone1 -o jsonpath='{.status.podIP}')

echo "Test results:" > $1
for i in {1..10}; do
  echo "Test $i" | tee -a $1
  
  # Test from drone1 to ground
  echo "Drone1 to Ground" | tee -a $1
  kubectl exec -it drone1 -- iperf3 -c $RECEIVER_IP_GROUND &> temp_ground &
  pid_ground=$!

  # Test from drone3 to drone1 to create congestion
  kubectl exec -it drone3 -- iperf3 -c $RECEIVER_IP_DRONE1 -P 128 -t 10 >/dev/null 2>&1 &
  pid_drone1=$!

  # Wait for both tests to complete
  wait $pid_ground
  wait $pid_drone1

  # Append the results to the output file
  cat temp_ground >> $1

  # Sleep for 5 seconds between experiments
  sleep 5
done

# Remove temporary files
rm temp_ground
