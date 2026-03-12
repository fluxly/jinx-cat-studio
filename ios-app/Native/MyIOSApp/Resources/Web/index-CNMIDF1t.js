var b=Object.defineProperty;var y=(o,a,e)=>a in o?b(o,a,{enumerable:!0,configurable:!0,writable:!0,value:e}):o[a]=e;var l=(o,a,e)=>y(o,typeof a!="symbol"?a+"":a,e);(function(){const a=document.createElement("link").relList;if(a&&a.supports&&a.supports("modulepreload"))return;for(const s of document.querySelectorAll('link[rel="modulepreload"]'))t(s);new MutationObserver(s=>{for(const i of s)if(i.type==="childList")for(const r of i.addedNodes)r.tagName==="LINK"&&r.rel==="modulepreload"&&t(r)}).observe(document,{childList:!0,subtree:!0});function e(s){const i={};return s.integrity&&(i.integrity=s.integrity),s.referrerPolicy&&(i.referrerPolicy=s.referrerPolicy),s.crossOrigin==="use-credentials"?i.credentials="include":s.crossOrigin==="anonymous"?i.credentials="omit":i.credentials="same-origin",i}function t(s){if(s.ep)return;s.ep=!0;const i=e(s);fetch(s.href,i)}})();const S=3e4;class w{constructor(){l(this,"pending",new Map);l(this,"idCounter",0);window.nativeBridge={receiveResponse:this.receiveResponse.bind(this)}}async call(a,e,t=S){const[s,i]=this.parseDotMethod(a),r=this.generateId(),n=JSON.stringify({id:r,namespace:s,method:i,params:e});return new Promise((d,m)=>{var f,g;const h=setTimeout(()=>{this.pending.delete(r),m(new p("timeout",`Bridge call timed out after ${t}ms: ${a}`))},t);this.pending.set(r,{resolve:d,reject:m,timeoutId:h}),(g=(f=window.webkit)==null?void 0:f.messageHandlers)!=null&&g.bridge?window.webkit.messageHandlers.bridge.postMessage(n):(clearTimeout(h),this.pending.delete(r),console.warn(`[BridgeClient] No native bridge available for: ${a}`),m(new p("no_bridge","Native bridge not available (not running in WKWebView)")))})}receiveResponse(a){let e;try{e=JSON.parse(a)}catch(n){console.error("[BridgeClient] Failed to parse response JSON:",a,n);return}const{id:t,ok:s,result:i,error:r}=e;if(!t){console.error("[BridgeClient] Response missing id:",e);return}const c=this.pending.get(t);if(!c){console.warn("[BridgeClient] Received response for unknown id:",t);return}if(clearTimeout(c.timeoutId),this.pending.delete(t),s)c.resolve(i);else{const n=(r==null?void 0:r.code)??"unknown_error",d=(r==null?void 0:r.message)??"An unknown error occurred.";c.reject(new p(n,d))}}generateId(){return this.idCounter+=1,`req-${this.idCounter}-${Date.now()}`}parseDotMethod(a){const e=a.split(".");if(e.length<2)throw new Error(`Invalid dotMethod format: "${a}" — expected "namespace.method"`);const t=e[0],s=e.slice(1).join(".");return[t,s]}}class p extends Error{constructor(a,e){super(e),this.code=a,this.name="BridgeError"}}const v=new w;class E{constructor(){l(this,"state",{currentView:"home",metaOptions:null,capturedImageBase64:null,status:null});l(this,"listeners",new Set)}subscribe(a){return this.listeners.add(a),()=>{this.listeners.delete(a)}}getState(){return this.state}setState(a){this.state={...this.state,...a},this.notify()}notify(){this.listeners.forEach(a=>{try{a()}catch(e){console.error("[Store] Listener threw an error:",e)}})}}const u=new E;class C extends HTMLElement{connectedCallback(){this.render()}render(){this.innerHTML=`
      <div class="home-view__cards">
        <div class="card card--interactive menu-card" data-view="email" role="button" tabindex="0" aria-label="Email / Note">
          <div class="menu-card__icon">✉️</div>
          <h2 class="menu-card__title">Email / Note</h2>
          <p class="menu-card__subtitle">Compose and send a structured note</p>
        </div>
        <div class="card card--interactive menu-card" data-view="camera" role="button" tabindex="0" aria-label="Camera">
          <div class="menu-card__icon">📷</div>
          <h2 class="menu-card__title">Camera</h2>
          <p class="menu-card__subtitle">Capture a photo and send it by email</p>
        </div>
      </div>
    `,this.querySelectorAll("[data-view]").forEach(a=>{a.addEventListener("click",()=>this.handleCardTap(a)),a.addEventListener("keydown",e=>{(e.key==="Enter"||e.key===" ")&&(e.preventDefault(),this.handleCardTap(a))})})}handleCardTap(a){const e=a.dataset.view;e&&this.dispatchEvent(new CustomEvent("navigate",{bubbles:!0,detail:{view:e}}))}}customElements.define("main-menu-card",C);class O extends HTMLElement{constructor(){super(...arguments);l(this,"options",null);l(this,"rendered",!1)}connectedCallback(){this.rendered||(this.renderShell(),this.rendered=!0),this.options&&this.populateSelects()}setOptions(e){this.options=e,this.rendered&&this.populateSelects()}getValues(){return{category:this.getSelectValue("category"),tagPrimary:this.getSelectValue("tagPrimary"),tagSecondary:this.getSelectValue("tagSecondary"),tagTertiary:this.getSelectValue("tagTertiary"),subject:this.getInputValue("subject")}}renderShell(){this.innerHTML=`
      <div class="metadata-form">
        <div class="form-group">
          <label class="form-label" for="mf-category">Category</label>
          <select class="form-select" id="mf-category" name="category">
            <option value="">— None —</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label" for="mf-tagPrimary">Tag Primary</label>
          <select class="form-select" id="mf-tagPrimary" name="tagPrimary">
            <option value="">— None —</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label" for="mf-tagSecondary">Tag Secondary</label>
          <select class="form-select" id="mf-tagSecondary" name="tagSecondary">
            <option value="">— None —</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label" for="mf-tagTertiary">Tag Tertiary</label>
          <select class="form-select" id="mf-tagTertiary" name="tagTertiary">
            <option value="">— None —</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label" for="mf-subject">Subject</label>
          <input
            class="form-input"
            type="text"
            id="mf-subject"
            name="subject"
            placeholder="Optional subject line..."
            autocomplete="off"
            autocorrect="off"
            spellcheck="false"
          />
        </div>
      </div>
    `,this.querySelectorAll("select, input").forEach(e=>{e.addEventListener("change",()=>this.dispatchChangeEvent()),e.addEventListener("input",()=>this.dispatchChangeEvent())})}populateSelects(){this.options&&(this.populateSelect("mf-category",this.options.categories),this.populateSelect("mf-tagPrimary",this.options.tagOptions),this.populateSelect("mf-tagSecondary",this.options.tagOptions),this.populateSelect("mf-tagTertiary",this.options.tagOptions))}populateSelect(e,t){const s=this.querySelector(`#${e}`);if(!s)return;const i=s.value;s.innerHTML='<option value="">— None —</option>',t.forEach(r=>{const c=document.createElement("option");c.value=r,c.textContent=r,s.appendChild(c)}),i&&t.includes(i)&&(s.value=i)}getSelectValue(e){const t=this.querySelector(`[name="${e}"]`);return(t==null?void 0:t.value)??""}getInputValue(e){const t=this.querySelector(`[name="${e}"]`);return(t==null?void 0:t.value)??""}dispatchChangeEvent(){this.dispatchEvent(new CustomEvent("metadata-change",{bubbles:!0,detail:this.getValues()}))}}customElements.define("metadata-form",O);class T extends HTMLElement{constructor(){super(...arguments);l(this,"autoHideTimeout",null)}static get observedAttributes(){return["type","message"]}connectedCallback(){this.render()}attributeChangedCallback(e,t,s){t!==s&&(this.autoHideTimeout!==null&&(clearTimeout(this.autoHideTimeout),this.autoHideTimeout=null),this.render(),this.getAttribute("type")==="success"&&(this.autoHideTimeout=setTimeout(()=>{this.setAttribute("type","idle"),this.setAttribute("message","")},4e3)))}disconnectedCallback(){this.autoHideTimeout!==null&&(clearTimeout(this.autoHideTimeout),this.autoHideTimeout=null)}render(){const e=this.getAttribute("type")??"idle",t=this.getAttribute("message")??"",s=e!=="idle"&&t.length>0,i=["status-banner"];s&&i.push("status-banner--visible"),e==="success"?i.push("status-banner--success"):e==="error"?i.push("status-banner--error"):e==="loading"&&i.push("status-banner--loading"),this.className=i.join(" "),this.setAttribute("role",s?"alert":"none"),this.setAttribute("aria-live","polite"),this.textContent=t}}customElements.define("status-banner",T);class _ extends HTMLElement{constructor(){super(...arguments);l(this,"_metaOptions",null)}set metaOptions(e){this._metaOptions=e;const t=this.querySelector("metadata-form");t&&e&&t.setOptions(e)}connectedCallback(){if(this.render(),this._metaOptions){const e=this.querySelector("metadata-form");e&&e.setOptions(this._metaOptions)}}render(){var e,t;this.innerHTML=`
      <div class="view">
        <button class="nav-back" type="button" id="env-back">
          ← Back
        </button>

        <div class="card">
          <h2 class="section-title">Email Note</h2>
          <metadata-form></metadata-form>
          <div class="divider"></div>
          <div class="form-group" style="margin-top: 0;">
            <label class="form-label" for="env-body">Note Body</label>
            <textarea
              class="form-textarea"
              id="env-body"
              name="body"
              placeholder="Write your note here..."
              rows="6"
              autocorrect="on"
              spellcheck="true"
            ></textarea>
          </div>
        </div>

        <status-banner id="env-status" type="idle" message=""></status-banner>

        <div class="actions">
          <button class="btn btn--primary btn--full" type="button" id="env-send">
            Send Note
          </button>
        </div>
      </div>
    `,(e=this.querySelector("#env-back"))==null||e.addEventListener("click",()=>this.navigateHome()),(t=this.querySelector("#env-send"))==null||t.addEventListener("click",()=>this.handleSend())}navigateHome(){this.dispatchEvent(new CustomEvent("navigate",{bubbles:!0,detail:{view:"home"}}))}async handleSend(){var c;const e=this.querySelector("metadata-form");if(!e)return;const t=e.getValues(),s=(((c=this.querySelector("#env-body"))==null?void 0:c.value)??"").trim(),i=this.querySelector("#env-send");this.querySelector("#env-status"),this.setStatus("loading","Opening mail composer..."),i&&(i.disabled=!0);const r={category:t.category||void 0,tagPrimary:t.tagPrimary||void 0,tagSecondary:t.tagSecondary||void 0,tagTertiary:t.tagTertiary||void 0,subject:t.subject||void 0,body:s||void 0};try{const n=await v.call("mail.composeNote",r),m={sent:"Note sent successfully.",saved:"Note saved as draft.",cancelled:"Compose cancelled.",failed:"Send failed. Please try again."}[n.status]??`Status: ${n.status}`,h=n.status==="sent"?"success":n.status==="cancelled"?"idle":n.status==="failed"?"error":"success";this.setStatus(h,m),u.setState({status:{type:h,message:m}})}catch(n){const d=n instanceof p?n.message:"An unexpected error occurred.";this.setStatus("error",d)}finally{i&&(i.disabled=!1)}}setStatus(e,t){const s=this.querySelector("#env-status");s&&(s.setAttribute("type",e),s.setAttribute("message",t))}}customElements.define("email-note-view",_);class B extends HTMLElement{constructor(){super(...arguments);l(this,"_metaOptions",null);l(this,"_capturedBase64",null)}set metaOptions(e){this._metaOptions=e;const t=this.querySelector("metadata-form");t&&e&&t.setOptions(e)}set capturedImage(e){this._capturedBase64=e,this.updateImagePreview(),this.updateSendButton()}connectedCallback(){this.render();const e=u.getState().capturedImageBase64;if(e&&(this._capturedBase64=e,this.updateImagePreview(),this.updateSendButton()),this._metaOptions){const t=this.querySelector("metadata-form");t&&t.setOptions(this._metaOptions)}}render(){var e,t,s;if(this.innerHTML=`
      <div class="view">
        <button class="nav-back" type="button" id="cv-back">
          ← Back
        </button>

        <div class="card">
          <h2 class="section-title">Camera</h2>

          <div id="cv-preview-container">
            <div class="photo-preview photo-preview--placeholder" id="cv-placeholder">
              No photo captured yet
            </div>
            <img
              class="photo-preview"
              id="cv-preview"
              alt="Captured photo preview"
              style="display:none;"
            />
          </div>

          <div class="actions" style="margin-top: 16px;">
            <button class="btn btn--secondary btn--full" type="button" id="cv-capture">
              Capture Photo
            </button>
          </div>
        </div>

        <div class="card" id="cv-meta-card">
          <h2 class="section-title">Email Metadata</h2>
          <metadata-form></metadata-form>
        </div>

        <status-banner id="cv-status" type="idle" message=""></status-banner>

        <div class="actions">
          <button class="btn btn--primary btn--full" type="button" id="cv-send" disabled>
            Send Photo
          </button>
        </div>
      </div>
    `,(e=this.querySelector("#cv-back"))==null||e.addEventListener("click",()=>this.navigateHome()),(t=this.querySelector("#cv-capture"))==null||t.addEventListener("click",()=>this.handleCapture()),(s=this.querySelector("#cv-send"))==null||s.addEventListener("click",()=>this.handleSend()),this._metaOptions){const i=this.querySelector("metadata-form");i&&i.setOptions(this._metaOptions)}}navigateHome(){this.dispatchEvent(new CustomEvent("navigate",{bubbles:!0,detail:{view:"home"}}))}async handleCapture(){const e=this.querySelector("#cv-capture");e&&(e.disabled=!0),this.setStatus("loading","Opening camera...");try{const t=await v.call("camera.capturePhoto");if(t.status==="captured"&&t.imageBase64)this._capturedBase64=t.imageBase64,u.setState({capturedImageBase64:t.imageBase64}),this.updateImagePreview(),this.updateSendButton(),this.setStatus("idle","");else if(t.status==="cancelled")this.setStatus("idle","");else if(t.status==="unavailable")this.setStatus("error","Camera is not available on this device.");else{const s=t.error??"Photo capture failed.";this.setStatus("error",s)}}catch(t){const s=t instanceof p?t.message:"An unexpected error occurred.";this.setStatus("error",s)}finally{e&&(e.disabled=!1)}}async handleSend(){if(!this._capturedBase64){this.setStatus("error","No photo to send. Capture a photo first.");return}const e=this.querySelector("metadata-form");if(!e)return;const t=e.getValues(),s=this.querySelector("#cv-send");this.setStatus("loading","Opening mail composer..."),s&&(s.disabled=!0);const i={category:t.category||void 0,tagPrimary:t.tagPrimary||void 0,tagSecondary:t.tagSecondary||void 0,tagTertiary:t.tagTertiary||void 0,subject:t.subject||void 0,imageBase64:this._capturedBase64};try{const r=await v.call("mail.composePhoto",i),n={sent:"Photo sent successfully.",saved:"Email saved as draft.",cancelled:"Compose cancelled.",failed:"Send failed. Please try again."}[r.status]??`Status: ${r.status}`,d=r.status==="sent"?"success":r.status==="cancelled"?"idle":r.status==="failed"?"error":"success";this.setStatus(d,n),u.setState({status:{type:d,message:n}})}catch(r){const c=r instanceof p?r.message:"An unexpected error occurred.";this.setStatus("error",c)}finally{s&&(s.disabled=!1)}}updateImagePreview(){const e=this.querySelector("#cv-placeholder"),t=this.querySelector("#cv-preview");!e||!t||(this._capturedBase64?(t.src=`data:image/jpeg;base64,${this._capturedBase64}`,t.style.display="block",e.style.display="none"):(t.style.display="none",e.style.display="flex"))}updateSendButton(){const e=this.querySelector("#cv-send");e&&(e.disabled=!this._capturedBase64)}setStatus(e,t){const s=this.querySelector("#cv-status");s&&(s.setAttribute("type",e),s.setAttribute("message",t))}}customElements.define("camera-view",B);class q extends HTMLElement{constructor(){super(...arguments);l(this,"unsubscribe",null)}connectedCallback(){this.render(),this.listenForNavigation(),this.unsubscribe=u.subscribe(()=>this.render()),this.loadMetaOptions()}disconnectedCallback(){var e;(e=this.unsubscribe)==null||e.call(this),this.unsubscribe=null}render(){const e=u.getState(),t=e.currentView;this.innerHTML=`
      <div class="app-container">
        ${t==="home"?this.renderHome():""}
        ${t==="email"?this.renderEmail():""}
        ${t==="camera"?this.renderCamera():""}
      </div>
    `;const s=e.metaOptions;s&&this.injectMetaOptions(s);const i=e.capturedImageBase64;if(i&&t==="camera"){const r=this.querySelector("camera-view");r&&(r.capturedImage=i)}}renderHome(){return`
      <div class="home-view view">
        <div class="home-view__header">
          <h1 class="home-view__title">Utility App</h1>
          <p class="home-view__subtitle">Choose an action below</p>
        </div>
        <main-menu-card></main-menu-card>
      </div>
    `}renderEmail(){return"<email-note-view></email-note-view>"}renderCamera(){return"<camera-view></camera-view>"}injectMetaOptions(e){const t=this.querySelector("email-note-view");t&&(t.metaOptions=e);const s=this.querySelector("camera-view");s&&(s.metaOptions=e)}listenForNavigation(){this.addEventListener("navigate",e=>{const t=e,{view:s}=t.detail;u.setState({currentView:s,status:null})})}async loadMetaOptions(){try{const e=await v.call("meta.getOptions");u.setState({metaOptions:e})}catch(e){console.warn("[AppShell] Failed to load meta options:",e),u.setState({metaOptions:{categories:["Ideas","Tasks","Reference","Journal","Project","Personal","Work","Other"],tagOptions:["Urgent","Important","Someday","Waiting","Active","Backlog","Done","Other"]}})}}}customElements.define("app-shell",q);
