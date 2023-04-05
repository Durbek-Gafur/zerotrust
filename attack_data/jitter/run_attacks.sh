#!/bin/bash

# Remove all network policies
kubectl delete networkpolicies --all

# Run the experiment without network policies
./experiment.sh experiment_without_policies

# Apply network policies
kubectl apply -f ~/zerotrust/yaml/policy-extended.yaml

# Run the experiment with network policies
./experiment.sh experiment_with_policies
