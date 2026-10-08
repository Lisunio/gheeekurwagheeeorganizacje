const app = document.getElementById('app');
const content = document.getElementById('content');
const nav = document.getElementById('nav');
const modal = document.getElementById('modal');
const modalBody = document.getElementById('modalBody');
const toastBox = document.getElementById('toast');

let data = null;
let page = 'home';

const pages = [
    ['home', 'Pulpit', '▦', 'tablet.view'],
    ['members', 'Członkowie', '♙', 'members.view'],
    ['ranks', 'Rangi', '◆', 'ranks.view'],
    ['tasks', 'Zadania', '✓', 'tasks.view'],
    ['notes', 'Notatnik', '▤', 'notes.view'],
    ['shop', 'Sklep', '◈', 'shop.view'],
    ['bank', 'Finanse', '₿', 'bank.view'],
];

const permissionLabels = {
    'tablet.view': 'Tablet',
    'members.view': 'Podgląd członków',
    'members.hire': 'Zatrudnianie',
    'members.fire': 'Zwalnianie',
    'members.rank': 'Zmiana rangi',
    'ranks.view': 'Podgląd rang',
    'ranks.manage': 'Zarządzanie rangami',
    'tasks.view': 'Podgląd zadań',
    'tasks.start': 'Uruchamianie zadań',
    'notes.view': 'Podgląd notatek',
    'notes.write': 'Tworzenie notatek',
    'notes.org': 'Notatki organizacji',
    'notes.manage': 'Zarządzanie notatkami',
    'shop.view': 'Podgląd sklepu',
    'shop.buy': 'Zakupy',
    'bank.view': 'Podgląd finansów',
    'bank.deposit': 'Wpłaty',
    'bank.withdraw': 'Wypłaty',
    'activity.view': 'Historia aktywności'
};

