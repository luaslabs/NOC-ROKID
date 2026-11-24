# LuasLink NOC for Rokid Glasses

An AIUI agent for Rokid Glasses (monochrome-green display). It reads from noc.luaslink.com and, with a separate Read + write token, runs a few spoken Omada commands after you tap to confirm.

## Pages

| Page | Shows |
|---|---|
| Overview | All sites, with problems first: OFFLINE / DEVICE OFF, gateway and AP counts, users. Refreshes every minute. |
| Site | Status, offline devices, the internet line there with its bill status, Wi-Fi SSIDs and networks/VLANs. |
| Lines and bills | Each LUAS line: where it is, since when, and its latest bill (PAID / UNPAID / OVERDUE). |

Temple: swipe to move, tap to open, double-tap to go back. Say **Hi Rokid**, then a site name ("KL Convex"), a line ("LUAS 2"), "bills", or a command:

| Say | Does (after a tap) |
|---|---|
| create site MAJLIS PETRONAS vlan 10 20 | New site with LuasLink defaults + VLAN 10, 20 |
| add vlan 30 to PDRM FUN RUN | VLAN 30 on that site |
| add SSID GUEST password 12345678 to KL CONVEX | Extra SSID (5+6 GHz) |
| DPI on for KL CONVEX | DPI + traffic logging on |

Malay works too ("buat site baru …", "tambah vlan 30 kat …"). Nothing changes until you tap on the confirmation screen; double-tap cancels.

## Set up

1. On noc.luaslink.com › Operators & connectors, create a **Read only** token "Rokid glasses" and, for commands, a **Read + write** token "Rokid glasses (write)". Revoke the write token at once if the glasses are lost.
2. Copy `config.example.js` to `config.js` and paste both tokens. `config.js` is git-ignored; never commit it.
3. Import into AIUI Studio Global (aiui-global.rokid.com) from GitHub, or upload the folder, then add `config.js` in Studio.
4. Device Debug tab → fill in name, category (Work) and intent → **Repackage and Save** → wait for the green "Debug version ready".
5. Hi Rokid app → Settings → Developer Options → AIUI → update the glasses resource pack.
6. On the glasses: "Rokid, open LuasLink NOC".

Do not submit this agent to the public Agent Store: it contains a NOC token.
