const TEMPLATE = document.createElement('template');
TEMPLATE.innerHTML = `
<style>
:host{--as-accent:#3ee6a3;--as-bg:#08141b;--as-panel:#0d2029;--as-text:#effbff;--as-muted:#93aeba;--as-line:#29434e;--as-danger:#ff8e9c;font:14px/1.45 system-ui,-apple-system,"Segoe UI",sans-serif;color:var(--as-text)}
*{box-sizing:border-box}.launcher{position:fixed;z-index:2147483000;bottom:20px;width:58px;height:58px;border-radius:50%;border:0;background:var(--as-accent);color:#052117;font-weight:900;box-shadow:0 15px 45px #0008;cursor:pointer}.right{right:20px}.left{left:20px}.panel{position:fixed;z-index:2147483000;bottom:90px;width:min(390px,calc(100vw - 24px));height:min(650px,calc(100vh - 110px));display:none;grid-template-rows:auto 1fr auto;background:var(--as-bg);border:1px solid var(--as-line);border-radius:22px;overflow:hidden;box-shadow:0 24px 80px #000a}.panel.open{display:grid}.panel.right{right:20px}.panel.left{left:20px}.head{display:flex;justify-content:space-between;gap:12px;align-items:center;padding:14px 15px;border-bottom:1px solid var(--as-line);background:var(--as-panel)}.title{font-weight:850}.sub{display:block;color:var(--as-muted);font-size:11px}.iconbtn{border:1px solid var(--as-line);background:transparent;color:var(--as-text);border-radius:10px;padding:7px;cursor:pointer}.log{overflow:auto;padding:15px;display:grid;gap:11px;align-content:start;scroll-behavior:smooth}.message{max-width:84%;padding:11px 13px;border-radius:16px;white-space:pre-wrap;overflow-wrap:anywhere}.assistant{justify-self:start;background:var(--as-panel);border:1px solid var(--as-line)}.customer{justify-self:end;background:#14526a}.meta{display:block;color:var(--as-muted);font-size:10px;margin-top:6px}.sources{margin-top:8px;border-top:1px solid var(--as-line);padding-top:7px}.sources a{display:block;color:#7cdbff;font-size:11px;margin-top:4px}.status{min-height:20px;padding:0 15px;color:var(--as-muted);font-size:11px}.composer{display:grid;grid-template-columns:1fr auto;gap:8px;padding:10px;border-top:1px solid var(--as-line);background:var(--as-panel)}textarea{resize:none;min-height:48px;max-height:120px;border:1px solid var(--as-line);border-radius:13px;background:#061117;color:var(--as-text);padding:11px;font:inherit}.send{border:0;border-radius:13px;background:var(--as-accent);color:#042017;font-weight:850;padding:0 16px;cursor:pointer}.send:disabled{opacity:.55;cursor:not-allowed}.actions{display:flex;gap:7px;flex-wrap:wrap;margin-top:8px}.action{border:1px solid var(--as-line);background:transparent;color:var(--as-text);border-radius:999px;padding:6px 9px;font-size:11px;cursor:pointer}.error{color:var(--as-danger)}.sr{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0,0,0,0)}
@media(max-width:480px){.panel{bottom:0;left:0!important;right:0!important;width:100vw;height:100dvh;border-radius:0}.launcher{bottom:14px}.right{right:14px}.left{left:14px}}
@media(prefers-reduced-motion:reduce){.log{scroll-behavior:auto}}
</style>
<button class="launcher right" type="button" aria-haspopup="dialog" aria-expanded="false" aria-label="Open product support">ASK</button>
<section class="panel right" role="dialog" aria-modal="false" aria-labelledby="as-title">
  <header class="head"><div><span class="title" id="as-title">Product Support</span><span class="sub">AI-assisted · Human support available</span></div><button class="iconbtn close" type="button" aria-label="Close support">✕</button></header>
  <div class="log" role="log" aria-label="Support conversation" aria-live="off"></div>
  <div>
    <div class="status" role="status" aria-live="polite"></div>
    <form class="composer"><textarea aria-label="Message" placeholder="Ask about the product" maxlength="8000"></textarea><button class="send" type="submit">Send</button></form>
  </div>
</section>
<div class="sr completion" aria-live="polite"></div>`;

class AgenticSupport extends HTMLElement {
  static observedAttributes = ['title','position','theme','greeting'];

