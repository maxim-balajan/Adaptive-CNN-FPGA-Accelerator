import pandas as pd
import matplotlib.pyplot as plt
plt.rcParams['figure.dpi'] = 300

# Read CSV and enforce column names (now including DSPs)
df = pd.read_csv("OOC_KS_benchmark.csv", skiprows=0)
df.columns = ["KS", "LUTs", "FFs", "BRAM", "DSPs", "Frequency"]

# Clean + convert
df = df.apply(lambda col: col.astype(str).str.strip() if col.dtype == object else col)
df = df.apply(pd.to_numeric, errors="coerce")
df = df.dropna(subset=["KS", "LUTs", "FFs", "BRAM", "DSPs"]).reset_index(drop=True)

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(6, 2))
plt.subplots_adjust(wspace=0.55)

colors = plt.rcParams["axes.prop_cycle"].by_key()["color"]
color_luts = colors[0]
color_ffs  = colors[1]
color_bram = colors[2]
color_dsps = colors[3] if len(colors) > 3 else "black"

# =========================================================
# FIRST SUBPLOT: LUTs + FFs (two y-axes)
# =========================================================
# LUTs (primary y-axis)
line_luts, = ax1.plot(df["KS"], df["LUTs"], marker="o",
                      color=color_luts, label="LUTs")
ax1.set_ylabel("LUT Amount", color=color_luts)
ax1.tick_params(axis='y', labelcolor=color_luts)

# FFs (secondary y-axis)
ax1_ff = ax1.twinx()
line_ffs, = ax1_ff.plot(df["KS"], df["FFs"], marker="o",
                        color=color_ffs, label="FFs")
ax1_ff.set_ylabel("Flip-Flop Amount", color=color_ffs)
ax1_ff.tick_params(axis='y', labelcolor=color_ffs)

ax1.set_xticks(df["KS"])
ax1.set_xlabel("Kernel Size")
ax1.set_title("LUT and FF Amount\nfor varying Kernel Sizes")
ax1.grid(True, linestyle="--", linewidth=0.5)

ax1.legend(handles=[line_luts, line_ffs], loc="upper left")

# =========================================================
# SECOND SUBPLOT: BRAM + DSPs (two y-axes)
# =========================================================
# BRAM (primary)
line_bram, = ax2.plot(df["KS"], df["BRAM"], marker="o",
                      color=color_bram, label="BRAM")
ax2.set_ylabel("BRAM Amount", color=color_bram)
ax2.tick_params(axis='y', labelcolor=color_bram)

# DSPs (secondary)
ax2_dsp = ax2.twinx()
line_dsps, = ax2_dsp.plot(df["KS"], df["DSPs"], marker="o",
                          color=color_dsps, label="DSPs")
ax2_dsp.set_ylabel("DSP Amount", color=color_dsps)
ax2_dsp.set_yticks([0, 1, 2]);
ax2_dsp.tick_params(axis='y', labelcolor=color_dsps)

ax2.set_xticks(df["KS"])
ax2.set_xlabel("Kernel Size")
ax2.set_title("BRAM and DSP Amount\nfor varying Kernel Sizes")
ax2.grid(True, linestyle="--", linewidth=0.5)

ax2.legend(handles=[line_bram, line_dsps], loc="lower right")

plt.tight_layout()
plt.show()
