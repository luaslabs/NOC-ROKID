// Calls read-only tools on the LuasLink NOC MCP endpoint (JSON-RPC over HTTPS).
import config from '../config.js'

let nextId = 1

/** Accepts either the bare token or the full connector URL (https://noc.luaslink.com/mcp/<token>). */
function endpoint(write) {
  const raw = String((write ? config.writeToken : config.token) || '').trim()
  if (!raw || raw.indexOf('PASTE') >= 0) {
    throw new Error(write ? 'Commands need a Read + write token (writeToken in config.js).' : 'No NOC token. Add a read-only token in config.js.')
  }
  const fromUrl = raw.match(/\/mcp\/([A-Za-z0-9_-]+)/)
  const token = fromUrl ? fromUrl[1] : raw
  const base = String(config.nocUrl || 'https://noc.luaslink.com').replace(/\/+$/, '')
  // Token in the path as well as the header: some proxies drop Authorization.
  return { url: base + '/mcp/' + token, token }
}

export function canWrite() {
  const raw = String(config.writeToken || '').trim()
  return !!raw && raw.indexOf('PASTE') < 0
}

export async function callTool(name, args = {}, write = false) {
  const target = endpoint(write)
  const response = await fetch(target.url, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'accept': 'application/json',
      'authorization': 'Bearer ' + target.token
    },
    body: JSON.stringify({ jsonrpc: '2.0', id: nextId++, method: 'tools/call', params: { name, arguments: args } })
  })
  if (response.status === 401) throw new Error('NOC token rejected. Check config.js.')
  if (!response.ok) throw new Error('NOC unavailable (' + response.status + ')')
  const body = await response.json()
  if (body.error) throw new Error(body.error.message || 'NOC error')
  const result = body.result || {}
  if (result.isError) {
    const text = (result.content && result.content[0] && result.content[0].text) || 'NOC error'
    throw new Error(text)
  }
  return result.structuredContent || {}
}

const STATE = {
  online: 'ONLINE',
  degraded: 'DEVICE OFF',
  offline: 'OFFLINE',
  empty: 'NO DEVICES',
  unknown: 'UNKNOWN'
}
export function stateLabel(state) {
  return STATE[state] || 'UNKNOWN'
}

export function countText(c) {
  return c && c.total ? c.online + '/' + c.total : '-'
}

export function rm(value) {
  return 'RM' + Number(value || 0).toFixed(2)
}

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
export function day(iso) {
  if (!iso) return '-'
  const [y, m, d] = String(iso).slice(0, 10).split('-').map(Number)
  return d + ' ' + MONTHS[m - 1]
}

export function billText(billing) {
  if (!billing || billing.status === 'none' || !billing.latestBill) return 'no bill yet'
  const b = billing.latestBill
  if (billing.status === 'paid') return 'PAID ' + rm(b.amountDue)
  if (billing.status === 'overdue') return 'OVERDUE ' + rm(billing.outstanding) + ' since ' + day(b.dueDate)
  if (billing.status === 'partial') return 'PART ' + rm(billing.outstanding) + ' left, due ' + day(b.dueDate)
  return 'UNPAID ' + rm(billing.outstanding) + ' due ' + day(b.dueDate)
}

const norm = (s) => String(s || '').toLowerCase().replace(/[^a-z0-9]/g, '')

/**
 * Work out what a spoken request asks for.
 * Returns { kind: 'lines' } | { kind: 'line', code } | { kind: 'site', site } | { kind: 'unknown' }.
 */
export function understand(text, sites) {
  const said = norm(text)
  if (!said) return { kind: 'unknown' }
  const line = said.match(/luas(\d{1,2})/)
  if (line) return { kind: 'line', code: 'LUAS' + line[1] }
  if (/bil|bill|unifi|line|talian/.test(said)) return { kind: 'lines' }
  let best = null
  let bestScore = 0
  for (const site of sites || []) {
    const name = norm(site.name)
    if (!name) continue
    let score = 0
    if (said.indexOf(name) >= 0) score = name.length + 100
    else if (name.indexOf(said) >= 0 && said.length >= 3) score = said.length + 50
    else {
      // Shared words, e.g. "convex" for "KL CONVEX HALL 5".
      const words = String(site.name).toLowerCase().split(/[^a-z0-9]+/).filter((w) => w.length >= 3)
      score = words.filter((w) => said.indexOf(w) >= 0).reduce((n, w) => n + w.length, 0)
    }
    if (score > bestScore) { bestScore = score; best = site }
  }
  return best && bestScore >= 3 ? { kind: 'site', site: best } : { kind: 'unknown' }
}

/** HH:MM in Malaysia time (UTC+8, no daylight saving). */
export function clock(iso) {
  const t = Date.parse(iso)
  if (!t) return ''
  const d = new Date(t + 8 * 3600000)
  const pad = (n) => (n < 10 ? '0' : '') + n
  return pad(d.getUTCHours()) + ':' + pad(d.getUTCMinutes())
}
