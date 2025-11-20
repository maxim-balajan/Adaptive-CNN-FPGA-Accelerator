import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.ticker import LogLocator, FuncFormatter, NullLocator

# Load CSV
df = pd.read_csv("hardware_performance_benchmarking.csv")
df.columns = df.columns.str.strip()

for col in ["HW_Fast_Mean", "HW_Fast_STD",
            "HW_Slow_Mean", "HW_Slow_STD",
            "SW_Mean", "SW_STD"]:
    df[col] = df[col].str.replace("us", "", regex=False).astype(float) / 1000.0  # -> ms

# Plot setup
methods = ["Faster Hardware\nConfiguration", "Slower Hardware\nConfiguration", "Software\n(x86-Architecture)"]
means = [df["HW_Fast_Mean"], df["HW_Slow_Mean"], df["SW_Mean"]]
stds  = [df["HW_Fast_STD"],  df["HW_Slow_STD"],  df["SW_STD"]]

plt.figure(figsize=(12, 7))
bar_height = 0.25
indices = np.arange(len(df))

colors = ["tab:blue", "tab:orange", "tab:green"]

for i, method in enumerate(methods):
    plt.barh(
        indices + i * bar_height,
        means[i],
        xerr=stds[i],
        height=bar_height,
        label=method,
        capsize=4,
        alpha=0.8,
        ecolor='black',
        linewidth=1.5 
    )

plt.yticks(indices + bar_height, df["Identifier"], fontsize=20)
plt.xlabel("Latency (ms)", fontsize=16)
plt.title("Hardware vs Software Latency Comparison\nof AlexNet Layers", fontsize=25)
plt.grid(axis="x", linestyle="--", alpha=0.4)
plt.legend(fontsize=20)

# --- Nonlinear log scale with plain-number labels ---
ax = plt.gca()
ax.set_xscale("log")

xmin = max(1e-3, df[["HW_Fast_Mean","HW_Slow_Mean","SW_Mean"]].min().min())
xmax = df[["HW_Fast_Mean","HW_Slow_Mean","SW_Mean"]].max().max()
base = 10.0
majors = LogLocator(base=base, numticks=12)
ax.xaxis.set_major_locator(majors)

def plain_number(x, pos):
    return format(x, "g")

ax.xaxis.set_major_formatter(FuncFormatter(plain_number))
ax.xaxis.set_minor_locator(NullLocator())
ax.tick_params(axis='x', which='major', labelsize=20)
ax.tick_params(axis='y', which='major', labelsize=20)

# Reverse y-axis order
ax.invert_yaxis()

plt.tight_layout()
plt.show()
