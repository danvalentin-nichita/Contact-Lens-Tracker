import json

with open('ContactLensTracker/Localizable.xcstrings', 'r') as f:
    data = json.load(f)

# The strings we want to keep and translate
strings_in_code = [
    "%@ (%lld left)",
    "%lld Pair(s)",
    "%lld Pairs Remaining",
    "Add Contact Lenses",
    "Add Inventory",
    "Add Pairs",
    "Are you absolutely sure?",
    "Astigmatism",
    "Auto-Renew Pairs",
    "Bi-Weekly",
    "Cancel",
    "Choose Lens Type to Renew",
    "Close",
    "Custom",
    "Daily",
    "Danger Zone",
    "Days Left",
    "Details",
    "Done",
    "Edit",
    "Enter lens type",
    "Health",
    "Home",
    "Inventory",
    "L (OS)",
    "Lens Type",
    "Loading...",
    "Monthly",
    "Multifocal",
    "Next Checkup",
    "No Active\nLenses",
    "No inventory tracked yet.",
    "Not Set",
    "Nuke Database",
    "Nuke It All",
    "Preferences",
    "Prescription",
    "R (OD)",
    "Replace",
    "Replace Lenses",
    "Replace Lenses Early?",
    "Reset Current Pair Start Date",
    "Save",
    "Settings",
    "Start Lenses",
    "Theme",
    "This will delete all your settings, prescription data, and inventory. This cannot be undone.",
    "Type",
    "Unknown",
    "Warning: Pairs will be deducted automatically without confirmation when the duration expires.",
    "Your current pair is still good. Are you sure you want to replace it now?",
    "SPH", "BC", "DIA", "CYL", "AXIS", "ADD"
]

translations_it = {
    "%@ (%lld left)": "%1$@ (%2$lld rimaste)",
    "%lld Pair(s)": "%lld Paio/a",
    "%lld Pairs Remaining": "%lld Paia Rimaste",
    "Add Contact Lenses": "Aggiungi Lenti a Contatto",
    "Add Inventory": "Aggiungi Inventario",
    "Add Pairs": "Aggiungi Paia",
    "Are you absolutely sure?": "Sei assolutamente sicuro?",
    "Astigmatism": "Astigmatismo",
    "Auto-Renew Pairs": "Rinnovo Automatico",
    "Bi-Weekly": "Quindicinale",
    "Cancel": "Annulla",
    "Choose Lens Type to Renew": "Scegli il tipo di lente da rinnovare",
    "Close": "Chiudi",
    "Custom": "Personalizzato",
    "Daily": "Giornaliera",
    "Danger Zone": "Zona di Pericolo",
    "Days Left": "Giorni Rimasti",
    "Details": "Dettagli",
    "Done": "Fatto",
    "Edit": "Modifica",
    "Enter lens type": "Inserisci il tipo di lente",
    "Health": "Salute",
    "Home": "Home",
    "Inventory": "Inventario",
    "L (OS)": "S (OS)",
    "Lens Type": "Tipo di Lente",
    "Loading...": "Caricamento in corso...",
    "Monthly": "Mensile",
    "Multifocal": "Multifocale",
    "Next Checkup": "Prossimo Controllo",
    "No Active\nLenses": "Nessuna Lente\nAttiva",
    "No inventory tracked yet.": "Nessun inventario tracciato.",
    "Not Set": "Non Impostato",
    "Nuke Database": "Svuota Database",
    "Nuke It All": "Cancella Tutto",
    "Preferences": "Preferenze",
    "Prescription": "Prescrizione",
    "R (OD)": "D (OD)",
    "Replace": "Sostituisci",
    "Replace Lenses": "Sostituisci Lenti",
    "Replace Lenses Early?": "Sostituire le lenti prima?",
    "Reset Current Pair Start Date": "Ripristina Data di Inizio",
    "Save": "Salva",
    "Settings": "Impostazioni",
    "Start Lenses": "Inizia Lenti",
    "Theme": "Tema",
    "This will delete all your settings, prescription data, and inventory. This cannot be undone.": "Questo eliminerà tutte le tue impostazioni, dati di prescrizione e inventario. L'operazione non è reversibile.",
    "Type": "Tipo",
    "Unknown": "Sconosciuto",
    "Warning: Pairs will be deducted automatically without confirmation when the duration expires.": "Attenzione: le lenti verranno scalate automaticamente senza conferma allo scadere del tempo.",
    "Your current pair is still good. Are you sure you want to replace it now?": "Il tuo paio attuale è ancora buono. Sei sicuro di volerlo sostituire ora?",
    "SPH": "SFE",
    "BC": "CB",
    "DIA": "DIA",
    "CYL": "CIL",
    "AXIS": "ASSE",
    "ADD": "ADD"
}

# Clean strings dict
new_strings = {}

for key in strings_in_code:
    if key in data['strings']:
        val = data['strings'][key]
    else:
        val = {"localizations": {}}
        
    if "localizations" not in val:
        val["localizations"] = {}
        
    if "en" not in val["localizations"]:
        val["localizations"]["en"] = {"stringUnit": {"state": "translated", "value": key}}
        
    if "it" not in val["localizations"]:
        if key in translations_it:
            val["localizations"]["it"] = {"stringUnit": {"state": "translated", "value": translations_it[key]}}
    else:
        if key in translations_it:
            val["localizations"]["it"]["stringUnit"]["value"] = translations_it[key]
            val["localizations"]["it"]["stringUnit"]["state"] = "translated"
            
    # Remove extractionState if stale to make it clean
    if "extractionState" in val:
        del val["extractionState"]
        
    new_strings[key] = val

data['strings'] = new_strings

with open('ContactLensTracker/Localizable.xcstrings', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Updated Localizable.xcstrings")
