
rm $1
RECEIVER_IP=$(kubectl get pod ground -o jsonpath='{.status.podIP}')
echo "Test results:" > $1
for i in {1..10}; do
  echo "Test $i" | tee -a $1
  kubectl exec -it drone1 -- iperf3 -c $RECEIVER_IP >> $1
done
