// Spoken commands that change the Omada controller through the NOC.
// A command is only planned here; the page shows it and runs it after a tap.
import { LanguageModel } from 'language-model'
import { callTool } from './noc.js'

const VLANS = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]

const SSID_ITEM = {
  type: 'object',
  properties: {
    name: { type: 'string', description: 'SSID name, max 32 characters' },
    password: { type: 'string', description: 'Wi-Fi password, 8-63 characters, exactly as spoken' },
    band24: { type: 'boolean', description: 'Also create a 2.4 GHz-only companion SSID' }
  },
  required: ['name', 'password']
}

const TOOLS = [
  {
    type: 'function',
    function: {
      name: 'create_omada_site',
      description: 'Create a new Omada site with LuasLink standard settings. Optional extra VLANs and up to 4 additional SSIDs.',
      parameters: {
        type: 'object',
        properties: {
          name: { type: 'string', description: 'New site name as spoken, e.g. MAJLIS PETRONAS' },
          vlans: { type: 'array', items: { type: 'integer', enum: VLANS } },
          additionalSsids: { type: 'array', maxItems: 4, items: SSID_ITEM }
        },
        required: ['name']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'add_site_vlans',
      description: 'Add VLANs (10, 20 ... 100) to an existing site.',
      parameters: {
        type: 'object',
        properties: { site: { type: 'string' }, vlans: { type: 'array', items: { type: 'integer', enum: VLANS } } },
        required: ['site', 'vlans']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'add_site_ssids',
      description: 'Add up to 4 Wi-Fi SSIDs to an existing site.',
      parameters: {
        type: 'object',
        properties: { site: { type: 'string' }, ssids: { type: 'array', maxItems: 4, items: SSID_ITEM } },
        required: ['site', 'ssids']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'set_site_dpi',
      description: 'Turn Deep Packet Inspection (and traffic logging) on or off for an existing site.',
      parameters: {
        type: 'object',
        properties: { site: { type: 'string' }, dpi: { type: 'boolean' } },
        required: ['site', 'dpi']
      }
    }
  }
]

const SYSTEM = 'You turn one spoken command (English or Malay) from a LuasLink network engineer into exactly one tool call. ' +
  'Malay hints: buat/cipta = create, tambah = add, hidupkan/on = on, matikan/tutup/off = off, dan = and. ' +
  'VLAN IDs are only 10, 20, 30 ... 100; "vlan sepuluh" = 10. ' +
  'For an existing site, use the closest name from this list exactly as written: '

const norm = (s) => String(s || '').toLowerCase().replace(/[^a-z0-9]/g, '')

const WORDS = { ten: 10, twenty: 20, thirty: 30, forty: 40, fifty: 50, sixty: 60, seventy: 70, eighty: 80, ninety: 90, hundred: 100,
  sepuluh: 10, duapuluh: 20, tigapuluh: 30, empatpuluh: 40, limapuluh: 50, enampuluh: 60, tujuhpuluh: 70, lapanpuluh: 80, sembilanpuluh: 90, seratus: 100 }

function vlanList(text) {
  const found = []
  const t = String(text || '').toLowerCase().replace(/(dua|tiga|empat|lima|enam|tujuh|lapan|sembilan)\s+puluh/g, '$1puluh')
  for (const m of t.match(/\d+|[a-z]+/g) || []) {
    const n = /^\d+$/.test(m) ? Number(m) : WORDS[m]
    if (VLANS.indexOf(n) >= 0 && found.indexOf(n) < 0) found.push(n)
  }
  return found.sort((a, b) => a - b)
}

/** Closest existing site name, or null. */
export function matchSite(spoken, siteNames) {
  const said = norm(spoken)
  if (!said) return null
  let best = null
  let bestScore = 0
  for (const name of siteNames || []) {
    const n = norm(name)
    let score = 0
    if (n === said) score = 1000
    else if (n.indexOf(said) >= 0 || said.indexOf(n) >= 0) score = Math.min(n.length, said.length) + 100
    else {
      const words = String(name).toLowerCase().split(/[^a-z0-9]+/).filter((w) => w.length >= 3)
      score = words.filter((w) => said.indexOf(w) >= 0).reduce((s, w) => s + w.length, 0)
    }
    if (score > bestScore) { bestScore = score; best = name }
  }
  return bestScore >= 3 ? best : null
}

/** Simple patterns, used when the language model is unavailable or returns nothing. */
export function parseQuick(text, siteNames) {
  const t = String(text || '').trim().replace(/[.?!]+$/, '')
  let m = t.match(/^(?:please\s+)?(?:create|buat|cipta|new)\s+(?:new\s+|baru\s+)?site\s+(?:baru\s+)?(.+?)(?:\s+(?:with|dengan))?(?:\s+vlans?\s+(.+))?$/i)
  if (m) return { tool: 'create_omada_site', args: { name: m[1].trim(), vlans: vlanList(m[2]) } }
  m = t.match(/^(?:add|tambah)\s+vlans?\s+(.+?)\s+(?:to|ke|untuk|for|dekat|kat)\s+(?:site\s+)?(.+)$/i)
  if (m) return { tool: 'add_site_vlans', args: { site: m[2].trim(), vlans: vlanList(m[1]) } }
  m = t.match(/^(?:(?:turn|set)\s+)?dpi\s+(on|off|hidup|mati|tutup)\s+(?:for\s+|untuk\s+|kat\s+|dekat\s+)?(?:site\s+)?(.+)$/i) ||
    t.match(/^(?:turn\s+)?(on|off|hidupkan|matikan|tutup)\s+dpi\s+(?:for\s+|untuk\s+|kat\s+|dekat\s+)?(?:site\s+)?(.+)$/i)
  if (m) return { tool: 'set_site_dpi', args: { site: m[2].trim(), dpi: /^(on|hidup)/i.test(m[1]) } }
  return null
}

/** Validate and tidy a planned call; throws with a short reason the glasses can show. */
export function check(plan, siteNames) {
  const a = Object.assign({}, plan.args || {})
  const clean = (list) => (list || []).map(Number).filter((n) => VLANS.indexOf(n) >= 0)
  const ssids = (list) => (list || []).slice(0, 4).map((s) => {
    const name = String(s.name || '').trim()
    const password = String(s.password || '').replace(/\s+/g, '')
    if (!name) throw new Error('SSID name missing')
    if (password.length < 8 || password.length > 63) throw new Error('Wi-Fi password for ' + name + ' must be 8-63 characters')
    return { name, password, band24: !!s.band24 }
  })
  if (plan.tool === 'create_omada_site') {
    const name = String(a.name || '').trim().toUpperCase().slice(0, 64)
    if (!name) throw new Error('Site name missing')
    const existing = (siteNames || []).find((n) => norm(n) === norm(name))
    if (existing) throw new Error('Site ' + existing + ' already exists')
    const args = { name }
    const vlans = clean(a.vlans)
    if (vlans.length) args.vlans = vlans
    const extra = ssids(a.additionalSsids)
    if (extra.length) args.additionalSsids = extra
    return { tool: plan.tool, args }
  }
  const site = matchSite(a.site, siteNames)
  if (!site) throw new Error('No site like "' + (a.site || '') + '"')
  if (plan.tool === 'add_site_vlans') {
    const vlans = clean(a.vlans)
    if (!vlans.length) throw new Error('Which VLANs? 10, 20 ... 100')
    return { tool: plan.tool, args: { site, vlans } }
  }
  if (plan.tool === 'add_site_ssids') {
    const list = ssids(a.ssids)
    if (!list.length) throw new Error('Which SSID?')
    return { tool: plan.tool, args: { site, ssids: list } }
  }
  if (plan.tool === 'set_site_dpi') {
    const on = a.dpi !== false
    return { tool: plan.tool, args: { site, dpi: on, loggingTraffic: on } }
  }
  throw new Error('Not an allowed command')
}

/** Lines to show on the confirmation screen. */
export function describe(plan) {
  const a = plan.args
  const ssidLines = (list) => (list || []).map((s) => 'SSID ' + s.name + ' / ' + s.password + (s.band24 ? ' (+2.4G)' : ''))
  if (plan.tool === 'create_omada_site') {
    return { title: 'CREATE SITE', lines: [a.name, a.vlans ? 'VLAN ' + a.vlans.join(', ') : 'No extra VLAN'].concat(ssidLines(a.additionalSsids), ['+ LUASLINK Wi-Fi, LAN 10.10.0.1/24, DPI']) }
  }
  if (plan.tool === 'add_site_vlans') return { title: 'ADD VLAN', lines: [a.site, 'VLAN ' + a.vlans.join(', ')] }
  if (plan.tool === 'add_site_ssids') return { title: 'ADD SSID', lines: [a.site].concat(ssidLines(a.ssids)) }
  return { title: a.dpi ? 'DPI ON' : 'DPI OFF', lines: [a.site] }
}

export async function plan(text, siteNames) {
  let modelError = null
  try {
    if ((await LanguageModel.availability()) === 'available') {
      const session = await LanguageModel.create({
        initialPrompts: [{ role: 'system', content: SYSTEM + (siteNames || []).join('; ') }],
        tools: TOOLS
      })
      let call = null
      session.addEventListener('toolcall', (event) => {
        if (call) return
        let args = event.arguments
        if (typeof args === 'string') { try { args = JSON.parse(args) } catch (e) { args = {} } }
        call = { tool: event.functionName, args: args || {} }
      })
      try {
        await session.prompt(String(text))
      } finally {
        session.destroy()
      }
      if (call) return check(call, siteNames)
    }
  } catch (e) {
    modelError = e
  }
  const quick = parseQuick(text, siteNames)
  if (quick) return check(quick, siteNames)
  if (modelError && /already exists|No site|password|VLAN|SSID/.test(modelError.message)) throw modelError
  throw new Error('Not understood. Try "create site NAME vlan 10 20" or "add vlan 30 to NAME".')
}

export async function run(planned) {
  return callTool(planned.tool, planned.args, true)
}

/** Short result lines for the glasses. */
export function summarize(planned, result) {
  const r = result || {}
  const lines = []
  const vlanLines = (list) => (list || []).map((v) => 'VLAN ' + v.vlan + ' ' + (v.result === 'failed' ? 'FAILED' + (v.error ? ': ' + v.error : '') : v.result))
  const ssidLines = (list) => (list || []).map((x) => (x.created ? 'SSID ' : 'SSID FAILED ') + x.name + ' ' + (x.bands || '') + (x.error ? ': ' + x.error : ''))
  if (planned.tool === 'create_omada_site') {
    lines.push('Site ' + (r.name || planned.args.name) + ' created')
    if (r.lan && r.lan.ok === false) lines.push('LAN not set: ' + (r.lan.error || 'see NOC'))
    if (r.dpi && r.dpi.pending) lines.push('DPI on once a gateway is adopted')
    return lines.concat(vlanLines(r.vlans), ssidLines(r.ssids))
  }
  if (planned.tool === 'add_site_vlans') return vlanLines(r.vlans)
  if (planned.tool === 'add_site_ssids') return ssidLines(r.ssids)
  return [r.pending ? 'DPI queued until a gateway is adopted' : 'DPI ' + (r.dpi ? 'on' : 'off') + ' for ' + (r.site || planned.args.site)]
}
