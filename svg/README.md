# SVAR filemanager “vivid” SVG set

These files are copied from the public SVAR CDN:

**Base URL:** `https://cdn.svar.dev/icons/filemanager/vivid/{small|big}/{name}.svg`

The **canonical list of `name`** values matches the bundled icon map (`let me = { … }`) in **`@svar-ui/react-filemanager`** (`dist/index.es.js`). That map lists every extension/type the library treats as having a dedicated CDN asset.

Also included:

- **`unknown.svg`** — used by the library as the fallback slug when an extension has no mapped icon (`st()` default template).

**Note:** At the CDN, **`multiple.svg`**, **`search.svg`**, and **`none.svg`** exist under **`big/`** but not **`small/`**. After a download run, **`download-svar-filemanager-icons.ps1`** copies those three from **`big/`** into **`small/`** so both folders stay complete.

Re-download:

```powershell
cd C:\dev\cdn-store
.\download-svar-filemanager-icons.ps1
```

## jsDelivr (GitHub-hosted)

If this repo is published as **`icebot411/cdn-store`** on GitHub, the React Files Manager uses:

`https://cdn.jsdelivr.net/gh/icebot411/cdn-store@main/svg/{small|big}/{name}.svg`

(e.g. `.../svg/small/folder.svg`.)

### jsDelivr 404 (“Couldn’t find … /svg/big/… )

jsDelivr serves **whatever is on GitHub**. If **`svg/small`** is committed but **`svg/big`** is empty or incomplete, **`/svg/big/pdf.svg`** fails while **`/svg/small/pdf.svg`** can still work.

1. Locally, run **`.\download-svar-filemanager-icons.ps1`** so **`svg/big`** and **`svg/small`** each contain **39** `*.svg` files (same basenames).
2. From your **`cdn-store`** clone:

   ```text
   git add svg/big svg/small
   git commit -m "Add svg/big filemanager icons (mirror SVAR vivid)"
   git push origin main
   ```

3. Retry: `https://cdn.jsdelivr.net/gh/icebot411/cdn-store@main/svg/big/pdf.svg`  
4. If you still see a stale 404 within a minute, purge the file on jsDelivr: `https://www.jsdelivr.com/?docs=purge-cache`

**Quick workaround (optional):** Create **`frontend/.env.local`** in **dve-core-react**:

```env
VITE_SVAR_FM_ICONS_VARIANT=small
```

(use **`svg/small/...`** for every row/card icon until **`svg/big`** is on GitHub; SVGs scale, art may differ slightly from SVAR “big”). Remove the env line once **`big`** is synced.

Respect SVAR / upstream licensing if you ship these assets; this folder is only a vendor mirror for offline or self-hosted icon serving.