  constructor(){
    super();
    this.attachShadow({mode:'open'}).append(TEMPLATE.content.cloneNode(true));
    this.state={sessionToken:null,conversationId:null,busy:false};
    this.$=s=>this.shadowRoot.querySelector(s);
  }

  connectedCallback(){
    this.applyConfig();
    this.$('.launcher').addEventListener('click',()=>this.open());
    this.$('.close').addEventListener('click',()=>this.close());
    this.$('.composer').addEventListener('submit',e=>this.onSubmit(e));
    this.$('textarea').addEventListener('keydown',e=>{
      if(e.key==='Enter'&&!e.shiftKey){e.preventDefault();this.$('.composer').requestSubmit();}
      if(e.key==='Escape')this.close();
    });
    this.shadowRoot.addEventListener('click',e=>{
      const action=e.target.closest('[data-action]');
      if(action?.dataset.action==='handoff')this.requestHandoff();
    });
    this.addMessage('assistant',this.getAttribute('greeting')||'Hi. How can I help with the product?');
    window.addEventListener('keydown',this._esc=e=>{if(e.key==='Escape')this.close();});
  }

  disconnectedCallback(){ window.removeEventListener('keydown',this._esc); }
  attributeChangedCallback(){ if(this.isConnected)this.applyConfig(); }

  applyConfig(){
    const pos=this.getAttribute('position')==='left'?'left':'right';
    this.$('.launcher').className=`launcher ${pos}`;
    this.$('.panel').className=`panel ${pos}`;
    this.$('.title').textContent=this.getAttribute('title')||'Product Support';
    const theme=this.getAttribute('theme')||'dark';
    if(theme==='light'){
      this.style.setProperty('--as-bg','#f6fbfd');this.style.setProperty('--as-panel','#ffffff');this.style.setProperty('--as-text','#10232b');this.style.setProperty('--as-muted','#49636f');this.style.setProperty('--as-line','#cad9df');
    }
  }

  open(){
    this.$('.panel').classList.add('open');
    this.$('.launcher').setAttribute('aria-expanded','true');
    this.$('textarea').focus();
    this.dispatchEvent(new CustomEvent('agentic-support-open',{bubbles:true}));
  }

  close(){
    if(!this.$('.panel').classList.contains('open'))return;
    this.$('.panel').classList.remove('open');
    this.$('.launcher').setAttribute('aria-expanded','false');
    this.$('.launcher').focus();
  }

  setBusy(busy,text=''){ this.state.busy=busy;this.$('.send').disabled=busy;this.$('textarea').disabled=busy;this.$('.status').textContent=text; }

  addMessage(role,content,citations=[]){
    const el=document.createElement('article');
    el.className=`message ${role}`;
    const body=document.createElement('div');body.textContent=content;el.append(body);
    if(citations.length){
      const sources=document.createElement('div');sources.className='sources';
      citations.forEach(c=>{const a=document.createElement('a');a.textContent=c.title||'Source';a.href=c.uri||'#';a.target='_blank';a.rel='noreferrer';sources.append(a);});
      el.append(sources);
    }
    const meta=document.createElement('small');meta.className='meta';meta.textContent=role==='customer'?'You':'Support assistant';el.append(meta);
    this.$('.log').append(el);this.$('.log').scrollTop=this.$('.log').scrollHeight;
    if(role==='assistant'){this.$('.completion').textContent='Support response complete.';}
  }

  async ensureSession(){
    if(this.state.sessionToken)return;
    const api=this.getAttribute('api-base');
    const tenant=this.getAttribute('tenant');
    if(!api||!tenant)throw new Error('Widget is missing api-base or tenant configuration.');
    const r=await fetch(`${api}/sessions`,{method:'POST',headers:{'Content-Type':'application/json','X-Tenant-Key':tenant},body:JSON.stringify({channel:'web_widget',locale:navigator.language||'en',consent:{purpose:'product_support',granted:true,policyVersion:'mvp-1'}})});
    if(!r.ok)throw new Error(`Session failed (${r.status}).`);
    const data=await r.json();this.state.sessionToken=data.sessionToken;
  }

