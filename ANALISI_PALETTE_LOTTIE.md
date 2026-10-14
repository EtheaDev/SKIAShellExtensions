# Lottie Text Editor: palette dei colori e allineamento dei fix

Analisi del 14 ottobre 2026.

Questo documento contiene due parti:

1. **Palette dei colori** per i file Lottie (`.json`), sotto l'editor, come quella dell'SVG Text Editor 3.5.0.
2. **Fix da riportare** da SVGShellExtensions (revisioni r177–r198). I due editor hanno la stessa base: SynEdit a sinistra, viewer a destra, stessa gestione di file, tab, impostazioni e aggiornamenti.

> **Progetto di riferimento: `D:\ETHEA\SVGShellExtensions`.**
> Ogni fix e la palette vanno presi da lì: unit, metodi e messaggi di commit SVN citati sotto.
> Per vedere ogni modifica nel dettaglio: `svn diff -c <rev>` nella cartella di SVGShellExtensions.
> Il codice di SkiaShellExtensions (r57, versione 1.7.1) è fermo allo stato di SVGShellExtensions r177.
> Nessuno dei fix della parte 2 è ancora presente: li ho verificati uno per uno nei sorgenti.

---

## Parte 1 – Palette dei colori per le animazioni Lottie

### 1.1 Funzioni (le stesse dell'SVG Text Editor)

- Pannello ridimensionabile sotto l'editor con i colori usati nel file e il numero di occorrenze di ciascuno.
- **Clic** su un colore: evidenzia tutte le occorrenze nel testo (indicatore SynEdit) e seleziona la prima.
  Alt+→ / Alt+← e le frecce nell'intestazione scorrono le occorrenze.
- **Cursore su un colore**: il campione corrispondente viene marcato e portato in vista.
- **Doppio clic**: sostituisce il colore sotto il cursore, mantenendo il formato originale.
- **Menu contestuale**:
  - sostituisci tutte le occorrenze, con un solo undo;
  - seleziona tutte le occorrenze (multi-caret);
  - copia il valore;
  - aggiungi o rimuovi dai colori personalizzati.
- **Colori personalizzati** con il pulsante "+" (TColorDialog), salvati subito in Settings.ini.
- Opzione nei Settings "Show color palette under the editor", attiva di default.

### 1.2 Come sono scritti i colori in un file Lottie

È la differenza sostanziale rispetto all'SVG. In Lottie un colore non è quasi mai una stringa: è un **array di numeri**, e il suo significato dipende dalla chiave e dal tipo dell'oggetto che lo contiene.

