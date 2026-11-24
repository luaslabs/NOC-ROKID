<script def>
{
  "navigationBarTitleText": "LuasLink NOC",
  "description": "Overview of LuasLink event sites: which are offline or have a device offline. Swipe to move, tap to open. Say 'Hi Rokid' then a site name, a line (LUAS2) or 'bills'."
}
</script>

<script setup>
import wx from 'wx'
import { callTool, stateLabel, countText, understand, clock } from '../../lib/noc.js'

const ORDER = { offline: 0, degraded: 1, unknown: 2, online: 3, empty: 4 }

export default {
  data: {
    loading: true,
    error: '',
    heard: '',
    summary: '',
    observed: '',
    sites: [],
    allSites: [],
    selected: 0
  },

  onLoad() {
    this.load()
  },

  onShow() {
    this.timer = setInterval(() => this.load(), 60000)
  },

  onHide() {
    clearInterval(this.timer)
    if (this.recognition) this.recognition.abort()
  },

  onUnload() {
    clearInterval(this.timer)
  },

  async load() {
    try {
      const snap = await callTool('list_sites')
      const all = (snap.sites || []).slice().sort((a, b) => (ORDER[a.state] - ORDER[b.state]) || a.name.localeCompare(b.name))
      const bad = all.filter((s) => s.state === 'offline' || s.state === 'degraded')
      const rows = all.filter((s) => s.state !== 'empty').map((s) => ({
        name: s.name,
        state: stateLabel(s.state),
        warn: s.state === 'offline' || s.state === 'degraded',
        gw: countText(s.devices.gateways),
        ap: countText(s.devices.accessPoints),
        clients: s.clients == null ? '-' : String(s.clients)
      }))
      this.setData({
        loading: false,
        error: snap.error && !all.length ? snap.error : '',
        summary: bad.length ? bad.length + ' SITE PROBLEM' + (bad.length > 1 ? 'S' : '') : 'ALL SITES OK',
        observed: snap.observedAt ? 'updated ' + clock(snap.observedAt) + (snap.stale ? ' (old)' : '') : '',
        sites: rows,
        allSites: all.map((s) => ({ name: s.name }))
      })
    } catch (e) {
      this.setData({ loading: false, error: e.message || 'NOC unavailable' })
    }
  },

  // Temple controls: swipe moves the highlight, tap opens it. Row 0 is "Lines and bills".
  onKeyDown(event) {
    console.log('[luaslink] key ' + event.code)
  },

  onKeyUp(event) {
    const last = this.data.sites.length
    if (event.code === 'ArrowDown' || event.code === 'ArrowRight') {
      event.preventDefault()
      this.select(Math.min(last, this.data.selected + 1))
    } else if (event.code === 'ArrowUp' || event.code === 'ArrowLeft') {
      event.preventDefault()
      this.select(Math.max(0, this.data.selected - 1))
    } else if (event.code === 'Enter') {
      event.preventDefault()
      this.openSelected()
    }
  },

  select(index) {
    this.setData({ selected: index })
  },

  openSelected() {
    const i = this.data.selected
    if (i === 0) return this.openLines()
    const row = this.data.sites[i - 1]
    if (row) wx.navigateTo({ url: '/pages/site/index?name=' + encodeURIComponent(row.name) })
  },

  openSite(event) {
    const name = event.target.dataset.name
    if (name) wx.navigateTo({ url: '/pages/site/index?name=' + encodeURIComponent(name) })
  },

  openLines() {
    wx.navigateTo({ url: '/pages/lines/index' })
  },

  // "Hi Rokid" (or a temple-button wakeup) while this page is open: listen for a site, line or "bills".
  onVoiceWakeup(event) {
    event.preventDefault()
    this.listen()
  },

  listen() {
    if (this.recognition) this.recognition.abort()
    const recognition = new SpeechRecognition()
    recognition.lang = 'en-US'
    recognition.onresult = (event) => {
      const text = event.results[event.resultIndex][0].transcript
      this.act(text)
    }
    recognition.onerror = () => this.setData({ heard: 'Did not catch that' })
    this.recognition = recognition
    this.setData({ heard: 'Listening...' })
    try {
      recognition.start()
    } catch (e) {
      this.setData({ heard: 'Microphone not available' })
    }
  },

  act(text) {
    const intent = understand(text, this.data.allSites)
    this.setData({ heard: '"' + text + '"' })
    if (intent.kind === 'site') wx.navigateTo({ url: '/pages/site/index?name=' + encodeURIComponent(intent.site.name) })
    else if (intent.kind === 'line') wx.navigateTo({ url: '/pages/lines/index?line=' + intent.code })
    else if (intent.kind === 'lines') wx.navigateTo({ url: '/pages/lines/index' })
    else this.setData({ heard: '"' + text + '" - no match' })
  }
}
</script>

