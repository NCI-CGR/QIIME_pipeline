



import qiime2
import pandas as pd
table = qiime2.Artifact.load('table.qza')
df = table.view(pd.DataFrame)
df.sum(axis=1)
df.sum(axis=1).median()
