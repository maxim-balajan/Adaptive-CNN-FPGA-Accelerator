import pandas as pd
data = pd.read_csv("datatype_benchmark.csv",sep=";")
data.to_json("datatype_benchmark.json",orient="records")
