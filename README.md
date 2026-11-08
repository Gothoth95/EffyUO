# EffyUO

Client Ultima Online (Dust765/ClassicUO) per **UODreams** con assistant integrato
(macro Python stile ClassicAssist, hotkey, agenti, PvP) e possibilità di usare ClassicAssist come plugin.

## Installazione

1. Crea una cartella vuota, per esempio `C:\EffyUO`.
2. Scarica [`Aggiorna EffyUO.bat`](https://raw.githubusercontent.com/Gothoth95/EffyUO/main/updater/Aggiorna%20EffyUO.bat)
   (tasto destro → *Salva link con nome*) e mettilo in quella cartella.
3. Fai doppio clic su `Aggiorna EffyUO.bat`: scarica il client.
4. Serve il **.NET Desktop Runtime 10 (x64)**: <https://dotnet.microsoft.com/download/dotnet/10.0>
   (l'updater ti avvisa se manca).
5. Apri `settings.json` e controlla `ultimaonlinedirectory` (la cartella di Ultima Online Classic).

## Aggiornare

Doppio clic su `Aggiorna EffyUO.bat`: scarica **solo i file cambiati**.
Le tue impostazioni, i profili e le macro non vengono toccati.

## Avvio

- `Avvia - Assistant interno.bat` → client con l'assistant integrato (`-assist`, `-pyedit`).
- `Avvia - ClassicAssist.bat` → client con ClassicAssist come plugin: metti il percorso di
  `ClassicAssist.dll` in `settings.json` → `"plugins": ["C:\\...\\ClassicAssist.dll"]`.

## Struttura

- `client/` – i file del client (pubblicati così come sono, controllati con SHA256)
- `manifest.json` – elenco dei file con dimensione e hash, letto dall'updater
- `updater/` – `Aggiorna EffyUO.bat` e `updater.ps1`
- `tools/` – script per pubblicare una nuova versione (`publish.ps1`, `make-manifest.ps1/.py`)
