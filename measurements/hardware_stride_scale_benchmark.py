import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.lines import Line2D

# Read CSV
df = pd.read_csv("./hardware_stride_scale_benchmark.csv", header=None,
                 names=["Index", "Mean", "STD"], skiprows=1)

# Clean data
df["Mean"] = df["Mean"].str.replace("us", "", regex=False).astype(float) / 1e3
df["STD"] = df["STD"].str.replace("us", "", regex=False).astype(float) / 1e3

# Plot
plt.figure()
ax = plt.gca()

# Plot mean line
line_mean, = ax.plot(df["Index"], df["Mean"], 'x-', label="Mean Latency (ms)")

# Shade ± STD
std_area = ax.fill_between(
    df["Index"],
    df["Mean"] - df["STD"],
    df["Mean"] + df["STD"],
    alpha=0.8,
    color="red",
    label="Standard Deviation (ms)"
)

plt.xlabel("Stride Length")
plt.ylabel("Mean Latency (ms)")
plt.title("Latency Variance for different Stride Lengths\n[Conv (3x3)]")
plt.grid(True)

# ───────────────────────────────────────────────
# FIRST LEGEND: classic (points + shaded area)
# ───────────────────────────────────────────────
leg1 = ax.legend(loc="upper left")

# ───────────────────────────────────────────────
# SECOND LEGEND: parameter block (bottom-right, aligned)
# ───────────────────────────────────────────────
raw_params = {
    "Input Length": 35,
    "Input Channel": 256,
    "Output Channel": 384,
    "Padding Size": 0,
    "Concurrent Channel": 8
}

label_width = max(len(k) for k in raw_params.keys())
num_width   = max(len(str(v)) for v in raw_params.values())

formatted_params = [
    f"{key.ljust(label_width)} : {str(value).rjust(num_width)}"
    for key, value in raw_params.items()
]

# Dummy handles for text-only legend
handles = [Line2D([], [], color="none")] * len(formatted_params)

leg2 = ax.legend(
    handles,
    formatted_params,
    loc="upper right",
    frameon=True,
    handlelength=0,
    handletextpad=0,
    prop={"family": "DejaVu Sans Mono", "size": 10}
)

# Re-add the first legend so both show
ax.add_artist(leg1)

plt.show()
