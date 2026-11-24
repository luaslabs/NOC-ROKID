<script def>
{
  "navigationBarTitleText": "Site",
  "description": "One LuasLink site: device status, offline devices, Wi-Fi SSIDs, LAN/VLANs and the internet line placed there.",
  "schema": {
    "data": {
      "type": "object",
      "properties": { "name": { "type": "string" } },
      "required": ["name"]
    }
  }
}
</script>

<script setup>
import { callTool, stateLabel, countText, billText } from '../../lib/noc.js'

export default {
  data: {
    name: '',
    loading: true,
    error: '',
    state: '',
    counts: '',
    clients: '',
    offline: [],
    ssids: [],
    networks: [],
    lines: [],
    dpi: ''
  },

  onLoad(query) {
    this.setData({ name: decodeURIComponent((query && query.name) || '') })
    this.load()
  },

  async load() {
    this.setData({ loading: true, error: '' })
    try {
      const [snap, lineData] = await Promise.all([
        callTool('list_sites', { site: this.data.name }),
        callTool('list_lines', { line: this.data.name }).catch(() => ({ lines: [] }))
      ])
      const sites = snap.sites || []
      const site = sites.find((s) => s.name === this.data.name) || sites[0]
      if (!site) throw new Error('No site named ' + this.data.name)
      const list = (site.devices && site.devices.list) || []
      this.setData({
        loading: false,
        name: site.name,
        state: stateLabel(site.state),
        counts: 'GW ' + countText(site.devices.gateways) + '  SW ' + countText(site.devices.switches) + '  AP ' + countText(site.devices.accessPoints),
        clients: site.clients == null ? '' : site.clients + ' users',
        dpi: site.pendingDpi ? 'DPI waiting for gateway' : '',
        offline: list.filter((d) => d.status === 'offline').map((d) => ({ text: d.name + ' (' + d.type + ')' })),
        ssids: (site.ssids || []).map((s) => ({ text: s.name + '  ' + (s.bands || '') })),
        networks: (site.networks || []).map((n) => ({ text: (n.vlan && n.vlan > 1 ? 'VLAN ' + n.vlan : n.name) + '  ' + (n.subnet || '') })),
        lines: (lineData.lines || []).map((l) => ({ text: l.code + '  ' + billText(l.billing) }))
      })
    } catch (e) {
      this.setData({ loading: false, error: e.message || 'NOC unavailable' })
    }
  }
}
</script>

<page>
  <view class="screen">
    <text class="title">{{name}}</text>
    <view ink:if="{{loading}}" class="note"><text>Loading...</text></view>
    <view ink:elif="{{error}}" class="note">
      <text>{{error}}</text>
      <button class="act" bindtap="load">Retry</button>
    </view>
    <scroll-view ink:else class="body" scroll-y="true">
      <text class="big">{{state}}</text>
      <text class="data">{{counts}}</text>
      <text ink:if="{{clients}}" class="data">{{clients}}</text>
      <text ink:if="{{dpi}}" class="meta">{{dpi}}</text>

      <text ink:if="{{offline.length}}" class="label">OFFLINE DEVICES</text>
      <text ink:for="{{offline}}" class="item">! {{item.text}}</text>

      <text ink:if="{{lines.length}}" class="label">INTERNET LINE</text>
      <text ink:for="{{lines}}" class="item">{{item.text}}</text>

      <text ink:if="{{ssids.length}}" class="label">WI-FI</text>
      <text ink:for="{{ssids}}" class="item">{{item.text}}</text>

      <text ink:if="{{networks.length}}" class="label">NETWORKS</text>
      <text ink:for="{{networks}}" class="item">{{item.text}}</text>
    </scroll-view>
  </view>
</page>

<style>
.screen { display: flex; flex-direction: column; padding: 12px 16px; height: 100%; }
.title { font-size: 16px; font-weight: 500; color: rgba(64,255,94,0.72); margin-bottom: 4px; }
.big { font-size: 22px; font-weight: 500; color: #40ff5e; letter-spacing: 0.04em; }
.body { flex: 1; }
.data { font-family: monospace; font-size: 13px; color: rgba(64,255,94,0.72); }
.label { font-size: 11px; font-weight: 500; letter-spacing: 0.08em; color: rgba(64,255,94,0.48); margin-top: 8px; padding-top: 4px; border-top: 1px solid rgba(64,255,94,0.24); }
.item { font-size: 13px; color: rgba(64,255,94,0.72); }
.meta { font-size: 11px; color: rgba(64,255,94,0.48); }
.note { display: flex; flex-direction: column; gap: 8px; font-size: 14px; color: rgba(64,255,94,0.72); }
.act { padding: 6px; font-size: 12px; color: rgba(64,255,94,0.72); border: 1px solid rgba(64,255,94,0.48); border-radius: 4px; background-color: #000000; }
.act:focus { color: #40ff5e; border-color: #40ff5e; }
</style>
