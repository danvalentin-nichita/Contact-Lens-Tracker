import json

path = "/Users/dan/Documents/XCode Projects/ContactLensTracker/ContactLensTracker/ContactLensTracker/Localizable.xcstrings"

with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

for key, val in data.get("strings", {}).items():
    locs = val.get("localizations", {})
    for lang, ldata in locs.items():
        if "stringUnit" in ldata:
            if ldata["stringUnit"].get("state") == "translated" and ldata["stringUnit"].get("value") is None:
                ldata["stringUnit"]["state"] = "needs_work"
                ldata["stringUnit"]["value"] = ""

with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Fixed Localizable.xcstrings")
