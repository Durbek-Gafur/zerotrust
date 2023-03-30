import re
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

def extract_throughput_values(filename):
    with open(filename, 'r') as file:
        content = file.read()
        regex = r'\d+\s+Mbits/sec'
        matches = re.findall(regex, content)
        throughput_values = [float(match.split()[0]) for match in matches]
        return throughput_values

throughput_without_microsegmentation = extract_throughput_values('output.txt')
throughput_with_microsegmentation = extract_throughput_values('output_c.txt')

df = pd.DataFrame({'Without Microsegmentation': throughput_without_microsegmentation,
                   'With Microsegmentation': throughput_with_microsegmentation})

sns.set(style='whitegrid')
plt.figure(figsize=(6, 6))
sns.boxplot(data=df)
plt.title('Iperf Throughput Comparison')
plt.savefig('iperf_comparison_boxplot.pdf')
