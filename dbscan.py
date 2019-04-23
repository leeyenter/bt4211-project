import numpy as np
from sklearn.cluster import DBSCAN
import json, pickle
import pandas as pd
distances = np.load("/hpctmp/e0003561/bt4211-project/distances.npy")
eps = 0.475
print("Building model with eps =", eps)
clustering = DBSCAN(eps=eps, metric='precomputed', n_jobs=20).fit(distances)
#print("Saving model")
#clustering.save("/hpctmp/e0003561/bt4211-project/cluster_model")
#with open("/hpctmp/e0003561/bt4211-project/cluster_model", "wb") as f:
#    pickle.dump(clustering, f)
value_counts = pd.Series(clustering.labels_).value_counts()
print("No. of groups:", value_counts.shape)
print(value_counts)
#with open("/hpctmp/e0003561/bt4211-project/value_counts.json", "w") as f:
#    json.dump(json.loads(value_counts.to_json()), f)
