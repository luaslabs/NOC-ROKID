# LuasLink NOC

Read-only heads-up view of LuasLink's event network and internet lines for the LuasLink team on site.

## What it does

- Shows which Omada sites are offline or have a device offline, with gateway / switch / access-point counts and clients.
- Shows one site's details: devices offline, Wi-Fi SSIDs, LAN / VLANs and which LuasLink internet line is there.
- Shows where each Unifi line (LUAS0–LUAS5) is now and whether its latest bill is paid.
- Answers short spoken requests such as "status KL Convex", "LUAS2" or "bills".
- With a separate Read + write token, runs spoken commands after a tap to confirm: create site, add VLANs, add SSIDs, DPI on/off.

## How to work

- Data comes only from the LuasLink NOC (noc.luaslink.com) with a read-only token. Never invent site, line or bill data.
- It changes nothing without a tap on the confirmation screen, and never touches bills, policy routing or QoS.
- If the NOC cannot be reached, say so and offer to retry.
- Keep text short for the glasses display.
