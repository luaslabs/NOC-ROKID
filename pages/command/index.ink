<script def>
{
  "navigationBarTitleText": "Command",
  "description": "Confirms and runs one spoken NOC command (create site, add VLANs, add SSIDs, DPI). Nothing changes until the user taps.",
  "schema": {
    "data": {
      "type": "object",
      "properties": { "text": { "type": "string" } },
      "required": ["text"]
    }
  }
}
</script>

<script setup>
import { callTool, canWrite } from '../../lib/noc.js'
import { plan, describe, run, summarize } from '../../lib/command.js'

// step: thinking | confirm | running | done | error
export default {
  data: { heard: '', step: 'thinking', title: '', lines: [], message: '', hint: '' },

  onLoad(query) {
    const heard = decodeURIComponent((query && query.text) || '')
    this.setData({ heard })
    this.prepare(heard)
  },

  async prepare(heard) {
    if (!canWrite()) return this.fail('Commands need a Read + write token (writeToken in config.js).')
    try {
      const snap = await callTool('list_sites')
      const names = (snap.sites || []).map((s) => s.name)
      this.planned = await plan(heard, names)
      const view = describe(this.planned)
      this.setData({ step: 'confirm', title: view.title, lines: view.lines.map((t) => ({ t })), hint: 'Tap to do it. Double-tap to cancel.' })
    } catch (e) {
      this.fail(e.message || 'Could not prepare the command')
    }
  },

  fail(message) {
    this.setData({ step: 'error', message, hint: 'Double-tap to go back.' })
  },

  onKeyUp(event) {
    if (event.code !== 'Enter') return
    event.preventDefault()
    if (this.data.step === 'confirm') this.execute()
  },

  async execute() {
    this.setData({ step: 'running', hint: '' })
    try {
      const result = await run(this.planned)
      this.setData({ step: 'done', title: 'DONE', lines: summarize(this.planned, result).map((t) => ({ t })), hint: 'Double-tap to go back.' })
    } catch (e) {
      this.fail(e.message || 'NOC refused the command')
    }
  }
}
</script>

<page>
  <view class="screen">
    <text class="heard">"{{heard}}"</text>
    <text ink:if="{{step === 'thinking'}}" class="big">CHECKING...</text>
    <text ink:if="{{step === 'running'}}" class="big">WORKING...</text>
    <text ink:if="{{step === 'error'}}" class="big">NOT DONE</text>
    <text ink:if="{{step === 'error'}}" class="item">{{message}}</text>
    <text ink:if="{{step === 'confirm' || step === 'done'}}" class="big">{{title}}</text>
    <text ink:if="{{step === 'confirm' || step === 'done'}}" ink:for="{{lines}}" class="item">{{item.t}}</text>
    <text class="hint">{{hint}}</text>
  </view>
</page>

<style>
.screen { display: flex; flex-direction: column; padding: 12px 16px; height: 100%; }
.heard { font-size: 11px; color: rgba(64,255,94,0.48); margin-bottom: 6px; }
.big { font-size: 22px; font-weight: 500; color: #40ff5e; letter-spacing: 0.04em; margin-bottom: 6px; }
.item { font-size: 14px; color: rgba(64,255,94,0.72); }
.hint { margin-top: 10px; padding-top: 6px; border-top: 1px solid rgba(64,255,94,0.24); font-size: 12px; color: rgba(64,255,94,0.72); }
</style>
