import pandas as pd
import matplotlib.pyplot as plt
plt.rcParams['figure.dpi'] = 300

# Read CSV and enforce column names
df = pd.read_csv("OOC_KS_benchmark.csv", skiprows=0)
df.columns = ["KS", "LUTs", "FFs", "BRAM", "DSPs", "Frequency"]

# Clean + convert
df = df.apply(lambda col: col.astype(str).str.strip() if col.dtype == object else col)
df = df.apply(pd.to_numeric, errors="coerce")
df = df.dropna(subset=["KS", "LUTs", "FFs", "BRAM", "DSPs"]).reset_index(drop=True)

# Explicit colors requested
color_luts  = 'tab:blue'
color_ffs   = 'tab:orange'
color_bram  = 'tab:green'
color_dsps  = 'tab:red'

fig, ax_left = plt.subplots(figsize=(6, 3))

# ===============================
# LEFT AXIS: LUTs + FFs (left axis)
# ===============================
line_luts, = ax_left.plot(df["KS"], df["LUTs"], marker="o",   # circle
                          color=color_luts, label="LUTs")
line_ffs,  = ax_left.plot(df["KS"], df["FFs"], marker="s",    # square
                          color=color_ffs, label="FFs")

ax_left.set_xlabel("Kernel Size")
ax_left.grid(True, linestyle="--", linewidth=0.5)

# X-axis ticks in steps of 2 from 1 to 16
ax_left.set_xticks(range(1, 17, 2))

# ===============================
# RIGHT AXIS: BRAM + DSPs (right axis)
# ===============================
ax_right = ax_left.twinx()

line_bram, = ax_right.plot(df["KS"], df["BRAM"], marker="^",   # triangle
                           color=color_bram, label="BRAM")
line_dsps, = ax_right.plot(df["KS"], df["DSPs"], marker="D",   # diamond
                           color=color_dsps, label="DSPs")

# remove the default single ylabels and add colored per-metric labels using offset points
ax_left.set_ylabel("")   # clear default
ax_right.set_ylabel("")

# ===============================
# Colored axis labels (no overlap)
# ===============================

# Vertical positions that won't overlap
y_lut  = 0.73
y_ff   = 0.25
y_bram = 0.78
y_dsp  = 0.25

# Left side labels: offsets to the left (negative x offset)
ax_left.annotate('LUT Amount', xy=(0, y_lut), xycoords='axes fraction',
                 xytext=(-55, 0), textcoords='offset points',
                 color=color_luts, rotation=90, va='center', ha='center',
                 fontsize=10, clip_on=False)

ax_left.annotate('FF Amount', xy=(0, y_ff), xycoords='axes fraction',
                 xytext=(-55, 0), textcoords='offset points',
                 color=color_ffs, rotation=90, va='center', ha='center',
                 fontsize=10, clip_on=False)

# Right side labels: offsets to the right (positive x offset)
ax_right.annotate('BRAM Amount', xy=(1, y_bram), xycoords='axes fraction',
                  xytext=(35, 0), textcoords='offset points',
                  color=color_bram, rotation=90, va='center', ha='center',
                  fontsize=10, clip_on=False)

ax_right.annotate('DSP Amount', xy=(1, y_dsp), xycoords='axes fraction',
                  xytext=(35, 0), textcoords='offset points',
                  color=color_dsps, rotation=90, va='center', ha='center',
                  fontsize=10, clip_on=False)

# Ensure tick labels remain readable (neutral color)
ax_left.tick_params(axis='y', labelcolor='black')
ax_right.tick_params(axis='y', labelcolor='black')
ax_right.set_yticks(range(0, 41, 10))

# ===============================
# Combined Legend (2x2)
# ===============================
lines = [line_luts, line_ffs, line_bram, line_dsps]
labels = [l.get_label() for l in lines]
plt.legend(lines, labels, loc="upper left", ncol=2)

plt.title("Resource Usage for Varying Kernel Size\n[Channel Amount ≙ 2]")
plt.tight_layout()
plt.show()
