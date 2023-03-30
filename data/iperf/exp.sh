
rm $1
RECEIVER_IP='172.31.7.156'
echo "Test results:" > $1
for i in {1..10}; do
  echo "Test $i" | tee -a $1
  iperf3 -c $RECEIVER_IP >> $1
done
