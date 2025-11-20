import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.lines import Line2D
plt.rcParams['figure.dpi'] = 300

# Read CSV
df = pd.read_csv("./hardware_oc_scale_benchmark.csv", header=None,
                 names=["Index", "Mean", "STD"], skiprows=1)

# Slice and clean data
df = df.iloc[256:290].copy()
df["Mean"] = df["Mean"].str.replace("us", "", regex=False).astype(float) / 1e3
df["STD"] = df["STD"].str.replace("us", "", regex=False).astype(float)

# Plot
plt.figure()
ax = plt.gca()

# Plot mean line
plt.plot(df["Index"], df["Mean"], 'o-', label="Mean Latency (ms)")

# Set y-axis tick spacing
y_min = 16.5
y_max = max(df["Mean"])
plt.yticks(np.arange(y_min, y_max + 0.01, 0.5))

plt.xlabel("Output Channel Size")
plt.ylabel("Mean Latency (ms)")
plt.title("Latency Variance for different Output Channel Sizes\n[Conv (3x3)]")
plt.grid(True)

# ───────────────────────────────────────────────
# FIRST LEGEND: Max STD, no indent
# ───────────────────────────────────────────────
max_std = df["STD"].max()
leg1_label = f"Maximum Standard Deviation:\n≈{max_std:.2f} µs"

leg1 = ax.legend(
    handles=[Line2D([], [], color='none')],
    labels=[leg1_label],
    loc="lower right",
    frameon=True,
    handlelength=0,
    handletextpad=0,
)

# ───────────────────────────────────────────────
# SECOND LEGEND: Parameter block (bottom-right, aligned)
# ───────────────────────────────────────────────
raw_params = {
    "Input Length": 13,
    "Input Channel": 256,
    "Padding Size": 1,
    "Stride Length": 1
}

label_width = max(len(k) for k in raw_params.keys())
num_width   = max(len(str(v)) for v in raw_params.values())

formatted_params = [
    f"{key.ljust(label_width)} : {str(value).rjust(num_width)}"
    for key, value in raw_params.items()
]

# Dummy handles (text-only legend)
handles = [Line2D([], [], color="none")] * len(formatted_params)

leg2 = ax.legend(
    handles,
    formatted_params,
    loc="upper left",
    frameon=True,
    handlelength=0,
    handletextpad=0,
    prop={"family": "DejaVu Sans Mono"}
)

# Re-add the first legend
ax.add_artist(leg1)

plt.show()
