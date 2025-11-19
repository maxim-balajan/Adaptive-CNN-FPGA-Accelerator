import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Read CSV (adjust filename as needed)
df = pd.read_csv("./hardware_ic_scale_benchemark.csv", header=None, names=["Index", "Mean", "STD"])

# Slice and clean data
df = df.iloc[256:280].copy()
df["Mean"] = df["Mean"].str.replace("us", "", regex=False).astype(float) / 1e3
df["STD"] = df["STD"].str.replace("us", "", regex=False).astype(float) / 1e3

# Plot
plt.figure()

# Plot mean line
plt.plot(df["Index"], df["Mean"], 'o-', label="Mean Latency (ms)")

# Shade ± STD
plt.fill_between(
    df["Index"],
    df["Mean"] - df["STD"],
    df["Mean"] + df["STD"],
    alpha=0.9,
    color="red",
    label="STD Latency (ms)"
)

# Set y-axis tick spacing and start point
y_min = 16.5
y_max = max(df["Mean"] + df["STD"])  # automatic upper bound
plt.yticks(np.arange(y_min, y_max + 0.01, 0.5))

plt.xlabel("Output Channel Size")
plt.ylabel("Mean Latency (ms)")
plt.title("Latency Variance for different Output Channel Sizes\n(Conv-3-3-8-256-k)")

plt.grid(True)
plt.legend()

plt.show()
