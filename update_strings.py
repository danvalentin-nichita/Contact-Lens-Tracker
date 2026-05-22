import json

path = "/Users/dan/Documents/XCode Projects/ContactLensTracker/ContactLensTracker/ContactLensTracker/Localizable.xcstrings"

with open(path, 'r') as f:
    data = json.load(f)

new_keys = {
    "pairs_remaining": "%lld Pairs Remaining",
    "replace_lenses": "Replace Lenses",
    "start_lenses": "Start Lenses",
    "add_contact_lenses": "Add Contact Lenses",
    "in_inventory": "%lld in inventory",
    "days_left": "%lld days left",
    "start_accessory": "Start",
    "not_set": "Not Set",
    "Eye Drops": "Eye Drops",
    "Cleaner": "Cleaner",
    "Lens Case": "Lens Case"
}

for k, v in new_keys.items():
    if k not in data["strings"]:
        data["strings"][k] = {
            "localizations": {
                "en": {
                    "stringUnit": {
                        "state": "translated",
                        "value": v
                    }
                }
            }
        }

with open(path, 'w') as f:
    json.dump(data, f, indent=2)

print("Updated Localizable.xcstrings")