  async ensureConversation(){
    if(this.state.conversationId)return;
    await this.ensureSession();
    const api=this.getAttribute('api-base');
    const r=await fetch(`${api}/conversations`,{method:'POST',headers:{'Content-Type':'application/json','Authorization':`Bearer ${this.state.sessionToken}`},body:JSON.stringify({channel:'web_widget',locale:navigator.language||'en',tonePreference:'adaptive',pageContext:{title:document.title,url:location.href,product:this.getAttribute('product')||undefined,version:this.getAttribute('product-version')||undefined}})});
    if(!r.ok)throw new Error(`Conversation failed (${r.status}).`);
    this.state.conversationId=(await r.json()).id;
  }

  async onSubmit(e){
    e.preventDefault();if(this.state.busy)return;
    const input=this.$('textarea'),content=input.value.trim();if(!content)return;
    this.addMessage('customer',content);input.value='';this.setBusy(true,'Searching approved product knowledge…');
    try{
      if(this.hasAttribute('demo')){
        await new Promise(r=>setTimeout(r,450));
        this.addMessage('assistant',this.demoAnswer(content),[{title:'Demo product guide',uri:'#'}]);
      }else{
        await this.ensureConversation();
        const api=this.getAttribute('api-base');
        const clientMessageId=crypto.randomUUID();
        const r=await fetch(`${api}/conversations/${this.state.conversationId}/messages`,{method:'POST',headers:{'Content-Type':'application/json','Authorization':`Bearer ${this.state.sessionToken}`,'Idempotency-Key':crypto.randomUUID()},body:JSON.stringify({clientMessageId,content})});
        if(!r.ok)throw new Error(`Message failed (${r.status}).`);
        const data=await r.json();
        this.addMessage('assistant',data.message.content,data.citations||[]);
        if(data.escalation?.recommended)this.addHandoffAction(data.escalation.reason);
      }
      this.dispatchEvent(new CustomEvent('agentic-support-message',{detail:{conversationId:this.state.conversationId},bubbles:true}));
    }catch(err){this.addMessage('assistant','I could not reach the support service. Please try again or request a person.');this.$('.status').innerHTML=`<span class="error">${err.message}</span>`;this.addHandoffAction('Support service unavailable');}
    finally{this.setBusy(false,'');input.focus();}
  }

  addHandoffAction(reason='Human support requested'){
    const wrap=document.createElement('div');wrap.className='actions';wrap.innerHTML=`<button class="action" type="button" data-action="handoff">Request a person</button><span class="meta"></span>`;wrap.querySelector('.meta').textContent=reason;this.$('.log').append(wrap);
  }

  async requestHandoff(){
    this.setBusy(true,'Preparing handoff…');
    try{
      if(this.hasAttribute('demo')){await new Promise(r=>setTimeout(r,350));this.addMessage('assistant','A demo handoff has been prepared with the conversation context.');return;}
      await this.ensureConversation();
      const api=this.getAttribute('api-base');
      const r=await fetch(`${api}/conversations/${this.state.conversationId}/handoffs`,{method:'POST',headers:{'Content-Type':'application/json','Authorization':`Bearer ${this.state.sessionToken}`,'Idempotency-Key':crypto.randomUUID()},body:JSON.stringify({customerObjective:'Continue with a human support representative',transcriptConsent:true})});
      if(!r.ok)throw new Error(`Handoff failed (${r.status}).`);
      const h=await r.json();this.addMessage('assistant',`Human support request queued${h.externalCaseId?` as ${h.externalCaseId}`:''}.`);
    }catch(err){this.addMessage('assistant','I could not create the handoff automatically. Please use the product support contact channel.');}
    finally{this.setBusy(false,'');}
  }

  demoAnswer(input){
    const q=input.toLowerCase();
    if(q.includes('install')||q.includes('setup'))return 'To install the widget: create a tenant, approve a knowledge source, allow the website domain, load the module script, and add the agentic-support element. Keep privileged credentials on the server.';
    if(q.includes('price'))return 'Pricing is not included in this demo knowledge source, so I will not guess. Connect the approved pricing source or pricing API to answer this accurately.';
    if(q.includes('refund'))return 'The agent may explain an approved refund policy, but an actual refund should require identity verification, policy validation, and approval based on the configured risk threshold.';
    return 'This offline demo is not connected to product knowledge. In production, the agent would retrieve approved evidence, validate the answer, include citations, and escalate when evidence or authority is insufficient.';
  }
}

if(!customElements.get('agentic-support'))customElements.define('agentic-support',AgenticSupport);
export { AgenticSupport };
