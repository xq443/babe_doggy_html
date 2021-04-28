import json
import pandas as pd

with open('/Users/ConleyFKL/Desktop/ads_test/DPR_DogRuns_001.json', encoding='utf-8') as f:
    d = json.load(f)

results = []
for data in d:
    obj = dict()
    obj['Prop_ID'] = data['Prop_ID']
    obj['Name'] = data['Name']
    obj['Address'] = data['Address']
    obj['DogRuns_Type'] = data['DogRuns_Type']
    obj['Accessible'] = data['Accessible']
    obj['Notes'] = data['Notes']
    results.append(obj)
csv_df = pd.DataFrame(results)
csv_df.to_csv('/Users/ConleyFKL/Desktop/ads_test/Dogruns.csv')