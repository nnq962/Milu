'use strict';
const $ = (s, root = document) => root.querySelector(s);
const $$ = (s, root = document) => [...root.querySelectorAll(s)];
const esc = s => String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const icon = (name, cls = '') => `<svg class="icon ${cls}" aria-hidden="true"><use href="#i-${name}"/></svg>`;
const money = n => (n < 0 ? '−' : '') + new Intl.NumberFormat('vi-VN', {maximumFractionDigits:0}).format(Math.abs(n)) + 'đ';
const number = n => new Intl.NumberFormat('vi-VN', {maximumFractionDigits:0}).format(Math.abs(n));
const short = n => (Math.abs(n) >= 1e6 ? new Intl.NumberFormat('vi-VN', {maximumFractionDigits:1}).format(Math.abs(n)/1e6) + 'tr' : number(n/1000) + 'k');
const demoDate = '2026-10-30';
const categories = {
  food:{name:'Ăn uống',icon:'food'}, coffee:{name:'Cà phê',icon:'coffee'}, shopping:{name:'Mua sắm',icon:'bag'},
  transport:{name:'Di chuyển',icon:'car'}, home:{name:'Nhà ở',icon:'home'}, salary:{name:'Tiền lương',icon:'briefcase'}, freelance:{name:'Thu nhập khác',icon:'wallet'}
};
const accounts = [
  {id:'vcb',name:'Vietcombank',subtitle:'Tài khoản chính',balance:32450000,icon:'bank'},
  {id:'tcb',name:'Techcombank',subtitle:'Chi tiêu hằng ngày',balance:18200000,icon:'bank'},
  {id:'cash',name:'Tiền mặt',subtitle:'Ví của bạn',balance:2000000,icon:'wallet'}
];
const goals = [
  {id:'travel',name:'Một chuyến đi Nhật',amount:12000000,target:20000000,icon:'plane',date:'Tháng 3, 2027'},
  {id:'reserve',name:'Quỹ dự phòng',amount:90000000,target:100000000,icon:'shield',date:'An tâm cho những ngày bất ngờ'}
];
const loans = [
  {id:'minh',name:'Minh Trần',initials:'MT',kind:'lent',amount:15000000,principal:20000000,due:'2026-11-03'},
  {id:'anh',name:'Anh Tuấn',initials:'AT',kind:'lent',amount:55000000,principal:60000000,due:'2026-11-25'},
  {id:'linh',name:'Linh Nguyễn',initials:'LN',kind:'borrowed',amount:20000000,principal:20000000,due:'2026-12-15'}
];
let transactions = [
  {id:'t1',category:'coffee',amount:45000,kind:'expense',account:'tcb',date:'2026-10-30',time:'08:45',note:'Cà phê sáng'},
  {id:'t2',category:'shopping',amount:680000,kind:'expense',account:'vcb',date:'2026-10-29',time:'18:20',note:'Đi chợ cuối tuần'},
  {id:'t3',category:'transport',amount:65000,kind:'expense',account:'tcb',date:'2026-10-29',time:'17:42',note:'Grab về nhà'},
  {id:'t4',category:'food',amount:320000,kind:'expense',account:'tcb',date:'2026-10-28',time:'19:15',note:'Bữa tối cùng gia đình'},
  {id:'t5',category:'shopping',amount:1200000,kind:'expense',account:'vcb',date:'2026-10-25',time:'11:30',note:'Đôi giày mới'},
  {id:'t6',category:'food',amount:180000,kind:'expense',account:'cash',date:'2026-10-24',time:'12:15',note:'Ăn trưa cùng bạn'},
  {id:'t7',category:'transport',amount:310000,kind:'expense',account:'tcb',date:'2026-10-22',time:'09:10',note:'Đổ xăng và gửi xe'},
  {id:'t8',category:'home',amount:5000000,kind:'expense',account:'vcb',date:'2026-10-05',time:'10:00',note:'Tiền thuê nhà tháng 10'},
  {id:'t9',category:'freelance',amount:7000000,kind:'income',account:'vcb',date:'2026-10-20',time:'14:30',note:'Dự án thiết kế'},
  {id:'t10',category:'salary',amount:25000000,kind:'income',account:'vcb',date:'2026-10-10',time:'09:00',note:'Lương tháng 10'}
];
const state = {screen:'overview',detail:null,segment:'flows',filter:'all',search:'',month:'2026-10',budget:15000000,accent:'jade',dark:false,messages:[],questions:20,toastTimer:null,modal:null,returnFocus:null};
const paletteNames = {jade:'Xanh ngọc',blue:'Xanh iOS',graphite:'Than chì'};
const accents = {
  jade:{light:['#087f6d','#e8f4f0','#b6d9cf'],dark:['#71d9bf','#203d35','#325e51']},
  blue:{light:['#0064d9','#e9f1fd','#b9d4f7'],dark:['#8abaff','#203149','#304f74']},
  graphite:{light:['#484a52','#eaeaec','#c4c5cb'],dark:['#d1d3da','#34353c','#53555f']}
};
const screenNames = {overview:'Tổng quan',accounts:'Tài khoản',transactions:'Giao dịch',assistant:'Trợ lý'};
const screenIcons = {overview:'home',accounts:'wallet',transactions:'transfer',assistant:'chat'};
const notes = {
 overview:['Đọc được ngay,<br>hiểu được nhanh.','Tài sản ròng dẫn đầu. Thu chi và hạn mức đi cùng nhau. Giao dịch gần đây luôn ở trong tầm mắt.'],
 accounts:['Mỗi đồng tiền,<br>một nơi rõ ràng.','Tài khoản dùng danh sách để dễ so sánh. Hũ tiết kiệm có một nhịp riêng: số đã dành, mục tiêu, tiến độ.'],
 transactions:['Xem dòng tiền.<br>Không phải giải mã.','Ngày, hạng mục và số tiền có vai trò riêng. Khoản chi thường dùng màu mực; màu xanh và dấu cộng nhận diện thu nhập.'],
 assistant:['Một cuộc trò chuyện,<br>ít thứ chen ngang.','Câu hỏi gợi ý gắn với dữ liệu thật trong demo. Ô nhập rõ ràng. Lượt còn lại và trạng thái giả lập được nói minh bạch.']
};
const accountByID = id => accounts.find(a=>a.id===id);
const monthTransactions = () => transactions.filter(t=>t.date.startsWith(state.month));
const total = kind => monthTransactions().filter(t=>t.kind===kind).reduce((a,t)=>a+t.amount,0);
const netWorth = () => accounts.reduce((a,x)=>a+x.balance,0)+goals.reduce((a,x)=>a+x.amount,0)+loans.reduce((a,x)=>a+(x.kind==='lent'?x.amount:-x.amount),0);
const sorted = ts => [...ts].sort((a,b)=>`${b.date} ${b.time}`.localeCompare(`${a.date} ${a.time}`));
const monthLabel = () => `Tháng ${Number(state.month.split('-')[1])}`;
function dateLabel(date){if(date===demoDate)return'Hôm nay';if(date==='2026-10-29')return'Hôm qua';const [y,m,d]=date.split('-');return`${d}/${m}/${y}`;}
function section(title, action='', label='Xem tất cả'){return `<div class="section-heading"><h2>${title}</h2>${action?`<button class="text-button" data-action="${action}">${label}${icon('chevron')}</button>`:''}</div>`;}
function trendChart(full=false){
  const values=[166,172,169,184,190,netWorth()/1e6], w=336,h=full?150:88;
  const min=Math.min(...values)-5,max=Math.max(...values)+6;
  const pts=values.map((v,i)=>[i*(w-12)/5+6,h-(v-min)/(max-min)*(h-12)]);
  let path=`M${pts[0][0]},${pts[0][1]}`;
  for(let i=1;i<pts.length;i++){const [x0,y0]=pts[i-1],[x,y]=pts[i],m=(x0+x)/2;path+=` C${m},${y0} ${m},${y} ${x},${y}`;}
  const id=full?'trend-full':'trend-small';
  return `<svg class="trend-chart" ${full?'style="height:165px"':''} viewBox="0 0 336 ${h+10}" preserveAspectRatio="none" role="img" aria-label="Tài sản ròng 6 tháng, từ 166 triệu đến ${number(netWorth())} đồng. Dữ liệu minh hoạ."><defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="var(--accent)" stop-opacity=".13"/><stop offset="100%" stop-color="var(--accent)" stop-opacity="0"/></linearGradient></defs><path d="${path} L330,${h+8} L6,${h+8} Z" fill="url(#${id})"/><path d="${path}" fill="none" stroke="var(--accent)" stroke-width="2.5" stroke-linecap="round"/><circle cx="${pts[5][0]}" cy="${pts[5][1]}" r="4" fill="var(--accent)" stroke="var(--bg)" stroke-width="2"/></svg><div class="chart-months"><span>T5</span><span>T6</span><span>T7</span><span>T8</span><span>T9</span><span>T10</span></div>`;
}
function txRow(t){
 const transfer=t.kind==='transfer',cat=categories[t.category],income=t.kind==='income';
 return `<button class="list-row" data-tx="${t.id}"><span class="row-icon">${icon(transfer?'transfer':cat.icon)}</span><span class="row-content"><span class="row-title">${transfer?'Chuyển khoản':cat.name}</span><span class="row-subtitle" style="display:block">${esc(t.note || accountByID(t.account)?.name || 'Tài khoản')}</span></span><span class="row-trailing"><span class="row-amount money ${income?'positive':''}">${income?'+':transfer?'':'−'}${money(t.amount)}</span><span class="row-subtitle" style="display:block">${esc(t.time)}</span></span></button>`;
}
function txList(ts){return ts.length?`<div class="surface">${ts.map(txRow).join('')}</div>`:`<div class="empty-state">${icon('search')}Chưa có giao dịch phù hợp.<br>Thử chọn bộ lọc khác.</div>`;}
function budgetMarkup(){const expense=total('expense'),remaining=state.budget-expense,percent=state.budget?expense/state.budget*100:0;return `<button class="budget-block" data-action="budget"><div class="budget-line"><span class="secondary">Hạn mức tháng</span><strong class="${remaining<0?'negative':''}">${remaining<0?'Đã vượt':'Còn'} ${short(remaining)}</strong></div><div class="progress-track"><div class="progress-fill" style="width:${Math.min(percent,100)}%;${percent>=100?'background:var(--red)':percent>=80?'background:var(--orange)':''}"></div></div><div class="budget-foot"><span>${short(expense)} / ${short(state.budget)}</span><span>${Math.round(percent)}% đã dùng</span></div></button>`;}
function wealthChange(){
  const delta=netWorth()-190000000;
  if(delta===0)return '<p class="wealth-change secondary">Không đổi so với cuối tháng 9</p>';
  return `<p class="wealth-change"><span class="${delta>0?'positive':'negative'}" style="display:inline-flex;align-items:center;gap:3px">${icon(delta>0?'up-right':'down-right')} ${delta>0?'+':'−'}${short(delta)}</span><span class="secondary">so với cuối tháng 9</span></p>`;
}
function reportSeries(){
  const [year,month]=state.month.split('-').map(Number);
  return Array.from({length:6},(_,i)=>{
    const date=new Date(year,month-6+i,1);
    const key=`${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}`;
    const records=transactions.filter(t=>t.date.startsWith(key));
    return {key,label:`T${date.getMonth()+1}`,income:records.filter(t=>t.kind==='income').reduce((a,t)=>a+t.amount,0),expense:records.filter(t=>t.kind==='expense').reduce((a,t)=>a+t.amount,0)};
  });
}
function overview(){return `<h1 class="page-heading">Tổng quan</h1><p class="greeting">Một ngày tốt lành, Quyết.</p><div class="wealth-block"><button class="wealth-label" data-action="networth">Tài sản ròng ${icon('chevron')}</button><div class="wealth-amount money">${netWorth()<0?'−':''}${number(netWorth())}<span class="currency">đ</span></div>${wealthChange()}${trendChart()}</div><section class="surface overview-month"><button class="section-inline whole-link" data-action="reports"><span>${monthLabel()} của bạn</span>${icon('chevron')}</button><div class="flow-totals"><div class="flow-total"><div class="flow-total-label">${icon('down-left')} Đã thu</div><div class="flow-value money positive">${money(total('income'))}</div></div><div class="flow-total"><div class="flow-total-label">${icon('up-right')} Đã chi</div><div class="flow-value money">${money(total('expense'))}</div></div></div>${budgetMarkup()}</section>${section('Gần đây','all-transactions')}${txList(sorted(transactions).slice(0,3))}${section('Sắp đến hạn','loans','Xem khoản vay')}<button class="surface list-row" data-loan="minh"><span class="row-icon accent">${icon('clock')}</span><span class="row-content"><span class="row-title">Thu nợ Minh Trần</span><span class="row-subtitle" style="display:block">Thứ Ba, 3/11 · Còn 4 ngày</span></span><span class="row-trailing"><span class="row-amount money">15.000.000đ</span></span></button>`;}
function accountRow(a){return `<button class="list-row" data-account="${a.id}"><span class="bank-logo ${a.id}">${icon(a.icon)}</span><span class="row-content"><span class="row-title">${esc(a.name)}</span><span class="row-subtitle" style="display:block">${a.subtitle}</span></span><span class="row-trailing"><span class="money row-amount">${money(a.balance)}</span></span>${icon('chevron','row-chevron')}</button>`;}
function accountsScreen(){return `<h1 class="page-heading">Tài khoản</h1><p class="greeting">Tiền của bạn, ở đúng nơi.</p><div class="account-total"><p>Tổng số dư khả dụng</p><div class="money">${money(accounts.reduce((a,x)=>a+x.balance,0))}</div></div><div class="surface">${accounts.map(accountRow).join('')}</div>${section('Hũ tiết kiệm')}<div class="goal-list">${goals.map(g=>`<button class="surface goal-card" data-goal="${g.id}"><div class="goal-head">${icon(g.icon)}<span class="goal-percent">${Math.floor(g.amount/g.target*100)}%</span></div><h3 class="goal-title">${g.name}</h3><div class="goal-amount money">${money(g.amount)}</div><div class="progress-track"><div class="progress-fill" style="width:${Math.min(g.amount/g.target*100,100)}%"></div></div><p class="goal-meta">Mục tiêu ${money(g.target)} · ${g.id==='travel'?g.date:'Không có thời hạn'}</p></button>`).join('')}</div><p class="inline-hint">${icon('shield')} Tiền trong hũ được tính riêng với số dư khả dụng.</p>`;}
function transactionsScreen(){return `<h1 class="page-heading">Giao dịch</h1><div class="segmented" role="group" aria-label="Loại giao dịch"><button data-segment="flows" class="${state.segment==='flows'?'selected':''}" aria-pressed="${state.segment==='flows'}">Thu chi</button><button data-segment="loans" class="${state.segment==='loans'?'selected':''}" aria-pressed="${state.segment==='loans'}">Vay nợ</button></div>${state.segment==='flows'?`<div class="transaction-summary"><div><p>Đã chi ${monthLabel().toLowerCase()}</p><div class="money">${money(total('expense'))}</div></div><div class="income-small"><p>Đã thu</p><div class="money">+${short(total('income'))}</div></div></div><div class="filters" role="group" aria-label="Lọc thu chi">${[['all','Tất cả'],['expense','Chi tiêu'],['income','Thu nhập'],['transfer','Chuyển khoản']].map(([k,v])=>`<button class="filter-button ${state.filter===k?'selected':''}" data-filter="${k}" aria-pressed="${state.filter===k}">${v}</button>`).join('')}</div><label class="search-box">${icon('search')}<input id="transaction-search" type="search" placeholder="Tìm giao dịch" aria-label="Tìm giao dịch" value="${esc(state.search)}"></label><div id="transaction-results">${filteredTransactions()}</div><button class="text-button" style="margin-top:14px" data-action="reports">Xem báo cáo ${monthLabel().toLowerCase()} ${icon('chevron')}</button>`:loansScreen()}`;}
function filteredTransactions(){const norm=s=>s.normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/đ/g,'d').toLowerCase();const q=norm(state.search);const ts=sorted(monthTransactions().filter(t=>(state.filter==='all'||t.kind===state.filter)&&norm(`${categories[t.category]?.name||'chuyển khoản'} ${t.note} ${accountByID(t.account)?.name}`).includes(q)));if(!ts.length)return txList([]);const groups=new Map();for(const t of ts){if(!groups.has(t.date))groups.set(t.date,[]);groups.get(t.date).push(t);}return [...groups].map(([d,list])=>`<p class="day-label">${dateLabel(d)}</p>${txList(list)}`).join('');}
function loansScreen(){const lent=loans.filter(l=>l.kind==='lent').reduce((a,l)=>a+l.amount,0),borrowed=loans.filter(l=>l.kind==='borrowed').reduce((a,l)=>a+l.amount,0);return `<div class="flow-totals" style="margin:27px 0"><div class="flow-total"><p class="flow-total-label">Đang cho vay</p><p class="flow-value money positive">${money(lent)}</p></div><div class="flow-total"><p class="flow-total-label">Đang đi vay</p><p class="flow-value money">${money(borrowed)}</p></div></div>${loans.map(l=>`<button class="surface loan-card" data-loan="${l.id}" style="width:100%;text-align:left"><div class="loan-person"><span class="avatar">${l.initials}</span><div class="row-content"><p class="row-title">${l.name}</p><p class="loan-kind">${l.kind==='lent'?'Cho vay':'Đi vay'}</p></div>${l.id==='minh'?'<span class="due-badge">Còn 4 ngày</span>':icon('chevron','row-chevron')}</div><div class="loan-balance"><span class="money">${money(l.amount)}</span><span class="small secondary">còn lại</span></div><div class="progress-track"><div class="progress-fill" style="width:${(1-l.amount/l.principal)*100}%"></div></div><p class="loan-note">Gốc ${short(l.principal)} · Hạn ${dateLabel(l.due)}</p></button>`).join('')}`;}
function assistantScreen(){return `<h1 class="page-heading">Trợ lý Timi</h1>${state.messages.length?'':`<div class="assistant-intro">${icon('sparkle','assistant-glyph')}<h2>Hiểu tiền của bạn.<br>Từng chút một.</h2><p>Cùng nhìn lại thu chi và dành thêm một chút cho điều bạn muốn.</p></div><div class="suggestion-list">${['Tháng này tôi chi bao nhiêu?','Tôi đang để dành được bao nhiêu?','Ai sắp đến hạn trả nợ?'].map(q=>`<button class="suggestion" data-question="${q}">${q}${icon('up-right')}</button>`).join('')}</div><p class="assistant-disclosure">Trợ lý trong bản demo trả lời theo quy tắc từ dữ liệu minh hoạ, chưa dùng AI thật.</p>`}<div class="chat-messages" aria-live="polite">${state.messages.map(m=>`<div class="message ${m.role}">${m.text}</div>`).join('')}</div><form class="chat-form" id="chat-form"><input name="question" aria-label="Hỏi Timi" placeholder="Hỏi Timi…" autocomplete="off" ${state.questions?'':'disabled'} required maxlength="500"><button type="submit" aria-label="Gửi câu hỏi" ${state.questions?'':'disabled'}>${icon('send')}</button></form><p class="assistant-quota">${state.questions?`${state.questions} lượt còn lại trong phiên demo`:'Đã hết lượt trong phiên demo. Tải lại trang để thử lại.'}</p>${state.messages.length?'<p class="assistant-disclosure">Phản hồi giả lập từ dữ liệu demo.</p>':''}`;}
function reportsScreen(){
  const groups={};
  monthTransactions().filter(t=>t.kind==='expense').forEach(t=>groups[t.category]=(groups[t.category]||0)+t.amount);
  const series=reportSeries();
  const maximum=Math.max(1,...series.flatMap(s=>[s.income,s.expense]));
  const hasData=series.some(s=>s.income||s.expense);
  const chart=hasData?`<div class="report-bars" role="img" aria-label="Thu chi theo từng tháng từ ${series[0].label} đến ${series[5].label}. Các tháng không có giao dịch có giá trị bằng không.">
    ${series.map((s,i)=>`<div class="bar-group" title="${s.label}: thu ${money(s.income)}, chi ${money(s.expense)}">
      <span class="bar ${i<5?'faded':''}" style="height:${s.income/maximum*100}%;${s.income?'':'visibility:hidden'}"></span>
      <span class="bar expense ${i<5?'faded':''}" style="height:${s.expense/maximum*100}%;${s.expense?'':'visibility:hidden'}"></span>
    </div>`).join('')}</div>
    <div class="report-labels">${series.map(s=>`<span>${s.label}</span>`).join('')}</div>
    <div class="chart-legend"><span><span class="legend-dot"></span>Thu nhập</span><span><span class="legend-dot expense"></span>Chi tiêu</span></div>`:'<p class="empty-state">Chưa có thu chi trong 6 tháng này.</p>';
  return `<h1 class="page-heading">Báo cáo</h1><p class="greeting">${monthLabel()} 2026</p>
    <div class="detail-hero"><p>Đã chi</p><div class="money">${money(total('expense'))}</div><p class="detail-label">${monthTransactions().filter(t=>t.kind==='expense').length} giao dịch trong tháng</p></div>
    <div class="surface overview-month" style="margin-top:8px"><div class="flow-totals"><div class="flow-total"><p class="flow-total-label">Đã thu</p><p class="flow-value money positive">${short(total('income'))}</p></div><div class="flow-total"><p class="flow-total-label">Dư ra</p><p class="flow-value money">${total('income')-total('expense')<0?'−':''}${short(total('income')-total('expense'))}</p></div></div>${budgetMarkup()}</div>
    ${section('Chi theo hạng mục')}<div class="surface">${Object.entries(groups).sort((a,b)=>b[1]-a[1]).map(([k,v])=>`<div class="category-row"><div class="category-top"><span>${icon(categories[k].icon)}${categories[k].name}</span><span class="money">${money(v)}</span></div><div class="progress-track"><div class="progress-fill" style="width:${v/total('expense')*100}%"></div></div></div>`).join('')||'<div class="empty-state">Chưa có khoản chi trong tháng này.</div>'}</div>
    ${section('Thu chi 6 tháng')}<div class="surface" style="padding:8px 18px 18px">${chart}</div>`;
}
function netWorthScreen(){return `<h1 class="page-heading">Tài sản ròng</h1><div class="detail-hero"><p>Hiện tại</p><div class="money">${money(netWorth())}</div>${wealthChange()}</div>${trendChart(true)}${section('Gồm những gì')}<div class="surface"><button class="list-row" data-action="go-accounts"><span class="row-icon">${icon('wallet')}</span><span class="row-content row-title">Tài khoản</span><span class="money row-amount">${money(accounts.reduce((a,x)=>a+x.balance,0))}</span>${icon('chevron','row-chevron')}</button><button class="list-row" data-action="go-accounts"><span class="row-icon">${icon('leaf')}</span><span class="row-content row-title">Hũ tiết kiệm</span><span class="money row-amount">${money(goals.reduce((a,x)=>a+x.amount,0))}</span>${icon('chevron','row-chevron')}</button><button class="list-row" data-action="loans"><span class="row-icon">${icon('down-left')}</span><span class="row-content row-title">Cho vay</span><span class="money row-amount">70.000.000đ</span>${icon('chevron','row-chevron')}</button><button class="list-row" data-action="loans"><span class="row-icon">${icon('up-right')}</span><span class="row-content row-title">Đi vay</span><span class="money row-amount">−20.000.000đ</span>${icon('chevron','row-chevron')}</button></div><p class="inline-hint">Tài sản ròng = tài khoản + hũ + cho vay − đi vay.</p>`;}
function accountDetail(a){return `<div class="detail-hero"><span class="bank-logo ${a.id}" style="width:48px;height:48px;margin-bottom:20px">${icon(a.icon)}</span><h1 class="page-heading" style="font-size:28px">${a.name}</h1><p style="margin:18px 0 8px">Số dư hiện tại</p><div class="money">${money(a.balance)}</div></div><div class="detail-actions"><button class="primary-button" data-action="add" data-preferred="${a.id}">${icon('plus')} Ghi giao dịch</button></div>${section('Lịch sử')}${txList(sorted(transactions.filter(t=>t.account===a.id||t.to===a.id)))}`;}
function goalDetail(g){return `<div class="detail-hero">${icon(g.icon,'assistant-glyph')}<h1 class="page-heading" style="font-size:29px">${g.name}</h1><p style="margin:22px 0 8px">Đã để dành</p><div class="money">${money(g.amount)}</div></div><div class="progress-track" style="height:8px"><div class="progress-fill" style="width:${Math.min(g.amount/g.target*100,100)}%"></div></div><div class="budget-foot"><span>${Math.floor(g.amount/g.target*100)}% mục tiêu</span><span>${money(g.target)}</span></div><div class="detail-actions" style="margin-top:25px"><button class="secondary-button" data-goal-move="${g.id}" data-direction="withdraw">Rút tiền</button><button class="primary-button" data-goal-move="${g.id}" data-direction="deposit">Nạp tiền</button></div><div class="surface"><div class="form-row"><span>Mục tiêu</span><span class="money">${money(g.target)}</span></div><div class="form-row"><span>Còn thiếu</span><span class="money">${money(Math.max(g.target-g.amount,0))}</span></div><div class="form-row"><span>Thời hạn</span><span class="secondary">${g.id==='travel'?g.date:'Không có'}</span></div></div><p class="inline-hint">Nạp và rút hũ là chuyển tiền giữa các nơi giữ tiền, không tính vào thu chi.</p>`;}
function budgetScreen(){const remaining=state.budget-total('expense');return `<h1 class="page-heading">Hạn mức</h1><p class="greeting">${monthLabel()} 2026</p><div class="detail-hero"><p>${remaining<0?'Đã vượt':'Còn lại để chi'}</p><div class="money ${remaining<0?'negative':''}">${money(remaining)}</div></div><div class="surface budget-detail"><p>Hạn mức tháng</p><div class="money">${money(state.budget)}</div>${budgetMarkup()}</div><button class="primary-button" style="width:100%;margin-top:22px" data-action="edit-budget">Điều chỉnh hạn mức</button>${section('Chi tiêu hiện tại')}<div class="surface"><div class="form-row"><span>Đã chi</span><span class="money">${money(total('expense'))}</span></div><div class="form-row"><span>Ngày còn lại</span><span class="secondary">${state.month==='2026-10'?'2 ngày, tính cả hôm nay':'Kỳ đã kết thúc'}</span></div>${state.month==='2026-10'&&remaining>0?`<div class="form-row"><span>Có thể chi mỗi ngày</span><span class="money">~${money(remaining/2)}</span></div>`:''}</div>`;}
function render(preserveScroll=false){
 const scroll=$('#app-scroll'),oldTop=scroll.scrollTop;
 const detail=state.detail;
 $('#toolbar').innerHTML=detail?`<button class="back-button" data-action="back">${icon('back')}Quay lại</button><span class="toolbar-title">${detail.type==='reports'?monthLabel():''}</span><button class="icon-button" data-action="add" aria-label="Thêm giao dịch">${icon('plus')}</button>`:`${state.screen==='transactions'?`<button class="text-button" data-action="month">${monthLabel()} 2026 ${icon('down')}</button>`:`<span class="toolbar-subtitle">${state.screen==='overview'?'Thứ Sáu, 30 tháng 10':state.screen==='accounts'?'Timi':state.screen==='assistant'?'Không gian của bạn':''}</span>`}<div class="toolbar-actions"><button class="avatar-button" data-action="settings" aria-label="Cài đặt"><span class="avatar">Q</span></button>${state.screen!=='assistant'?`<button class="icon-button" data-action="add" aria-label="Thêm giao dịch">${icon('plus')}</button>`:''}</div>`;
 let html='';
 if(detail){if(detail.type==='reports')html=reportsScreen();if(detail.type==='networth')html=netWorthScreen();if(detail.type==='budget')html=budgetScreen();if(detail.type==='account')html=accountDetail(accountByID(detail.id));if(detail.type==='goal')html=goalDetail(goals.find(g=>g.id===detail.id));}
 else html=({overview,accounts:accountsScreen,transactions:transactionsScreen,assistant:assistantScreen})[state.screen]();
 $('#screen').innerHTML=html;
 $('#tab-bar').innerHTML=Object.keys(screenNames).map(k=>`<button data-screen="${k}" class="${state.screen===k?'active':''}" aria-current="${state.screen===k?'page':'false'}">${icon(screenIcons[k])}<span>${screenNames[k]}</span></button>`).join('');
 $$('.screen-picker button').forEach(b=>b.classList.toggle('selected',b.dataset.screen===state.screen));
 $('#note-title').innerHTML=notes[state.screen][0];$('#note-copy').textContent=notes[state.screen][1];
 if(!preserveScroll)scroll.scrollTop=0;else scroll.scrollTop=oldTop;
}
function navigate(screen){state.screen=screen;state.detail=null;state.search='';closeSheet(false);render();}
function detail(type,id){state.detail={type,id};render();}
function applyAppearance(){
 const phone=$('#phone');phone.dataset.theme=state.dark?'dark':'light';const p=accents[state.accent][state.dark?'dark':'light'];
 for(const el of [phone]){el.style.setProperty('--accent',p[0]);el.style.setProperty('--accent-soft',p[1]);el.style.setProperty('--accent-line',p[2]);}
 // Match the full-screen mobile canvas without recoloring the presentation around the phone.
 document.querySelector('meta[name="theme-color"]').content=state.dark?'#111214':'#f5f5f7';
 $('#accent-name').textContent=paletteNames[state.accent];
 $$('.swatch').forEach(b=>{b.classList.toggle('selected',b.dataset.accent===state.accent);b.setAttribute('aria-pressed',String(b.dataset.accent===state.accent));});
 $('#theme-toggle').innerHTML=icon(state.dark?'sun':'moon')+(state.dark?'Thử giao diện sáng':'Thử giao diện tối');$('#theme-toggle').setAttribute('aria-pressed',String(state.dark));
}
function toast(text){clearTimeout(state.toastTimer);const t=$('#toast');t.innerHTML=icon('check')+`<span>${esc(text)}</span><button data-action="dismiss-toast" aria-label="Đóng thông báo">${icon('close')}</button>`;t.hidden=false;state.toastTimer=setTimeout(()=>t.hidden=true,5500);}
function showSheet(title,body,opts={}){
 const layer=$('#sheet-layer');if(layer.hidden)state.returnFocus=document.activeElement;state.modal=opts.kind||'info';$('#toast').hidden=true;
 layer.innerHTML=`<section class="sheet" role="dialog" aria-modal="true" aria-labelledby="sheet-title"><div class="sheet-grabber" aria-hidden="true"></div><header class="sheet-header"><button class="sheet-cancel" data-action="close-sheet">${opts.save?'Huỷ':'Đóng'}</button><h2 id="sheet-title">${title}</h2>${opts.save?`<button class="save-button" type="submit" form="${opts.form||'entry-form'}" aria-label="Lưu">${icon('check')}</button>`:'<span style="width:44px" aria-hidden="true"></span>'}</header><div class="sheet-body">${body}</div></section>`;
 layer.hidden=false;$('#app-shell').inert=true;
 $$('#amount-input,#goal-amount,#budget-input',layer).forEach(f=>f.style.width=Math.max(1,f.value.length)+.3+'ch');
 requestAnimationFrame(()=>{const first=$('input:not([type=hidden]),select,textarea',layer)||$('button',layer);first?.focus({preventScroll:true});});
}
function closeSheet(restore=true){const l=$('#sheet-layer');l.hidden=true;l.innerHTML='';$('#app-shell').inert=false;state.modal=null;if(restore&&state.returnFocus?.isConnected)state.returnFocus.focus({preventScroll:true});}
function entrySheet(kind='expense',existing=null,preferred=''){
 const isTransfer=kind==='transfer';const options=Object.entries(categories).filter(([k])=>kind==='income'?['salary','freelance'].includes(k):!['salary','freelance'].includes(k));
 const accountOptions=accounts.map(a=>`<option value="${a.id}" ${a.id===(existing?.account||preferred||'tcb')?'selected':''}>${a.name}</option>`).join('');
 showSheet(existing?.id?'Sửa giao dịch':'Thêm giao dịch',`<form id="entry-form" novalidate data-kind="${kind}" data-id="${existing?.id||''}"><div class="segmented" role="group" aria-label="Loại giao dịch mới">${[['expense','Chi tiêu'],['income','Thu nhập'],['transfer','Chuyển khoản']].map(([k,v])=>`<button type="button" data-entry-kind="${k}" class="${kind===k?'selected':''}" aria-pressed="${kind===k}">${v}</button>`).join('')}</div><div class="amount-entry"><label for="amount-input">Số tiền</label><div class="amount-input-wrap"><input id="amount-input" name="amount" inputmode="numeric" autocomplete="off" placeholder="0" value="${existing?number(existing.amount):''}" maxlength="15" aria-describedby="entry-error"><span>đ</span></div><div class="quick-amounts">${[50000,100000,200000].map(n=>`<button type="button" data-amount="${n}">${short(n)}</button>`).join('')}</div></div><p class="form-error" id="entry-error" role="alert"></p><div class="form-group">${!isTransfer?`<div class="form-row"><label for="entry-category">Hạng mục</label><select id="entry-category" name="category"><option value="">Chọn hạng mục</option>${options.map(([k,v])=>`<option value="${k}" ${existing?.category===k?'selected':''}>${v.name}</option>`).join('')}</select></div>`:''}<div class="form-row"><label for="entry-account">${isTransfer?'Từ tài khoản':'Tài khoản'}</label><select id="entry-account" name="account">${accountOptions}</select></div>${isTransfer?`<div class="form-row"><label for="entry-to">Đến tài khoản</label><select id="entry-to" name="to">${accounts.map(a=>`<option value="${a.id}" ${a.id===(existing?.to||'vcb')?'selected':''}>${a.name}</option>`).join('')}</select></div>`:''}<div class="form-row"><label for="entry-date">Ngày</label><input type="date" id="entry-date" name="date" value="${existing?.date||demoDate}" max="${demoDate}" min="2020-01-01"></div></div><textarea class="form-note" name="note" placeholder="Thêm ghi chú" aria-label="Ghi chú" maxlength="200">${esc(existing?.note||'')}</textarea><p class="sheet-info">${isTransfer?'Chuyển khoản không tính vào thu nhập hoặc chi tiêu.':'Số dư và báo cáo trong demo sẽ cập nhật khi bạn lưu.'}</p></form>`,{save:true,kind:'entry'});
}
function applyTransaction(t,direction){const a=accountByID(t.account);a.balance+=(t.kind==='income'?t.amount:-t.amount)*direction;if(t.kind==='transfer')accountByID(t.to).balance+=t.amount*direction;}
function saveEntry(form){const data=new FormData(form),amount=Number(String(data.get('amount')).replace(/\D/g,'')),kind=form.dataset.kind,old=transactions.find(t=>t.id===form.dataset.id);let error='';
 if(!amount||amount>999999999999)error='Nhập số tiền từ 1đ đến 999.999.999.999đ.';
 else if(kind!=='transfer'&&!data.get('category'))error='Chọn một hạng mục cho giao dịch.';
 else if(kind==='transfer'&&data.get('account')===data.get('to'))error='Chọn hai tài khoản khác nhau để chuyển tiền.';
 else if(!/^\d{4}-\d{2}-\d{2}$/.test(data.get('date'))||data.get('date')>demoDate||data.get('date')<'2020-01-01')error='Chọn ngày từ 01/01/2020 đến 30/10/2026.';
 if(error){$('#entry-error').textContent=error;return;}
 const t={id:old?.id||'t'+Date.now(),kind,amount,category:kind==='transfer'?null:data.get('category'),account:data.get('account'),to:data.get('to')||null,date:data.get('date'),time:old?.time||'09:41',note:String(data.get('note')).trim()};
 if(old){applyTransaction(old,-1);transactions=transactions.filter(x=>x.id!==old.id);}transactions.push(t);applyTransaction(t,1);closeSheet(false);render(true);toast(old?'Đã cập nhật giao dịch':'Đã lưu giao dịch');
}
function transactionSheet(id){const t=transactions.find(x=>x.id===id);if(!t)return;const cat=categories[t.category];showSheet('Chi tiết giao dịch',`<div class="sheet-value">${icon(t.kind==='transfer'?'transfer':cat.icon)}<h3>${t.kind==='transfer'?'Chuyển khoản':cat.name}</h3><p class="money ${t.kind==='income'?'positive':''}">${t.kind==='income'?'+':t.kind==='expense'?'−':''}${money(t.amount)}</p><p class="small secondary">${dateLabel(t.date)} · ${t.time}</p></div><div class="form-group"><div class="form-row"><span>${t.kind==='transfer'?'Từ tài khoản':'Tài khoản'}</span><span class="secondary">${accountByID(t.account).name}</span></div>${t.to?`<div class="form-row"><span>Đến tài khoản</span><span class="secondary">${accountByID(t.to).name}</span></div>`:''}${t.note?`<div class="form-row"><span>Ghi chú</span><span class="secondary" style="text-align:right;overflow-wrap:anywhere;min-width:0">${esc(t.note)}</span></div>`:''}</div><div class="detail-actions"><button class="primary-button" data-edit-tx="${id}">${icon('edit')} Sửa giao dịch</button></div><button class="destructive-button" data-delete-tx="${id}">${icon('trash')} Xoá giao dịch</button><div id="delete-confirm"></div>`);}
function settingsSheet(){showSheet('Cài đặt',`<div class="settings-avatar"><span class="avatar">Q</span><h3>Ngọc Quyết</h3><p>Dữ liệu minh hoạ · Gói miễn phí</p></div><div class="surface"><button class="settings-row" data-action="toggle-theme"><span>${icon(state.dark?'sun':'moon')}Giao diện</span><span class="small">${state.dark?'Tối':'Sáng'} ${icon('chevron')}</span></button><button class="settings-row" data-action="cycle-accent"><span>${icon('leaf')}Màu nhấn</span><span class="small">${paletteNames[state.accent]}</span></button><button class="settings-row" data-action="budget-from-settings"><span>${icon('wallet')}Hạn mức chi tiêu</span>${icon('chevron','row-chevron')}</button><button class="settings-row" data-action="reports-from-settings"><span>${icon('chart')}Báo cáo</span>${icon('chevron','row-chevron')}</button></div><div class="info-callout"><strong>Về bản demo</strong><br>Đây là bản thử màu sắc, bố cục và tương tác. Dữ liệu chỉ nằm trong phiên mở trang, tải lại sẽ trở về mẫu ban đầu. Chưa có kết nối ngân hàng hoặc dịch vụ AI.</div>`);}
function loanSheet(id){const l=loans.find(x=>x.id===id);showSheet('Chi tiết khoản vay',`<div class="sheet-value"><span class="avatar" style="margin:0 auto 14px;width:52px;height:52px">${l.initials}</span><h3>${l.name}</h3><p class="small secondary" style="margin-top:7px">${l.kind==='lent'?'Đang cho vay':'Đang đi vay'}</p><p class="money">${money(l.amount)}</p><p class="small secondary">còn lại</p></div><div class="form-group"><div class="form-row"><span>Khoản vay ban đầu</span><span class="money">${money(l.principal)}</span></div><div class="form-row"><span>Đã trả</span><span class="money positive">${money(l.principal-l.amount)}</span></div><div class="form-row"><span>Hạn trả</span><span>${dateLabel(l.due)}</span></div></div><p class="sheet-info">Bản thiết kế minh hoạ cách xem thông tin khoản vay. Luồng ghi nhận trả nợ vẫn dùng chức năng hiện có trong app iOS.</p>`);}
function goalMoveSheet(id,direction){const g=goals.find(x=>x.id===id),deposit=direction==='deposit';showSheet(deposit?'Nạp vào hũ':'Rút từ hũ',`<form id="goal-form" data-id="${id}" data-direction="${direction}" novalidate><div class="amount-entry"><label for="goal-amount">${g.name}</label><div class="amount-input-wrap"><input id="goal-amount" name="amount" inputmode="numeric" placeholder="0" maxlength="15" aria-describedby="goal-error"><span>đ</span></div></div><p id="goal-error" class="form-error" role="alert"></p><div class="form-group"><div class="form-row"><label for="goal-account">${deposit?'Lấy tiền từ':'Chuyển tiền về'}</label><select name="account" id="goal-account">${accounts.map(a=>`<option value="${a.id}">${a.name}</option>`).join('')}</select></div><div class="form-row"><span>Đang có trong hũ</span><span class="money">${money(g.amount)}</span></div></div><p class="sheet-info">Số dư tài khoản và hũ cùng cập nhật. Tổng tài sản ròng không thay đổi.</p></form>`,{save:true,form:'goal-form',kind:'goal'});}
function monthSheet(){showSheet('Chọn tháng',`<p style="font-size:23px;font-weight:600;margin-top:18px">2026</p><div class="month-picker">${Array.from({length:12},(_,i)=>`<button data-month="2026-${String(i+1).padStart(2,'0')}" ${i>9?'disabled':''} class="${Number(state.month.split('-')[1])===i+1?'selected':''}">Tháng ${i+1}</button>`).join('')}</div><p class="sheet-info">Dữ liệu mẫu được ghi vào tháng 10. Các tháng khác sẽ hiển thị trạng thái trống nếu chưa có giao dịch.</p>`);}
function ask(question){if(!question.trim()||!state.questions)return;state.messages.push({role:'user',text:esc(question)});state.questions--;const q=question.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'');let answer;
 if(q.includes('no')||q.includes('vay'))answer=`Khoản gần đến hạn nhất là của <strong>Minh Trần</strong>: còn <strong>15.000.000đ</strong>, hạn 3/11/2026.<br><br>Tổng tiền đang cho vay là <strong>70.000.000đ</strong>. Bạn có thể xem chi tiết ở Giao dịch → Vay nợ.`;
 else if(q.includes('danh')||q.includes('tiet kiem')||q.includes('hu'))answer=`Bạn đã để dành <strong>${money(goals.reduce((a,g)=>a+g.amount,0))}</strong> trong ${goals.length} hũ.<br><br>Hũ đi Nhật đang có ${money(goals[0].amount)}, đạt ${Math.floor(goals[0].amount/goals[0].target*100)}% mục tiêu. Còn ${money(Math.max(goals[0].target-goals[0].amount,0))} nữa.`;
 else if(q.includes('chi')||q.includes('tieu')||q.includes('thang'))answer=`${monthLabel()} bạn đã chi <strong>${money(total('expense'))}</strong>, tương đương ${Math.round(total('expense')/state.budget*100)}% hạn mức.<br><br>${state.budget>=total('expense')?`Bạn còn <strong>${money(state.budget-total('expense'))}</strong> trong hạn mức tháng.`:`Bạn đã vượt hạn mức <strong>${money(total('expense')-state.budget)}</strong>.`}<br><br>Đã thu ${money(total('income'))}. Các số này cập nhật theo giao dịch bạn thêm trong demo.`;
 else answer='Trong bản demo này, mình có thể tóm tắt <strong>chi tiêu tháng này</strong>, <strong>tiền trong hũ</strong> và <strong>khoản vay sắp đến hạn</strong>. Bạn thử hỏi một trong ba chủ đề nhé.';
 state.messages.push({role:'assistant',text:answer});render();$('#app-scroll').scrollTop=$('#app-scroll').scrollHeight;$('#chat-form input')?.focus({preventScroll:true});
}
document.addEventListener('click',e=>{
 const b=e.target.closest('button,a.wordmark');if(!b)return;
 if(b.matches('a.wordmark')){e.preventDefault();navigate('overview');return;}
 const d=b.dataset;
 if(d.screen){navigate(d.screen);return;}
 if(d.accent){state.accent=d.accent;applyAppearance();return;}
 if(d.tx){transactionSheet(d.tx);return;}
 if(d.account){detail('account',d.account);return;}
 if(d.goal){detail('goal',d.goal);return;}
 if(d.loan){loanSheet(d.loan);return;}
 if(d.segment){state.segment=d.segment;render(true);return;}
 if(d.filter){state.filter=d.filter;render(true);return;}
 if(d.question){ask(d.question);return;}
 if(d.month){state.month=d.month;closeSheet(false);render();return;}
 if(d.amount){$('#amount-input').value=number(Number(d.amount));$('#amount-input').style.width=($('#amount-input').value.length+.3)+'ch';return;}
 if(d.goalMove){goalMoveSheet(d.goalMove,d.direction);return;}
 if(d.entryKind){const f=$('#entry-form'),original=transactions.find(t=>t.id===f.dataset.id),draft={...(original||{}),amount:Number(f.amount.value.replace(/\D/g,'')),account:f.account.value,date:f.date.value,note:f.note.value,category:f.category?.value};entrySheet(d.entryKind,draft);return;}
 if(d.editTx){const t=transactions.find(t=>t.id===d.editTx);entrySheet(t.kind,t);return;}
 if(d.deleteTx){$('#delete-confirm').innerHTML=`<div class="confirm-box" role="alert">Xoá giao dịch này? Số dư tài khoản sẽ được hoàn lại.<div class="confirm-actions"><button data-action="cancel-delete">Giữ lại</button><button data-confirm-delete="${d.deleteTx}">Xoá giao dịch</button></div></div>`;$('#delete-confirm').scrollIntoView({block:'nearest'});return;}
 if(d.confirmDelete){const t=transactions.find(t=>t.id===d.confirmDelete);if(t){applyTransaction(t,-1);transactions=transactions.filter(x=>x.id!==t.id);}closeSheet(false);render(true);toast('Đã xoá và cập nhật số dư');return;}
 const actions={
  add:()=>entrySheet('expense',null,d.preferred||''),back:()=>{state.detail=null;render();},'close-sheet':()=>closeSheet(),
  networth:()=>detail('networth'),reports:()=>detail('reports'),budget:()=>detail('budget'),settings:settingsSheet,
  'all-transactions':()=>{state.segment='flows';state.filter='all';navigate('transactions');},'go-accounts':()=>navigate('accounts'),
  loans:()=>{state.segment='loans';navigate('transactions');},month:monthSheet,'dismiss-toast':()=>$('#toast').hidden=true,
  'cancel-delete':()=>$('#delete-confirm').innerHTML='',
  'toggle-theme':()=>{state.dark=!state.dark;applyAppearance();settingsSheet();},
  'cycle-accent':()=>{const a=Object.keys(accents);state.accent=a[(a.indexOf(state.accent)+1)%a.length];applyAppearance();settingsSheet();},
  'budget-from-settings':()=>{closeSheet(false);detail('budget');},'reports-from-settings':()=>{closeSheet(false);detail('reports');},
  'edit-budget':()=>showSheet('Hạn mức tháng',`<form id="budget-form" novalidate><div class="amount-entry"><label for="budget-input">Mỗi tháng bạn muốn chi tối đa</label><div class="amount-input-wrap"><input id="budget-input" name="amount" inputmode="numeric" value="${number(state.budget)}" maxlength="15" aria-describedby="budget-error"><span>đ</span></div></div><p class="form-error" id="budget-error" role="alert"></p><p class="sheet-info">Áp dụng cùng một hạn mức cho mỗi tháng trong demo.</p></form>`,{save:true,form:'budget-form',kind:'budget'})
 };
 if(d.action&&actions[d.action])actions[d.action]();
});
document.addEventListener('input',e=>{
 if(e.target.id==='transaction-search'){state.search=e.target.value;$('#transaction-results').innerHTML=filteredTransactions();}
 if(['amount-input','goal-amount','budget-input'].includes(e.target.id)){const digits=e.target.value.replace(/\D/g,'');e.target.value=digits?number(Number(digits)):'';e.target.style.width=(Math.max(1,e.target.value.length)+.3)+'ch';}
});
document.addEventListener('submit',e=>{
 if(e.target.id==='entry-form'){e.preventDefault();saveEntry(e.target);}
 if(e.target.id==='chat-form'){e.preventDefault();ask(new FormData(e.target).get('question'));}
 if(e.target.id==='budget-form'){e.preventDefault();const n=Number(e.target.amount.value.replace(/\D/g,''));if(!n||n>999999999999){$('#budget-error').textContent='Nhập hạn mức từ 1đ đến 999.999.999.999đ.';return;}state.budget=n;closeSheet(false);render(true);toast('Đã cập nhật hạn mức');}
 if(e.target.id==='goal-form'){e.preventDefault();const form=e.target,amount=Number(form.amount.value.replace(/\D/g,'')),a=accountByID(form.account.value),g=goals.find(x=>x.id===form.dataset.id),deposit=form.dataset.direction==='deposit';let error='';if(!amount||amount>999999999999)error='Nhập số tiền hợp lệ để tiếp tục.';else if(deposit&&amount>a.balance)error='Số tiền vượt quá số dư tài khoản.';else if(!deposit&&amount>g.amount)error='Số tiền vượt quá tiền đang có trong hũ.';if(error){$('#goal-error').textContent=error;return;}g.amount+=deposit?amount:-amount;a.balance+=deposit?-amount:amount;closeSheet(false);render(true);toast(deposit?'Đã nạp tiền vào hũ':'Đã rút tiền về tài khoản');}
});
document.addEventListener('keydown',e=>{
 if($('#sheet-layer').hidden)return;
 if(e.key==='Escape'){e.preventDefault();closeSheet();}
 if(e.key==='Tab'){const controls=$$('button:not(:disabled),input:not(:disabled),select,textarea,a[href]',$('#sheet-layer')).filter(el=>el.getClientRects().length);const first=controls[0],last=controls.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last?.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first?.focus();}}
});
$('#sheet-layer').addEventListener('click',e=>{if(e.target===$('#sheet-layer')&&state.modal==='info')closeSheet();});
$('#theme-toggle').addEventListener('click',()=>{state.dark=!state.dark;applyAppearance();});
$('#try-add').addEventListener('click',()=>entrySheet());
render();applyAppearance();
