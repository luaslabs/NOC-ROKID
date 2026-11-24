// Copy this file to config.js (in AIUI Studio: create config.js) and paste the
// tokens from noc.luaslink.com › Operators & connectors. Either the bare token
// or the full connector URL (…/mcp/<token>) works.
// Never commit config.js.
export default {
  nocUrl: 'https://noc.luaslink.com',
  // Read only: status pages.
  token: 'PASTE_READ_ONLY_TOKEN_HERE',
  // Read + write, labelled "Rokid glasses (write)": spoken commands
  // (create site, add VLANs / SSIDs, DPI). Leave as is to disable commands.
  writeToken: 'PASTE_WRITE_TOKEN_HERE'
}