<page>
  <view class="screen">
    <view class="head">
      <text class="title">{{summary || 'LUASLINK NOC'}}</text>
      <text class="meta">{{observed}}</text>
    </view>

    <view ink:if="{{loading}}" class="note"><text>Loading sites...</text></view>
    <view ink:elif="{{error}}" class="note">
      <text>{{error}}</text>
      <button bindtap="load">Retry</button>
    </view>
    <scroll-view ink:else class="list" scroll-y="true" scroll-into-view="{{'row' + selected}}">
      <button id="row0" class="row link {{selected === 0 ? 'on' : ''}}" bindtap="openLines">
        <text class="name">LINES AND BILLS</text>
        <text class="state">where each LUAS line is, paid or not</text>
      </button>
      <button ink:for="{{sites}}" id="{{'row' + (index + 1)}}" class="row {{item.warn ? 'warn' : ''}} {{selected === index + 1 ? 'on' : ''}}" data-name="{{item.name}}" bindtap="openSite">
        <text class="name">{{item.warn ? '! ' : ''}}{{item.name}}</text>
        <text class="state">{{item.state}}  GW {{item.gw}}  AP {{item.ap}}  {{item.clients}} users</text>
      </button>
      <text ink:if="{{!sites.length}}" class="meta">No sites with devices.</text>
    </scroll-view>

    <text class="meta hint">{{heard || 'Swipe to move, tap to open. Hi Rokid + site or LUAS line.'}}</text>
  </view>
</page>

<style>
.screen { display: flex; flex-direction: column; padding: 12px 16px; height: 100%; }
.head { display: flex; flex-direction: row; justify-content: space-between; align-items: baseline; margin-bottom: 8px; }
.title { font-size: 18px; font-weight: 500; color: #40ff5e; letter-spacing: 0.04em; }
.meta { font-size: 11px; color: rgba(64,255,94,0.48); }
.note { display: flex; flex-direction: column; gap: 8px; font-size: 14px; color: rgba(64,255,94,0.72); }
.list { flex: 1; min-height: 0; }
.hint { margin-top: 4px; }
.link { border-style: dashed; }
.on { border-color: #40ff5e; border-width: 2px; background-color: rgba(64,255,94,0.16); }
.on .name { color: #40ff5e; font-weight: 500; }
.row { display: flex; flex-direction: column; align-items: flex-start; padding: 6px 8px; margin-bottom: 4px; border: 1px solid rgba(64,255,94,0.24); border-radius: 4px; background-color: #000000; text-align: left; }
.row:focus { border-color: #40ff5e; background-color: rgba(64,255,94,0.12); }
.warn { border-color: rgba(64,255,94,0.72); border-width: 2px; }
.name { font-size: 14px; color: rgba(64,255,94,0.72); }
.warn .name { color: #40ff5e; font-weight: 500; }
.state { font-family: monospace; font-size: 11px; color: rgba(64,255,94,0.48); }
.act { flex: 1; padding: 6px; font-size: 12px; color: rgba(64,255,94,0.72); border: 1px solid rgba(64,255,94,0.48); border-radius: 4px; background-color: #000000; }
.act:focus { color: #40ff5e; border-color: #40ff5e; background-color: rgba(64,255,94,0.12); }
</style>