| Dove | Esempio | Note |
|---|---|---|
| Fill / stroke statici (`ty:"fl"`, `ty:"st"`) | `"c":{"a":0,"k":[0.937,0.231,0.192,1]}` | RGBA float 0..1; alpha spesso presente ma ignorato (l'opacità sta in `"o"`) |
| Fill / stroke animati | `"c":{"a":1,"k":[{"t":0,"s":[1,0,0,1]},{"t":30,"s":[0,0,1,1]}]}` | ogni keyframe `"s"` (e `"e"` nel formato Bodymovin vecchio) è un'occorrenza |
| Gradienti (`ty:"gf"`, `ty:"gs"`) | `"g":{"p":3,"k":{"a":0,"k":[0,1,0,0, 0.5,0,1,0, 1,0,0,1, 0,1, 1,0.5]}}` | `p` stop di 4 numeri (offset,r,g,b), poi eventuali coppie (offset,alpha). Ogni stop è un'occorrenza: solo i 3 numeri r,g,b, non l'offset |
| Solid layer (`ty:1`) | `"sc":"#ef3b31"` | **stringa hex**, l'unico caso "alla SVG" |
| Testo (`ty:5`) | `"t":{"d":{"k":[{"s":{"fc":[1,1,1],"sc":[0,0,0]}}]}}` | fill/stroke color del testo, RGB senza alpha |
| Effetti, color control (`ef`, `ty:2`) | `"v":{"a":0,"k":[0.2,0.4,0.6,1]}` | tint, fill, tritone, ecc. |
| Slot (spec Lottie recente) | `"slots":{"id":{"p":{"a":0,"k":[r,g,b,a]}}}` | colori parametrici condivisi |
| File vecchi | `[239,59,49,1]` | alcuni export usano 0..255: valori > 1 indicano la scala 255 |

Conseguenze per il riconoscimento:

- **Una regex da sola non basta.** `[1,0,0,1]` può essere un colore, una posizione, una scala o un bezier. Serve sapere sotto quale chiave e in quale oggetto si trova l'array. Inoltre i file esportati hanno le chiavi in ordine variabile (`"a"`, `"k"`, `"ix"`).
- **Il file è spesso minificato su una sola riga** di centinaia di KB. Le posizioni (Line/Char) sono tutte sulla riga 1. Indicatori e navigazione funzionano lo stesso, ma la scansione deve essere lineare e senza allocazioni inutili. Il comando *Format JSON* (`actnFormatJSON`) già presente rende il file leggibile.

### 1.3 Architettura proposta

| Unit | Origine | Lavoro |
|---|---|---|
| `uSVGPaletteBar.pas` → `uColorPaletteBar.pas` (o stesso nome) | **copia da SVGShellExtensions** | Nessuna modifica funzionale: il controllo dipende solo da VCL, non dallo scanner. Va copiato con il fix dello style hook registrato in `initialization` (r191) e con angoli arrotondati/contatori (r188, r189) |
| `uLottieColorScanner.pas` | **nuova**, stessa interfaccia di `uSVGColorScanner.pas` | `Scan`, `BuildPalette`, `IndexOfColor`, `OccurrenceAt`, `FormatColorLike`, `ColorToHex` + helper `AlphaColorToColor`, `ColorToAlphaColor`, `OpaqueColor`, `AlphaOf`. Le parti indipendenti dal formato (`BuildPalette`, `IndexOfColor`, `OccurrenceAt`, helper) si copiano quasi identiche |
| `EditorMainForm.pas/.dfm` | **porting da SVGShellExtensions** | PalettePanel, PaletteSplitter, header con titolo, frecce e info; azioni `acPalettePrev`/`acPaletteNext`; PalettePopupMenu, PaletteColorDialog; metodi `UpdateColorPalette`, `HighlightPaletteEntry`, `GotoPaletteOccurrence`, `UpdatePaletteCaret`, `ReplaceColorOccurrences`, `ExecutePaletteColorDialog`, gestione colori custom, `PALETTE_INDICATOR_ID` (**nuovo GUID**) |
| `uSettings.pas`, `SettingsForm.pas/.dfm` | porting | `ShowColorPalette`, `ColorPaletteHeight`, `CustomColors` + `WriteCustomColors` (sezione `[ColorPalette]`), checkbox nei Settings |

#### Lo scanner Lottie

Si consiglia un **tokenizer JSON minimale che tiene traccia delle posizioni** (opzione A). È un'unica passata sul testo e mantiene uno stack di contesto: per ogni oggetto la chiave corrente e i valori già visti di `ty` e `p`. Quando trova un array numerico in una posizione "colore", genera le occorrenze con offset e lunghezza esatti.

Posizioni colore da riconoscere:

- `c.k` (se `a=0`), `c.k[i].s` e `c.k[i].e` (se `a=1`), in oggetti con `ty` = `fl` o `st`;
- `g.k.k` e i keyframe animati, in oggetti con `ty` = `gf` o `gs`: stop di 4 numeri, occorrenza = r,g,b, limitata ai primi `p` stop;
- `sc` stringa nei layer (hex);
- `fc` e `sc` array dentro `t.d.k[i].s` (testo);
- `v.k` di un effetto color control (`ty:2` dentro `ef`);
- `slots.*.p.k`, quando l'array ha 3 o 4 numeri nel range colore.

| Opzione | Pro | Contro |
|---|---|---|
| **A. Tokenizer con posizioni (consigliata)** | Preciso, nessun falso positivo, gestisce animazioni e gradienti, lineare anche su file minificati | ~300–400 righe di codice nuovo |
| B. `System.JSON` (TJSONObject) + ricerca del testo | Riconoscimento semplice dal DOM | Il DOM non conserva le posizioni nel testo: ritrovarle è fragile con valori ripetuti |
| C. Regex su `"c":{...}` e simili | Più breve | Falsi positivi e negativi (ordine delle chiavi, `ix`, gradienti, keyframe), difficile da mantenere |

`TLottieColorOccurrence` mantiene i campi della versione SVG:

- Offset, Line, CharStart, CharEnd, RawText, Color, PropertyName;
- PropertyName mostra il contesto nell'hint: "fill", "stroke", "gradient stop 2", "text fill", "solid layer", "effect".

Il campo `Format` cambia in:

```pascal
TLottieColorFormat = (lcfFloatRGB, lcfFloatRGBA, lcfIntRGB, lcfIntRGBA, lcfHex, lcfGradientStop);
```

Va aggiunto anche `Decimals: Integer`, il numero di decimali usati nel testo originale.

#### Conservare il formato originale nella sostituzione (`FormatColorLike`)

- Array float: stesso numero di componenti (3 o 4), stessa precisione (`0.937254905701` → 12 decimali, `0.94` → 2) e **alpha originale invariato**.
- Separatori: si conserva lo spazio dopo la virgola se l'originale lo usa.
- Scala 0..255 (file vecchi): si riscrive in interi.
- Stop di gradiente: si sostituiscono solo i 3 numeri r,g,b; l'offset resta intatto.
- `sc` hex: `#rrggbb`, con lo stesso maiuscolo/minuscolo.
- Conversione: `round(v*255)` in lettura, `v/255` formattato con `FormatFloat` e `TFormatSettings.Invariant` in scrittura (punto decimale, mai virgola).
  Dopo la scrittura vanno tolti gli zeri finali, se l'originale non li aveva.

#### Raggruppamento

Si raggruppa per RGB a 8 bit ignorando l'alpha, come in SVG. Due float che danno lo stesso byte (`0.9372` e `0.93725`) finiscono nello stesso campione: è voluto, perché nell'animazione sono lo stesso colore.

#### Aggiornamento dell'anteprima

Dopo una sostituzione basta il normale ciclo di modifica: `SynEditChange` → render posticipato (debounce) → `SkAnimatedImageEx*.LottieText` → nuova scansione della palette.

**Prerequisito:** oggi il Lottie editor non ha il debounce. `SynEditChange` chiama `AssignLottieTextToImage` a ogni tasto, e ricarica 5 animazioni. Va prima portato il fix r178 sul debounce (vedi 2.2). La scansione della palette va agganciata allo stesso timer, come in `UpdateColorPalette` dell'SVG editor.

### 1.4 Decisioni da confermare

1. **Doppio clic con il cursore fuori da un colore.** In SVG inserisce `#RRGGBB`; in JSON un valore isolato non ha senso.
   - (a) consigliata: non fa nulla e mostra un messaggio nella status bar;
   - (b) inserisce `[r,g,b,1]` in float.
2. **Formato dei colori custom** nel menu "Copy value": hex `#RRGGBB` (consigliato, leggibile) oppure array float Lottie.
3. **File `.lottie` (dotLottie, zip) e `.tgs` (gzip)**: la palette è attiva solo sui file JSON testuali aperti nell'editor (consigliato). Gli altri formati non sono testo modificabile.
4. **Gradienti**: una voce per ogni stop (consigliato) oppure il gradiente come un'unica voce con più colori.
5. **Colori animati**: ogni keyframe conta come occorrenza (consigliato, così la sostituzione cambia tutta l'animazione) oppure solo il primo.
6. **Nome della unit della barra**: copiare `uSVGPaletteBar.pas` così com'è, oppure rinominarla (es. `uColorPaletteBar`, `TColorPaletteBar`) e in futuro usarla anche da SVGShellExtensions (unit condivisa).

### 1.5 Fasi (come per SVG, un commit per fase)

1. Prerequisiti: fix della parte 2, in particolare debounce del render e ClearUndo.
2. Scanner `uLottieColorScanner` + barra della palette in sola lettura + Settings (visibilità, altezza).
3. Clic → evidenziazione e navigazione Alt+←/→.
4. Cursore → marker sul campione.
5. Doppio clic, menu contestuale, sostituzione con un solo undo, colori custom.
6. README, immagine `ColorPalette.png`, versione, release notes.

Test: un piccolo progetto console con file Lottie di esempio, per verificare lo scanner e il round-trip di `FormatColorLike`:

- statico;
- animato;
- gradiente;
- testo;
- solid layer;
- formato 0..255;
- minificato su una riga.

Se non ci sono file di prova nel progetto, si possono scaricare da LottieFiles.

---

## Parte 2 – Fix da riportare da SVGShellExtensions (r177 → r198)

Per ogni punto: la revisione di SVGShellExtensions da cui prendere il codice, e cosa ho trovato oggi in SkiaShellExtensions.

### 2.1 Shell extension: thumbnail e anteprima (r178)

| # | Fix | Stato in SkiaShellExtensions | Dove |
|---|---|---|---|
| 1 | **Perdita di handle GDI e memoria nelle miniature.** Il TBitmap non viene mai liberato e il chiamante riceve `Handle`, non `ReleaseHandle`: a ogni miniatura resta un oggetto GDI in explorer.exe. Va usato `ReleaseHandle` + `LBitmap.Free` in try/finally; `bitmapType` va impostato prima dell'uscita anticipata | **Presente** (`hBitmap := LBitmap.Handle`, nessun Free) | `uSKIAThumbnailHandler.pas` GetThumbnail ← `uSVGThumbnailHandler.pas` |
| 2 | Lo sfondo anti-alias va riempito con `FillRect`: impostare `Brush.Color` non disegna nulla | Presente | idem |
| 3 | **Data module `dmResources` come istanza condivisa**, creata al primo uso, non creata e distrutta da ogni `TFrmPreview`. Con due handler nello stesso processo, uno poteva liberare il modulo usato dall'altro | **Presente** (`TFrmPreview.Create/Destroy`) | `PreviewForm.pas`, `DResources.pas` |
| 4 | Fallback ANSI nel caricamento del testo dell'anteprima | Da verificare: qui si usa `SynEdit.Lines.LoadFromStream(AStream)` senza encoding, diverso dall'SVG. Va provato con un JSON salvato in ANSI con caratteri accentati | `PreviewForm.pas` LoadFromStream |
| 5 | Log ridotto: niente sorgente intero a ogni miniatura | Da verificare in `TLogPreview.Add` del thumbnail e del preview handler | |

### 2.2 Lottie Text Editor: revisione sistematica (r178)

| # | Fix | Stato | Dove |
|---|---|---|---|
| 6 | **Render con debounce.** Il render avviene in un timer (Interval 400 ms) e viene saltato se il testo non è cambiato (campo `FRenderedSVGText`, qui `FRenderedLottieText`). Oggi ogni tasto ricarica 5 `TSkAnimatedImageEx` | **Presente** (`SynEditChange` → `AssignLottieTextToImage` diretto) | `EditorMainForm.pas`: `SynEditChange`, `LoadTimerTimer`, `AssignSVGToImage` |
| 7 | **Undo che svuota il file appena aperto (r181).** Il caricamento viene registrato come modifica annullabile: il primo Ctrl+Z svuota il documento, e un salvataggio subito dopo scrive un file vuoto. Serve `SynEditor.ClearUndo` dopo il try/except in `TEditingFile.LoadFromFile` | **Presente** | `TEditingFile.LoadFromFile` |
| 8 | Estensioni maiuscole (`.JSON`) non riconosciute; `Pos` accetta anche estensioni parziali. Va usata `IsFileNameWithExt` (uMisc) con `SameText` sull'estensione intera | **Presente** (`pos(ExtractFileExt(AFileName), AcceptedExtensions)`) | `EditorMainForm.pas:512`, `uMisc.pas` |
| 9 | `AddEditingFile`: nell'except `LEditor.Free` dopo `LTabSheet.Free` opera su memoria già liberata (il TabSheet è owner dell'editor) | **Presente** | `AddEditingFile` |
| 10 | `EditFileList.Add` va fatto dopo il try: la lista è owner degli oggetti. `OpenFile` con `LCreated`: un ricaricamento fallito non deve chiudere la scheda esistente. In `acNewFileExecute`, `SetFocus` va fuori dal try | **Presente** (`Result := EditFileList.Add(EditingFile)` prima del try) | `AddEditingFile`, `OpenFile`, `acNewFileExecute` |
| 11 | `ConfirmChanges` e `ModifiedCount` controllano `Assigned(SynEditor)` | **Presente** | |
| 12 | `LoadOpenedFiles` attiva la scheda dall'indice della lista salvata: con un file non più apribile attiva quella sbagliata. Va usata `PageControl.ActivePage` | **Presente** | `LoadOpenedFiles` |
| 13 | `RemoveEditingFile` indicizza `PageControl.Pages` con l'indice di `EditFileList`: deve usare `EditingFile.TabSheet`. Chiudendo la prima scheda non ne attiva nessuna | **Presente** | `RemoveEditingFile` |
| 14 | **Chiusura annullabile** con file modificati: `mbCancel` nel dialogo; `FormClose` intercetta `EAbort` e imposta `Action := caNone`. Oggi il ramo `mrCancel` esiste ma nessun pulsante lo restituisce | **Presente** (`[mbYes, mbNo]`) | `ConfirmChanges`, `FormClose` |
| 15 | `acSaveAll` non deve fermarsi al primo file non salvabile | **Presente** | `acSaveAllExecute` |
| 16 | `WMCopyData`: limite su `cbData` e nome troncato al primo `#0` | Parziale: controlla nil e 0, ma non limita la lunghezza e non cerca `#0` | `WMCopyData` |
| 17 | Rimosso `mbHelp` dal dialogo di errore (inerte, HelpFile vuoto) | **Presente** (riga 2156) | gestore eccezioni |
| 18 | Rimosso il distruttore vuoto di `TEditingFile`; `FFileAge` esposto come proprietà `FileTimestamp` | Presente | |

### 2.3 Gutter di SynEdit nei temi scuri (r178)

| # | Fix | Stato | Dove |
|---|---|---|---|
| 19 | Il gutter resta grigio chiaro con numeri neri negli stili scuri. Va portato `ApplyStyleToGutter` (fondo, bordo, gradiente, font da `StyleServices`), chiamato sul container delle opzioni e su ogni editor; va impostato anche `Font.Color` dell'editor | **Presente** (solo `Gutter.Font.Name/Size`) | `EditorMainForm.pas` → `ApplyStyleToGutter` (commento esteso nel sorgente SVG) |

### 2.4 Controllo versione, download e URL

| # | Fix | Rev | Stato | Dove |
|---|---|---|---|---|
| 20 | Il check versione all'avvio gira in background invece di bloccare l'interfaccia | r178 | **Presente** (sincrono in `FormShow`) | `EditorMainForm.pas`, `uAbout.pas` |
| 21 | **Access Violation nel download** subito dopo il check automatico: il client HTTP condiviso non viene creato; il download fallito non va ritentato in loop; gli `Assert` diventano controlli veri; la regex delle versioni accetta tag senza "v" (`^v?(\d+)...`) | r178 | **Presente** (`Assert` alle righe 177/227/235, regex `^v(\d+)`) | `GitHubAPI.pas` |
| 22 | **`IsTimeToCheckNewVersion` deve scrivere subito `VersionCheckTime`** nell'INI: i settings vengono riletti in molti punti (es. a ogni file aperto) e ripristinano la data vecchia prima del salvataggio in chiusura. Il check partirebbe a ogni avvio | r194 | **Presente** (aggiorna solo il campo) | `uSettings.pas` |
| 23 | Refuso "dowload" → "download" | r194 | **Presente** (`uAbout.pas:48`) | `uAbout.pas` |
| 24 | `HELP_URL` sul sito di documentazione, `GITHUB_URL` sul repository; la LinkLabel prende la didascalia da `HELP_URL` | r178, r196 | Oggi `HELP_URL` = GitHub. Da aggiornare se e quando ci sarà un sito di documentazione VitePress per SkiaShellExtensions | `uAbout.pas` |

### 2.5 Stili VCL (r192, r193)

| # | Fix | Stato | Dove |
|---|---|---|---|
| 25 | **`UpdateApplicationStyle` con fallback.** Con `TStyleManager.SetStyle` uno stile salvato e non più incluso solleva un'eccezione all'avvio. Va trasformata in funzione: `TrySetStyle(name, False)`, poi `DefaultStyleName` (chiaro/scuro come Windows), poi `'Windows Modern'`; lo stile applicato si salva nei settings | **Presente** (`EditorMainForm.pas:407`; alla riga 989 c'è già un `TrySetStyle` isolato) | `UpdateApplicationStyle` |
| 26 | Stili **Windows11 Modern Light** (`Windows11_Modern_Light.vsf`) e **Windows11 Modern Dark** (`Windows_Modern_Dark_SE.vsf`). Va rimosso "Windows Modern Dark": ha lo stesso nome di risorsa `WINDOWSMODERNDARK`. Da aggiornare in `InitDefaultThemesAttributes` / `DefaultStyleName` e nei `Custom_Styles` dei **4** dproj (LottieTextEditor, AnimationViewer, SKIAShellExtensions, SKIAShellExtensions32). Conviene farlo dall'IDE come per SVG | **Presente** (c'è ancora "Windows Modern Dark") | `.dproj`, `uSettings.pas` |
| 27 | Barra della palette: style hook registrato in `initialization` | r191 | Solo con la palette (parte 1) | `uSVGPaletteBar.pas` |

### 2.6 Codifica, build e setup

| # | Fix | Rev | Stato | Dove |
|---|---|---|---|---|
| 28 | `uAbout.pas`: il © in r178 era diventato U+FFFD. Oggi il file usa "(c)" e non ha BOM: nessun danno. Se si aggiungono caratteri non ASCII, salvare in UTF-8 **con BOM** | r190 | OK, solo attenzione | |
| 29 | **Build.bat**: controllo di `errorlevel` a ogni passo (oggi un msbuild fallito porta a firmare i binari vecchi e a creare il setup). Vanno aggiunti il rilevamento di Delphi, `/v:minimal`, `/p:DCC_Hints=false` e il `pause` solo se lanciato da Esplora Risorse | r182 | **Presente** | `Build.bat` ← modello di SVGShellExtensions / MarkDownHelpViewer |
| 30 | Setup: rimuovere `WindowVisible` (obsoleto) e usare `ArchitecturesInstallIn64BitMode=x64compatible` | r197 | **Presente** (righe 23 e 36) | `Setup/SKIAShellExtensions.iss` |
| 31 | **`sk4d.dll` installato solo con il componente ShellExtensions.** LottieTextEditor e AnimationViewer usano Skia: con un'installazione personalizzata senza le shell extension non partono. Servono `Components: ShellExtensions Editor Viewer` | r197 | **Presente** (righe 55 e 61) | `.iss` |
| 32 | `DCC_DebugInformation=true` non valido nella configurazione Debug | r178 | OK (valori numerici) | |
| 33 | `VerInfo_Release` e versione allineata in tutti i dproj | r178 | OK (1.7.1 ovunque) | |

### 2.7 Ordine consigliato

1. Shell extension: punti 1–3 (perdita GDI, data module condiviso). Sono i più gravi, perché agiscono dentro explorer.exe.
2. Editor: punti 7 (undo che svuota il file), 14 (chiusura annullabile), 9–13 (ciclo di vita delle schede), 6 (debounce, prerequisito della palette).
3. Aggiornamenti: punti 20–23.
4. Stili e gutter: punti 19, 25, 26.
5. Build e setup: punti 29–31.
6. Palette (parte 1).
7. Versione **1.8.0**, README e release notes.
