import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

from matplotlib.ticker import ScalarFormatter
from matplotlib.ticker import LogLocator, FuncFormatter
from matplotlib.ticker import NullLocator

# Load CSV
df = pd.read_csv("hardware_performance_benchmarking.csv")
df.columns = df.columns.str.strip()

for col in ["HW_Fast_Mean", "HW_Fast_STD",
            "HW_Slow_Mean", "HW_Slow_STD",
            "SW_Mean", "SW_STD"]:
    df[col] = df[col].str.replace("us", "", regex=False).astype(float) / 1000.0  # -> ms

# Plot setup
methods = ["Faster Hardware Configuration", "Slower Hardware Configuration", "Software (x86-Architecture)"]
means = [df["HW_Fast_Mean"], df["HW_Slow_Mean"], df["SW_Mean"]]
stds  = [df["HW_Fast_STD"],  df["HW_Slow_STD"],  df["SW_STD"]]

plt.figure(figsize=(10, 6))
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
        alpha=0.8
    )

plt.yticks(indices + bar_height, df["Identifier"])

plt.xlabel("Latency (ms)")
plt.title("Hardware vs Software Latency Comparison\nof AlexNet Layers")
plt.grid(axis="x", linestyle="--", alpha=0.4)
plt.legend()

# --- Nonlinear log scale with plain-number labels ---
ax = plt.gca()
ax.set_xscale("log")

# Major ticks at powers of 10 between min and max
xmin = max(1e-3, (df[["HW_Fast_Mean","HW_Slow_Mean","SW_Mean"]].min().min()))  # avoid zero
xmax = df[["HW_Fast_Mean","HW_Slow_Mean","SW_Mean"]].max().max()
base = 10.0
majors = LogLocator(base=base, numticks=12)   # major locator at 10^n
ax.xaxis.set_major_locator(majors)

# Formatter: plain numbers (no 10^x), use general format to avoid trailing zeros
def plain_number(x, pos):
    # when x is an exact power of 10 it will still show like '1000'
    # use :g to keep it short (switches to scientific only for extremely large/small)
    return format(x, "g")

ax.xaxis.set_major_formatter(FuncFormatter(plain_number))

# Optionally: set some nicer tick positions instead of strict powers of 10.
# If you prefer ticks like [10, 50, 100, 500, 1000, 5000, ...], you can define them manually:
# ticks = [10, 50, 100, 500, 1000, 5000, 10000]
# ax.set_xticks([t for t in ticks if t >= xmin and t <= xmax])
# ax.xaxis.set_major_formatter(FuncFormatter(lambda x, pos: format(x, "g")))

# Turn off minor tick labels (keeps minor ticks if you like)
ax.xaxis.set_minor_locator(NullLocator())
ax.tick_params(axis='x', which='major', labelsize=10)

# Reverse y-axis order
ax.invert_yaxis()

plt.tight_layout()
plt.show()