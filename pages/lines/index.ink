<script def>
{
  "navigationBarTitleText": "Lines and bills",
  "description": "Where each LuasLink Unifi line is now and whether its latest bill is paid."
}
</script>

<script setup>
import { callTool, billText, day } from '../../lib/noc.js'

const RANK = { overdue: 0, unpaid: 1, partial: 2, none: 3, paid: 4 }

export default {
  data: { loading: true, error: '', filter: '', summary: '', lines: [] },

  onLoad(query) {
    this.setData({ filter: (query && query.line) || '' })
    this.load()
  },

  async load() {
    this.setData({ loading: true, error: '' })
    try {
      const data = await callTool('list_lines', this.data.filter ? { line: this.data.filter } : {})
      const lines = (data.lines || []).slice().sort((a, b) =>
        (RANK[(a.billing || {}).status || 'none'] - RANK[(b.billing || {}).status || 'none']) || a.code.localeCompare(b.code))
      const owing = lines.filter((l) => l.billing && l.billing.outstanding > 0)
      const total = owing.reduce((n, l) => n + l.billing.outstanding, 0)
      this.setData({
        loading: false,
        summary: owing.length ? owing.length + ' UNPAID  RM' + total.toFixed(2) : 'ALL BILLS PAID',
        lines: lines.map((l) => ({
          code: l.code,
          where: (l.currentLocation || 'Store') + (l.since ? ' since ' + day(l.since) : ''),
          bill: billText(l.billing),
          warn: !!(l.billing && l.billing.outstanding > 0)
        }))
      })
    } catch (e) {
      this.setData({ loading: false, error: e.message || 'NOC unavailable' })
    }
  }
}
</script>

<page>
  <view class="screen">
    <text class="title">{{filter || summary || 'LINES'}}</text>
    <view ink:if="{{loading}}" class="note"><text>Loading lines...</text></view>
    <view ink:elif="{{error}}" class="note">
      <text>{{error}}</text>
      <button class="act" bindtap="load">Retry</button>
    </view>
    <scroll-view ink:else class="list" scroll-y="true">
      <view ink:for="{{lines}}" class="row {{item.warn ? 'warn' : ''}}">
        <text class="code">{{item.warn ? '! ' : ''}}{{item.code}}</text>
        <text class="where">{{item.where}}</text>
        <text class="bill">{{item.bill}}</text>
      </view>
      <text ink:if="{{!lines.length}}" class="note">No matching line.</text>
    </scroll-view>
  </view>
</page>

<style>
.screen { display: flex; flex-direction: column; padding: 12px 16px; height: 100%; }
.title { font-size: 18px; font-weight: 500; color: #40ff5e; letter-spacing: 0.04em; margin-bottom: 8px; }
.list { flex: 1; }
.row { display: flex; flex-direction: column; padding: 6px 8px; margin-bottom: 4px; border: 1px solid rgba(64,255,94,0.24); border-radius: 4px; }
.warn { border-color: rgba(64,255,94,0.72); border-width: 2px; }
.code { font-size: 14px; font-weight: 500; color: #40ff5e; }
.where { font-size: 12px; color: rgba(64,255,94,0.72); }
.bill { font-family: monospace; font-size: 11px; color: rgba(64,255,94,0.48); }
.warn .bill { color: rgba(64,255,94,0.72); }
.note { display: flex; flex-direction: column; gap: 8px; font-size: 14px; color: rgba(64,255,94,0.72); }
.act { padding: 6px; font-size: 12px; color: rgba(64,255,94,0.72); border: 1px solid rgba(64,255,94,0.48); border-radius: 4px; background-color: #000000; }
</style>
