rm $1
RECEIVER_IP=$(kubectl get pod ground -o jsonpath='{.status.podIP}')
echo "Ping Test Results:" > $1
for i in {1..10}; do
  echo "Test $i" | tee -a $1
  kubectl exec -it drone1 -- ping -c 10 $RECEIVER_IP >> $1
  echo "" >> $1
done
