#!/bin/bash

OUTPUT_FILE="ping_test_results.txt"
REMOTE_OUTPUT_FILE="/tmp/ping_test_results.txt"
NETWORK_POLICY_DIR="~/zerotrust/yaml/policy-extended.yaml"
                    #~/zerotrust/yaml/policy-extended.yaml
function run_test() {
  # Remove the output file if it exists locally
  if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
  fi

  # Remove the output file if it exists in the ground pod
  kubectl exec -it ground -- rm -f "$REMOTE_OUTPUT_FILE"

  for i in {1..10}; do
    echo "Test $i" | tee -a "$OUTPUT_FILE"

    # Start hping3 ICMP flood on drone3 to create interference
    kubectl exec -it drone3 -- hping3 --icmp --flood $RECEIVER_IP >/dev/null 2>&1 &
    pid_hping=$!

    # Perform ping test from ground to drone1
    kubectl exec -it ground -- sh -c "echo 'Test $i' >> $REMOTE_OUTPUT_FILE && ping -c 10 $RECEIVER_IP >> $REMOTE_OUTPUT_FILE"

    # Stop hping3 ICMP flood on drone3
    kubectl exec -it drone3 -- pkill hping3
    wait $pid_hping
  done

  # Download the output file from the ground pod
  kubectl cp ground:"$REMOTE_OUTPUT_FILE" "$OUTPUT_FILE"
}

# Get the receiver IP
RECEIVER_IP=$(kubectl get pod drone1 -o jsonpath='{.status.podIP}')

# Remove network policies
#kubectl delete networkpolicy --all

# Run tests without network policies


# Run tests with network policies
echo "Running tests with network policies"
run_test
mv "$OUTPUT_FILE" "ping_test_results_with_policies.txt"

# Remove network policies
kubectl delete networkpolicy --all

# Run tests without network policies
echo "Running tests without network policies"
run_test
mv "$OUTPUT_FILE" "ping_test_results_without_policies.txt"
