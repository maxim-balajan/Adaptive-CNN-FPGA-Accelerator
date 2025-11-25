import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.lines import Line2D
plt.rcParams['figure.dpi'] = 300

# Read CSV
df = pd.read_csv("./hardware_is_scale_benchmark.csv", header=None,
                 names=["Index", "Mean", "STD"], skiprows=1)

df = df.iloc[2:].copy()
df["Mean"] = df["Mean"].str.replace("us", "", regex=False).astype(float) / 1e3
df["STD"] = df["STD"].str.replace("us", "", regex=False).astype(float)

plt.figure()
ax = plt.gca()

# Plot mean line
plt.plot(df["Index"], df["Mean"], 'o-', label="Mean Latency (ms)")

plt.xlabel("Input Image Length")
plt.ylabel("Mean Latency (ms)")
plt.title("Latency Variance for different Input Image Length\n[Conv (3x3)]")
plt.grid(True)

max_std = df["STD"].max()

leg1_label = f"Max. Standard Deviation:\n≈{max_std:.2f} µs"

leg1 = ax.legend(
    handles=[Line2D([], [], color='none')],
    labels=[leg1_label],
    loc="lower right",
    frameon=True,
    handlelength=0,
    handletextpad=0
)

raw_params = {
    "Input Channel": 256,
    "Output Channel": 384,
    "Padding Size": 0,
    "Stride Length": 1
}

label_width = max(len(k) for k in raw_params.keys())
num_width   = max(len(str(v)) for v in raw_params.values())

formatted_params = [
    f"{key.ljust(label_width)} : {str(value).rjust(num_width)}"
    for key, value in raw_params.items()
]

handles = [Line2D([], [], color="none")] * len(formatted_params)

leg2 = ax.legend(
    handles,
    formatted_params,
    loc="upper left",
    frameon=True,
    handlelength=0,
    handletextpad=0,
    prop={"family": "DejaVu Sans Mono", "size": 10}
)

# Re-add the first legend (otherwise second replaces it)
ax.add_artist(leg1)

plt.show()
