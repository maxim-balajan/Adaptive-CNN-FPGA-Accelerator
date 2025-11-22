import pandas as pd
import matplotlib.pyplot as plt
plt.rcParams['figure.dpi'] = 300

# Define correct column names (first column is CS)
cols = ["CS", "LUTs", "FFs", "BRAM", "DSPs", "Frequency"]

# Load CSV files, skip first row, assign headers manually
cs_df = pd.read_csv("OOC_CS_benchmark.csv", skiprows=1, names=cols)
ks_df = pd.read_csv("OOC_KS_benchmark.csv", skiprows=1, names=cols)

# Create a figure with two subplots (1 row, 2 columns)
fig, axs = plt.subplots(1, 2, figsize=(12, 15))

# Left subplot — CS benchmark
axs[0].plot(cs_df["CS"], cs_df["Frequency"], "o-")
axs[0].set_title("Maximum Frequency\nfor varying Channel Amount\n[Kernel Size ≙ 3]")
axs[0].set_xlabel("Channel Amount")
axs[0].set_ylabel("Frequency [MHz]")
axs[0].grid(True)

# Right subplot — KS benchmark
axs[1].plot(ks_df["CS"], ks_df["Frequency"], "o-")
axs[1].set_title("Maximum Frequency\nfor varying Kernel Size\n[Channel Amount ≙ 2]")
axs[1].set_xticks(range(1, 12, 2))
axs[1].set_xlabel("Kernel Size")
axs[1].grid(True)

#plt.tight_layout()
plt.grid(True)
plt.show()
