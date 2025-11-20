import pandas as pd
import matplotlib.pyplot as plt
plt.rcParams['figure.dpi'] = 300

# Read CSV and force the desired column labels (works whether the file has a header or not)
df = pd.read_csv("OOC_KS_benchmark.csv", skiprows=0)
df.columns = ["KS", "LUTs", "FFs", "BRAM", "Frequency"]  # explicitly set/overwrite column labels

# Ensure numeric types (strip whitespace, convert)
df = df.apply(lambda col: col.astype(str).str.strip() if col.dtype == object else col)
df[["KS", "LUTs", "FFs", "BRAM", "Frequency"]] = df[["KS", "LUTs", "FFs", "BRAM", "Frequency"]].apply(pd.to_numeric, errors="coerce")

# Optionally drop rows with missing numeric values
df = df.dropna(subset=["KS", "LUTs", "FFs", "BRAM", "Frequency"]).reset_index(drop=True)

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(7, 3))  # wider figure
plt.tight_layout()
plt.subplots_adjust(wspace=0.35)  # extra space between subplots

# Save the default color cycle
colors = plt.rcParams["axes.prop_cycle"].by_key()["color"]

# Original intended mapping based on your old plot order:
color_luts = colors[0]
color_ffs  = colors[1]
color_bram = colors[2]

# Left subplot: LUTs, FFs, BRAM (y-axis fixed 0–100)
line_bram, = ax1.plot(df["KS"], df["BRAM"], marker="o",
                      color=color_bram, label="BRAM")
line_ffs,  = ax1.plot(df["KS"], df["FFs"],  marker="o",
                      color=color_ffs, label="FFs")
line_luts, = ax1.plot(df["KS"], df["LUTs"], marker="o",
                      color=color_luts, label="LUTs")

ax1.set_xticks(df["KS"])
ax1.set_xlabel("Kernel Size")
ax1.set_ylabel("Resource Usage (%)")
ax1.set_title("Normalized Resource Utilization\nfor varying Kernel Sizes")
ax1.set_ylim(0, 50)
ax1.grid(True)
ax1.legend(
    handles=[line_luts, line_ffs, line_bram],
    labels=["LUTs", "FFs", "BRAM"]
)

# Right subplot: Frequency (auto y-axis)
ax2.plot(df["KS"], df["Frequency"], marker="o", label="Frequency")

ax2.set_xticks(df["KS"])
ax2.set_xlabel("Kernel Size")
ax2.set_ylabel("Frequency (MHz)")
ax2.set_title("Highest achieved Frequencies\nfor varying Kernel Sizes")
ax2.grid(True)

plt.tight_layout()
plt.show()
