# LuasLink NOC for Rokid Glasses

An AIUI agent for Rokid Glasses (monochrome-green display). It is **read-only**: it reads from noc.luaslink.com and never changes sites, Wi-Fi or bills.

## Pages

| Page | Shows |
|---|---|
| Overview | All sites, with problems first: OFFLINE / DEVICE OFF, gateway and AP counts, users. Refreshes every minute. |
| Site | Status, offline devices, the internet line there with its bill status, Wi-Fi SSIDs and networks/VLANs. |
| Lines and bills | Each LUAS line: where it is, since when, and its latest bill (PAID / UNPAID / OVERDUE). |

Press **Speak** and say a site name ("KL Convex"), a line ("LUAS 2") or "bills".

## Set up

1. On noc.luaslink.com › Operators & connectors, create a new connector token with **Read only** access, labelled "Rokid glasses".
2. Copy `config.example.js` to `config.js` and paste that token. `config.js` is git-ignored; never commit it and never use a "Read + write" token.
3. Import into AIUI Studio Global (aiui-global.rokid.com) from GitHub, or upload the folder, then add `config.js` in Studio.
4. Device Debug tab → fill in name, category (Work) and intent → **Repackage and Save** → wait for the green "Debug version ready".
5. Hi Rokid app → Settings → Developer Options → AIUI → update the glasses resource pack.
6. On the glasses: "Rokid, open LuasLink NOC".

Do not submit this agent to the public Agent Store: it contains a NOC token.