const esc = value => String(value ?? '').replace(/[&<>'"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
const money = value => `${Number(value || 0).toLocaleString('pl-PL')} $`;
const initials = value => String(value || '?').split(' ').map(x => x[0]).slice(0,2).join('').toUpperCase();
const perms = () => data?.rank?.permissions || {};
const has = p => p === 'tablet.view' ? !!data?.me : (perms()['*'] === true || perms()[p] === true);
const arg = value => encodeURIComponent(String(value ?? ''));
const unarg = value => decodeURIComponent(String(value ?? ''));


function post(action, payload = {}) {
    return fetch(`https://${GetParentResourceName()}/action`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: JSON.stringify({action, ...payload})
    });
}

function refreshData() {
    fetch(`https://${GetParentResourceName()}/refresh`, {method:'POST', body:'{}'});
}

function closeApp() {
    fetch(`https://${GetParentResourceName()}/close`, {method:'POST', body:'{}'});
    app.classList.add('hidden');
    closeModal();
}

function showToast(message, type='inform') {
    const el = document.createElement('div');
    el.className = `toast ${type}`;
    el.textContent = message;
    toastBox.appendChild(el);
    setTimeout(() => el.remove(), 2600);
}

function updateHeader() {
    const name = data?.name || 'Organizacja';
    const short = data?.short || data?.job || 'ORG';
    const me = data?.me?.name || 'Użytkownik';
    const rank = data?.rank?.name || 'Członek';

    document.getElementById('orgName').textContent = name;
    document.getElementById('orgShort').textContent = short;
    document.getElementById('orgAvatar').textContent = short.slice(0,4);
    document.getElementById('profileName').textContent = me;
    document.getElementById('profileRank').textContent = rank;
    document.getElementById('profileAvatar').textContent = initials(me);
    document.getElementById('crumbOrg').textContent = short;
    document.getElementById('crumbPage').textContent = pages.find(x => x[0] === page)?.[1] || 'Pulpit';
    document.getElementById('title').textContent = pages.find(x => x[0] === page)?.[1] || 'Pulpit';
}

function buildNav() {
    nav.innerHTML = '';
    for (const [id, label, icon, permission] of pages) {
        if (!has(permission)) continue;
        const button = document.createElement('button');
        button.className = `nav-btn ${page === id ? 'active' : ''}`;
        button.innerHTML = `<span class="nav-icon">${icon}</span><span>${label}</span>`;
        button.onclick = () => { page = id; buildNav(); render(); };
        nav.appendChild(button);
    }
}

function render() {
    if (!data) return;
    updateHeader();
    buildNav();

    if (page === 'home') return renderHome();
    if (page === 'members') return renderMembers();
    if (page === 'ranks') return renderRanks();
    if (page === 'tasks') return renderTasks();
    if (page === 'notes') return renderNotes();
    if (page === 'shop') return renderShop();
    if (page === 'bank') return renderBank();
}

function renderHome() {
    const members = Object.values(data.members || {});
    const activeTask = data.activeTask;

    content.innerHTML = `
        <div class="hero">
            <div>
                <span class="section-kicker">Witaj w systemie organizacji</span>
                <h2>${esc(data.name)}</h2>
                <p>${esc(data.short)} · siedziba: ${esc(data.location || 'brak')}</p>
            </div>
            <div class="hero-badge">${data.type === 'company' ? 'FIRMA / ESX JOB' : 'ORGANIZACJA KRYMINALNA'}</div>
        </div>

        <div class="grid grid-4" style="margin-top:12px">
            <div class="card stat"><div class="stat-label">Członkowie</div><div class="stat-value">${members.length}</div><div class="stat-sub">aktywnych wpisów</div></div>
            <div class="card stat"><div class="stat-label">Twoja ranga</div><div class="stat-value" style="font-size:18px">${esc(data.rank?.name || '-')}</div><div class="stat-sub">poziom ${data.rank?.level ?? '-'}</div></div>
            <div class="card stat"><div class="stat-label">Konto organizacji</div><div class="stat-value">${money(data.balance)}</div><div class="stat-sub">${esc(data.bankIban || 'brak IBAN')}</div></div>
            <div class="card stat"><div class="stat-label">Zadanie</div><div class="stat-value" style="font-size:17px">${activeTask ? esc(activeTask.label || activeTask.id) : 'Brak'}</div><div class="stat-sub">${activeTask ? 'w toku' : 'nic aktywnego'}</div></div>
        </div>

        <div class="grid grid-2" style="margin-top:12px">
            <div class="card">
                <div class="card-title"><h3>Ostatni członkowie</h3><button class="btn secondary" onclick="go('members')">Wszyscy</button></div>
                ${members.slice(0,4).map(memberRow).join('') || empty('Brak członków','Organizacja nie ma jeszcze członków.')}
            </div>
            <div class="card">
                <div class="card-title"><h3>Szybkie akcje</h3></div>
                <div class="grid grid-2">
                    ${has('bank.deposit') ? '<button class="btn" onclick="openMoney(\'deposit\')">Wpłać do organizacji</button>' : ''}
                    ${has('bank.withdraw') ? '<button class="btn secondary" onclick="openMoney(\'withdraw\')">Wypłać z organizacji</button>' : ''}
                    ${has('members.hire') ? '<button class="btn secondary" onclick="openHire()">Zatrudnij gracza</button>' : ''}
                    ${has('tasks.start') ? '<button class="btn secondary" onclick="go(\'tasks\')">Przeglądaj zadania</button>' : ''}
                </div>
            </div>
        </div>
    `;
}

function memberRow(m) {
    const rank = (data.ranks || []).find(r => Number(r.id) === Number(m.rankId));
    return `<div class="row"><div class="avatar">${initials(m.name)}</div><div class="row-main"><div class="row-title">${esc(m.name)}</div><div class="row-sub">${esc(rank?.name || 'Brak rangi')}</div></div><span class="pill green">${esc(rank?.name || 'Członek')}</span></div>`;
}

function renderMembers() {
    const members = Object.values(data.members || {});
    const canManage = has('members.hire') || has('members.fire') || has('members.rank');

    content.innerHTML = `
        ${has('members.hire') ? `<div class="card" style="margin-bottom:12px"><div class="card-title"><div><span class="section-kicker">ZARZĄDZANIE</span><h3 style="margin-top:5px">Dodaj członka</h3></div></div><button class="btn" onclick="openHire()">+ Zatrudnij gracza</button></div>` : ''}
        <div class="table-wrap">
            <div class="table-head"><div>Osoba</div><div>Ranga</div><div>Status</div><div>Akcje</div></div>
            ${members.length ? members.map(m => {
                const rank = (data.ranks || []).find(r => Number(r.id) === Number(m.rankId));
                return `<div class="table-row">
                    <div><strong>${esc(m.name)}</strong><div class="row-sub">${esc(m.identifier)}</div></div>
                    <div>${esc(rank?.name || '-')}</div>
                    <div><span class="pill green">${data.company ? 'Pracownik' : 'Członek'}</span></div>
                    <div class="row-actions">
                        ${has('members.rank') ? `<button class="btn secondary" onclick="openMemberRankEncoded('${arg(m.identifier)}')">Ranga</button>` : ''}
                        ${has('members.fire') ? `<button class="btn danger" onclick="fireMemberEncoded('${arg(m.identifier)}')">Zwolnij</button>` : ''}
                    </div>
                </div>`;
            }).join('') : `<div class="empty"><strong>Brak członków</strong>Dodaj pierwszą osobę do organizacji.</div>`}
        </div>
    `;
}

function renderRanks() {
    const ranks = data.ranks || [];
    content.innerHTML = `
        ${data.company ? `<div class="card" style="margin-bottom:12px"><span class="section-kicker">ESX JOB</span><h3 style="margin:6px 0">Rangi firmy są pobierane z joba ESX</h3><div class="muted" style="font-size:9px">Grade i nazwy rang ustawiasz w Config.Companies. Tablet nie modyfikuje tabeli jobów.</div></div>` : (has('ranks.manage') ? `<div class="card" style="margin-bottom:12px"><div class="card-title"><div><span class="section-kicker">UPRAWNIENIA</span><h3 style="margin-top:5px">Struktura organizacji</h3></div><button class="btn" onclick="openRank()">+ Dodaj rangę</button></div><div class="muted" style="font-size:9px">Wyższy poziom oznacza wyższą rangę. Osoba nie może zarządzać rangą równą lub wyższą od swojej.</div></div>` : '')}
        <div class="grid grid-2">
            ${ranks.map(r => `<div class="card">
                <div class="card-title"><div><span class="section-kicker">POZIOM ${r.level}</span><h3 style="margin-top:5px">${esc(r.name)}</h3></div><span class="pill">ID ${r.id}</span></div>
                <div class="permission-grid">${Object.keys(r.permissions || {}).filter(p => r.permissions[p]).map(p => `<span class="pill">${esc(permissionLabels[p] || p)}</span>`).join('') || '<span class="muted" style="font-size:9px">Brak specjalnych uprawnień</span>'}</div>
                ${!data.company && has('ranks.manage') && Number(data.rank?.id) !== Number(r.id) ? `<div class="form-actions"><button class="btn secondary" onclick="openRank(${r.id})">Edytuj</button></div>` : ''}
            </div>`).join('')}
        </div>
    `;
}

function renderTasks() {
    const tasks = data.tasks || [];
    content.innerHTML = `<div class="grid grid-2">${tasks.map(t => `<div class="card task-card">
        <span class="section-kicker">ZADANIE</span><h3>${esc(t.label)}</h3><p>${esc(t.description || '')}</p>
        <div class="reqs">
            ${t.requirements?.minPolice ? `<span class="req">POLICJA ${t.requirements.minPolice}+</span>` : ''}
            ${t.requirements?.minRank ? `<span class="req">RANGA ${t.requirements.minRank}+</span>` : ''}
            <span class="req">COOLDOWN ${Math.floor((t.cooldown || 0)/60)} MIN</span>
        </div>
        ${has('tasks.start') ? `<button class="btn" onclick="startTaskEncoded('${arg(t.id)}')">Rozpocznij zadanie</button>` : '<span class="muted" style="font-size:9px">Brak uprawnień do uruchamiania</span>'}
    </div>`).join('') || empty('Brak zadań','Dodaj zadania w config/tasks.lua.')}</div>`;
}

function renderNotes() {
    const notes = data.notes || [];
    content.innerHTML = `
        ${has('notes.write') ? `<div class="card" style="margin-bottom:12px"><div class="card-title"><div><span class="section-kicker">NOTATNIK</span><h3 style="margin-top:5px">Nowa notatka</h3></div><button class="btn" onclick="openNote()">+ Utwórz</button></div><div class="muted" style="font-size:9px">Notatki prywatne widzisz tylko ty. Notatki organizacyjne są wspólne.</div></div>` : ''}
        <div class="grid grid-2">${notes.map(n => `<div class="card note">
            <div class="note-head"><h3>${esc(n.title)}</h3><span class="pill ${n.private ? '' : 'green'}">${n.private ? 'PRYWATNA' : 'ORG'}</span></div>
            <p>${esc(n.content)}</p>
            <div class="note-meta">${esc(n.updated_at || n.created_at || '')}${has('notes.manage') || String(n.identifier) === String(data.me?.identifier) ? ` · <button class="btn danger" style="padding:4px 6px" onclick="deleteNote(${n.id})">Usuń</button>` : ''}</div>
        </div>`).join('') || empty('Brak notatek','Nie ma jeszcze żadnych zapisanych notatek.')}</div>
    `;
}

function renderShop() {
    let cards = '';
    Object.entries(data.shops || {}).forEach(([shopId, shop]) => {
        (shop.items || []).forEach(item => {
            cards += `<div class="card"><span class="section-kicker">${esc(shop.label || 'SKLEP')}</span><h3 style="margin:7px 0;font-size:13px">${esc(item.label || item.name)}</h3><div class="muted" style="font-size:9px">${money(item.price)} / szt. · dostawa ${shop.deliveryMinutes || 0} min</div><div style="margin-top:14px">${has('shop.buy') ? `<button class="btn" onclick="buyEncoded('${arg(shopId)}','${arg(item.name)}')">Kup</button>` : '<span class="muted" style="font-size:9px">Brak uprawnień</span>'}</div></div>`;
        });
    });
    content.innerHTML = `<div class="grid grid-3">${cards || empty('Sklep pusty','Dodaj produkty w config/shop.lua.')}</div>`;
}

function renderBank() {
    content.innerHTML = `
        <div class="grid grid-3">
            <div class="card stat"><div class="stat-label">Saldo organizacji</div><div class="stat-value">${money(data.balance)}</div><div class="stat-sub">IBAN: ${esc(data.bankIban || '-')}</div></div>
            <div class="card stat"><div class="stat-label">Wpłaty</div><div class="stat-value">+</div><div class="stat-sub">Środki pobierane z osobistego konta bankowego</div></div>
            <div class="card stat"><div class="stat-label">Wypłaty</div><div class="stat-value">−</div><div class="stat-sub">Środki trafiają na osobiste konto bankowe</div></div>
        </div>
        <div class="card" style="margin-top:12px"><div class="card-title"><div><span class="section-kicker">BANK ORGANIZACJI</span><h3 style="margin-top:5px">Operacje</h3></div></div><div style="display:flex;gap:8px;flex-wrap:wrap">${has('bank.deposit') ? '<button class="btn" onclick="openMoney(\'deposit\')">Wpłać środki</button>' : ''}${has('bank.withdraw') ? '<button class="btn secondary" onclick="openMoney(\'withdraw\')">Wypłać środki</button>' : ''}</div><div class="muted" style="font-size:9px;margin-top:13px">Operacje są wykonywane przez pScripts Banking i pojawiają się w historii rachunku organizacji.</div></div>
    `;
}

function empty(title, text) { return `<div class="empty" style="grid-column:1/-1"><strong>${esc(title)}</strong>${esc(text)}</div>`; }
function go(target) { page = target; render(); }

function openModal(title, kicker, body) {
    document.getElementById('modalTitle').textContent = title;
    document.getElementById('modalKicker').textContent = kicker;
    modalBody.innerHTML = body;
    modal.classList.remove('hidden');
}
function closeModal() { modal.classList.add('hidden'); modalBody.innerHTML = ''; }

function openConfirm(title, text, onConfirm) {
    openModal(title, 'POTWIERDZENIE', `<div class="card" style="margin:0"><p style="margin:0;color:#9aa5b5;font-size:10px;line-height:1.6">${esc(text)}</p></div><div class="form-actions"><button class="btn secondary" onclick="closeModal()">Anuluj</button><button class="btn danger" id="confirmAction">Potwierdź</button></div>`);
    document.getElementById('confirmAction').onclick = onConfirm;
}

function openMoney(type) {
    const title = type === 'deposit' ? 'Wpłata do organizacji' : 'Wypłata z organizacji';
    openModal(title, 'FINANSE', `<div class="field"><label>Kwota</label><input id="moneyAmount" class="input" type="number" min="1" step="1" placeholder="np. 5000"></div><div class="form-actions"><button class="btn secondary" onclick="closeModal()">Anuluj</button><button class="btn" onclick="submitMoney('${type}')">${type === 'deposit' ? 'Wpłać' : 'Wypłać'}</button></div>`);
}
function submitMoney(type) { const amount = Number(document.getElementById('moneyAmount').value); if (!amount || amount <= 0) return showToast('Podaj prawidłową kwotę','error'); post(type,{amount}); closeModal(); }

function openHire() {
    const ranks = (data.ranks || []).filter(r => Number(r.level) < Number(data.rank?.level || 0));
    openModal('Zatrudnij gracza','CZŁONKOWIE',`<div class="form-grid"><div class="field"><label>ID serwerowe</label><input id="hireTarget" class="input" type="number" min="1" placeholder="np. 12"></div><div class="field"><label>Ranga</label><select id="hireRank" class="select">${ranks.map(r=>`<option value="${r.id}">${esc(r.name)} · ${r.level}</option>`).join('')}</select></div></div><div class="form-actions"><button class="btn secondary" onclick="closeModal()">Anuluj</button><button class="btn" onclick="submitHire()">Zatrudnij</button></div>`);
}
function submitHire(){const target=Number(document.getElementById('hireTarget').value);const rankId=Number(document.getElementById('hireRank').value);if(!target||Number.isNaN(rankId))return showToast('Uzupełnij dane','error');post('hire',{target,rankId});closeModal();}
function fireMember(identifier){ openConfirm('Zwolnienie członka', 'Czy na pewno chcesz zwolnić tę osobę?', () => { post('fire',{identifier}); closeModal(); }); }
function openMemberRank(identifier){
    const ranks=(data.ranks||[]).filter(r=>Number(r.level)<Number(data.rank?.level||0));
    openModal('Zmień rangę','CZŁONEK',`<div class="field"><label>Nowa ranga</label><select id="memberRank" class="select">${ranks.map(r=>`<option value="${r.id}">${esc(r.name)} · ${r.level}</option>`).join('')}</select></div><div class="form-actions"><button class="btn secondary" onclick="closeModal()">Anuluj</button><button class="btn" onclick="submitMemberRank()">Zapisz</button></div>`);
    window.__memberRankIdentifier = identifier;
}
function openMemberRankEncoded(identifier){ openMemberRank(unarg(identifier)); }
function submitMemberRank(){
    const rankId=Number(document.getElementById('memberRank').value);
    if(!window.__memberRankIdentifier || Number.isNaN(rankId)) return showToast('Wybierz rangę','error');
    post('rank',{identifier:window.__memberRankIdentifier,rankId});
    window.__memberRankIdentifier=null;
    closeModal();
}
function fireMemberEncoded(identifier){ fireMember(unarg(identifier)); }

function openRank(rankId=null){
    const rank = rankId ? (data.ranks||[]).find(r=>Number(r.id)===Number(rankId)) : null;
    const selected = rank?.permissions || {};
    const permissionFields = Object.keys(permissionLabels).map(p=>`<label class="permission"><input type="checkbox" value="${esc(p)}" ${selected[p] ? 'checked' : ''}>${esc(permissionLabels[p])}</label>`).join('');
    openModal(rank ? 'Edytuj rangę' : 'Nowa ranga','RANGI',`<div class="form-grid"><div class="field"><label>Nazwa</label><input id="rankName" class="input" value="${esc(rank?.name || '')}" placeholder="np. Zastępca"></div><div class="field"><label>Poziom</label><input id="rankLevel" class="input" type="number" value="${rank?.level ?? 2}"></div><div class="field full"><label>Uprawnienia</label><div class="permission-grid">${permissionFields}</div></div></div><div class="form-actions"><button class="btn secondary" onclick="closeModal()">Anuluj</button><button class="btn" onclick="submitRank(${rankId ? rankId : 'null'})">Zapisz</button></div>`);
}
function submitRank(rankId){const name=document.getElementById('rankName').value.trim();const level=Number(document.getElementById('rankLevel').value);const permissions={};document.querySelectorAll('#modalBody .permission input:checked').forEach(x=>permissions[x.value]=true);if(!name||!level)return showToast('Uzupełnij dane','error');post(rankId?'updateRank':'createRank',{rankId,name,level,permissions});closeModal();}

function startTask(taskId){post('startTask',{taskId});}
function startTaskEncoded(taskId){startTask(unarg(taskId));}
function openNote(){openModal('Nowa notatka','NOTATNIK',`<div class="form-grid"><div class="field full"><label>Tytuł</label><input id="noteTitle" class="input" placeholder="Tytuł notatki"></div><div class="field full"><label>Treść</label><textarea id="noteContent" class="textarea" placeholder="Treść..."></textarea></div><div class="field full"><label><input id="notePrivate" type="checkbox"> prywatna notatka</label></div></div><div class="form-actions"><button class="btn secondary" onclick="closeModal()">Anuluj</button><button class="btn" onclick="submitNote()">Zapisz</button></div>`);}
function submitNote(){const title=document.getElementById('noteTitle').value.trim();const contentText=document.getElementById('noteContent').value;if(!title||!contentText)return showToast('Uzupełnij tytuł i treść','error');post('addNote',{title,content:contentText,private:document.getElementById('notePrivate').checked});closeModal();}
function deleteNote(id){ openConfirm('Usunięcie notatki', 'Czy na pewno chcesz usunąć tę notatkę?', () => { post('deleteNote',{id}); closeModal(); }); }
function buy(shopId,item){openModal('Potwierdź zakup','SKLEP',`<div class="card" style="margin:0"><div class="muted" style="font-size:9px">Produkt</div><div style="font-size:14px;font-weight:800;margin-top:5px">${esc(item)}</div></div><div class="form-grid" style="margin-top:10px"><div class="field"><label>Ilość</label><input id="buyAmount" class="input" type="number" min="1" max="50" value="1"></div></div><div class="form-actions"><button class="btn secondary" onclick="closeModal()">Anuluj</button><button class="btn" onclick="submitBuyEncoded('${arg(shopId)}','${arg(item)}')">Kup</button></div>`);}
function submitBuy(shopId,item){const amount=Number(document.getElementById('buyAmount').value);if(!amount||amount<1)return;post('buy',{shopId,item,amount});closeModal();}
function buyEncoded(shopId,item){buy(unarg(shopId),unarg(item));}
function submitBuyEncoded(shopId,item){submitBuy(unarg(shopId),unarg(item));}

function updateClock(){const now=new Date();document.getElementById('clock').textContent=now.toLocaleTimeString('pl-PL',{hour:'2-digit',minute:'2-digit'});}
setInterval(updateClock,1000);updateClock();

window.addEventListener('message', event => {
    if(event.data.action === 'open') { data = event.data.data; app.classList.remove('hidden'); page='home'; render(); }
    if(event.data.action === 'update') { data = event.data.data; render(); }
    if(event.data.action === 'notify') { showToast(event.data.message || '', event.data.type || 'inform'); }
});

document.addEventListener('keydown', event => { if(event.key === 'Escape' && !app.classList.contains('hidden')) closeApp(); });
