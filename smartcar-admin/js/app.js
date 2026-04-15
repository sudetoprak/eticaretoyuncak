/* ─── UYGULAMA DURUMU ─────────────────────────────────────────── */
let currentPage = 'dashboard';
let currentUser = null;

const _productCache = {};

/* ─── YARDIMCI FONKSİYONLAR ──────────────────────────────────── */

function toast(msg, type = 'default') {
  const el = document.createElement('div');
  el.className = `toast ${type}`;
  el.textContent = msg;
  document.getElementById('toast-container').appendChild(el);
  setTimeout(() => el.remove(), 3500);
}

function showModal(title, bodyHTML, onSubmit = null) {
  document.getElementById('modal-title').textContent = title;
  document.getElementById('modal-body').innerHTML = bodyHTML;
  document.getElementById('modal-overlay').classList.remove('hidden');
  if (onSubmit) {
    const form = document.querySelector('#modal-body form');
    if (form) form.addEventListener('submit', async (e) => { e.preventDefault(); await onSubmit(); });
  }
}

function hideModal() {
  document.getElementById('modal-overlay').classList.add('hidden');
}

function loading() {
  return `<div class="loading"><div class="spinner"></div> Yükleniyor...</div>`;
}

function empty(msg = 'Kayıt bulunamadı', icon = '📭') {
  return `<div class="empty-state"><span class="empty-icon">${icon}</span><p>${msg}</p></div>`;
}

function fmt(date) {
  if (!date) return '-';
  return new Date(date).toLocaleString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

function fmtMoney(n) {
  return (n || 0).toLocaleString('tr-TR', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' ₺';
}

function badge(text, cls) {
  return `<span class="badge badge-${cls}">${text}</span>`;
}

function roleBadge(role) {
  return badge(role === 'admin' ? 'Admin' : 'Kullanıcı', role);
}

function statusBadge(status) {
  const map = { pending: 'Bekliyor', paid: 'Ödendi', shipped: 'Kargoda',
                delivered: 'Teslim Edildi', cancelled: 'İptal' };
  return badge(map[status] || status, status);
}

function activeBadge(active) {
  return active ? badge('Aktif', 'active') : badge('Pasif', 'inactive');
}

/* ─── SAYFA GEÇİŞİ ───────────────────────────────────────────── */

function navigate(page) {
  currentPage = page;

  document.querySelectorAll('.nav-item').forEach(el => {
    el.classList.toggle('active', el.dataset.page === page);
  });

  const titles = {
    dashboard: 'Dashboard', users: 'Kullanıcılar', orders: 'Siparişler',
    products: 'Ürünler', cars: 'Bağlı Arabalar',
  };
  document.getElementById('page-title').textContent = titles[page] || page;
  document.getElementById('topbar-actions').innerHTML = '';
  document.getElementById('content').innerHTML = loading();

  switch (page) {
    case 'dashboard': renderDashboard(); break;
    case 'users':     renderUsers();     break;
    case 'orders':    renderOrders();    break;
    case 'products':  renderProducts();  break;
    case 'cars':      renderCars();      break;
  }
}

/* ─── AUTH ────────────────────────────────────────────────────── */

async function init() {
  const token = localStorage.getItem('sc_token');
  if (token) {
    try {
      currentUser = JSON.parse(localStorage.getItem('sc_user') || 'null') || await API.me();
      if (currentUser.role !== 'admin') throw new Error('Yetkisiz');
      showApp();
    } catch {
      localStorage.removeItem('sc_token');
      localStorage.removeItem('sc_user');
      showLogin();
    }
  } else {
    showLogin();
  }
}

function showLogin() {
  document.getElementById('login-screen').classList.remove('hidden');
  document.getElementById('app').classList.add('hidden');
}

function showApp() {
  document.getElementById('login-screen').classList.add('hidden');
  document.getElementById('app').classList.remove('hidden');
  document.getElementById('sidebar-user').innerHTML =
    `<strong>${currentUser.username}</strong>${currentUser.email}`;
  const hash = location.hash.replace('#', '') || 'dashboard';
  navigate(hash);
}

/* ─── SEKME GEÇİŞİ ───────────────────────────────────────────── */
document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    const tab = btn.dataset.tab;
    document.getElementById('tab-login').classList.toggle('hidden', tab !== 'login');
    document.getElementById('tab-register').classList.toggle('hidden', tab !== 'register');
  });
});

/* ─── KAYIT FORMU ─────────────────────────────────────────────── */
document.getElementById('register-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const btn = document.getElementById('register-btn');
  const err = document.getElementById('register-error');
  const suc = document.getElementById('register-success');
  err.classList.add('hidden'); suc.classList.add('hidden');
  btn.disabled = true; btn.textContent = 'Oluşturuluyor...';
  try {
    await API.adminRegister({
      full_name: document.getElementById('reg-fullname').value,
      username:  document.getElementById('reg-username').value,
      email:     document.getElementById('reg-email').value,
      password:  document.getElementById('reg-password').value,
      phone:     document.getElementById('reg-phone').value || undefined,
    });
    suc.textContent = 'Admin hesabı oluşturuldu! Şimdi giriş yapabilirsiniz.';
    suc.classList.remove('hidden');
    document.getElementById('register-form').reset();
    setTimeout(() => document.querySelector('[data-tab="login"]').click(), 2000);
  } catch (ex) {
    err.textContent = ex.message; err.classList.remove('hidden');
  } finally {
    btn.disabled = false; btn.textContent = 'Hesap Oluştur';
  }
});

/* ─── GİRİŞ FORMU ────────────────────────────────────────────── */
document.getElementById('login-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const btn = document.getElementById('login-btn');
  const err = document.getElementById('login-error');
  err.classList.add('hidden'); btn.disabled = true; btn.textContent = 'Giriş yapılıyor...';
  try {
    const { access_token } = await API.login(
      document.getElementById('login-email').value,
      document.getElementById('login-password').value,
    );
    localStorage.setItem('sc_token', access_token);
    currentUser = await API.me();
    if (currentUser.role !== 'admin') throw new Error('Bu hesabın admin yetkisi yok.');
    localStorage.setItem('sc_user', JSON.stringify(currentUser));
    showApp();
  } catch (ex) {
    err.textContent = ex.message; err.classList.remove('hidden');
  } finally {
    btn.disabled = false; btn.textContent = 'Giriş Yap';
  }
});

document.getElementById('logout-btn').addEventListener('click', () => {
  localStorage.removeItem('sc_token'); localStorage.removeItem('sc_user');
  currentUser = null; showLogin();
});

document.getElementById('modal-close-btn').addEventListener('click', hideModal);
document.getElementById('modal-overlay').addEventListener('click', (e) => {
  if (e.target === document.getElementById('modal-overlay')) hideModal();
});

window.addEventListener('hashchange', () => {
  const page = location.hash.replace('#', '') || 'dashboard';
  if (page !== currentPage) navigate(page);
});

/* ─── DASHBOARD ───────────────────────────────────────────────── */

async function renderDashboard() {
  try {
    const d = await API.dashboard();
    const users = d?.users || {}, orders = d?.orders || {}, revenue = d?.revenue || {};
    const products = d?.products || {}, commands = d?.commands || {};
    const dist = commands?.distribution || {}, byStatus = orders?.by_status || {};
    const maxCmd = Object.values(dist).length > 0 ? Math.max(...Object.values(dist), 1) : 1;

    document.getElementById('content').innerHTML = `
      <div class="stats-grid">
        <div class="stat-card blue"><span class="stat-label">Toplam Kullanıcı</span><span class="stat-value">${users.total ?? 0}</span><span class="stat-sub">Aktif: ${users.active ?? 0} · Bugün +${users.new_today ?? 0}</span></div>
        <div class="stat-card green"><span class="stat-label">Toplam Sipariş</span><span class="stat-value">${orders.total ?? 0}</span><span class="stat-sub">Bekleyen: ${byStatus.pending ?? 0} · Bugün: ${orders.today ?? 0}</span></div>
        <div class="stat-card yellow"><span class="stat-label">Toplam Gelir</span><span class="stat-value">${fmtMoney(revenue.total)}</span><span class="stat-sub">Bugün: ${fmtMoney(revenue.today)}</span></div>
        <div class="stat-card"><span class="stat-label">Ürünler</span><span class="stat-value">${products.active ?? 0}</span><span class="stat-sub">Düşük stok: ${products.low_stock ?? 0}</span></div>
        <div class="stat-card blue"><span class="stat-label">Komutlar (Bugün)</span><span class="stat-value">${commands.today ?? 0}</span><span class="stat-sub">Toplam: ${commands.total ?? 0} · Bu hafta: ${commands.week ?? 0}</span></div>
        <div class="stat-card green"><span class="stat-label">Bağlı Araba</span><span class="stat-value">${d?.connected_cars ?? 0}</span><span class="stat-sub">Anlık WebSocket</span></div>
      </div>
      <div class="section-grid">
        <div class="card">
          <div class="card-header"><span class="card-title">Sipariş Durumları</span></div>
          <ul class="cmd-dist-list">
            ${Object.keys(byStatus).length === 0
              ? `<p style="color:var(--text-muted);font-size:13px">Henüz sipariş yok.</p>`
              : Object.entries(byStatus).map(([k,v]) => `<li class="cmd-dist-item"><span>${statusBadge(k)}</span><strong>${v}</strong></li>`).join('')}
          </ul>
        </div>
        <div class="card">
          <div class="card-header"><span class="card-title">Komut Dağılımı (24s)</span></div>
          ${Object.keys(dist).length === 0
            ? `<p style="color:var(--text-muted);font-size:13px">Bugün henüz komut yok.</p>`
            : `<ul class="cmd-dist-list">${Object.entries(dist).sort((a,b)=>b[1]-a[1]).map(([cmd,cnt])=>`
              <li class="cmd-dist-item">
                <span style="width:90px;font-weight:600">${cmd}</span>
                <div style="flex:1;margin:0 12px"><div class="cmd-bar" style="width:${Math.round(cnt/maxCmd*100)}%"></div></div>
                <strong>${cnt}</strong>
              </li>`).join('')}</ul>`}
        </div>
      </div>`;
  } catch (ex) {
    document.getElementById('content').innerHTML = `<div class="alert alert-danger">Dashboard yüklenemedi: ${ex.message}</div>`;
  }
}

/* ─── KULLANICILAR ────────────────────────────────────────────── */

let usersPage = 1;
const usersLimit = 20;

async function renderUsers(page = 1) {
  usersPage = page;
  const searchVal = document.getElementById('user-search')?.value || '';
  const roleVal = document.getElementById('user-role-filter')?.value || '';

  document.getElementById('topbar-actions').innerHTML =
    `<button class="btn btn-outline btn-sm" onclick="openCreateAdmin()" style="margin-right:8px">+ Admin Ekle</button>` +
    `<button class="btn btn-primary btn-sm" onclick="openCreateUser()">+ Yeni Kullanıcı Ekle</button>`;

  try {
    const params = { page, limit: usersLimit };
    if (searchVal) params.search = searchVal;
    if (roleVal) params.role = roleVal;
    const { users, total } = await API.getUsers(params);
    const totalPages = Math.ceil(total / usersLimit);

    document.getElementById('content').innerHTML = `
      <div class="card">
        <div class="filters">
          <div class="form-group"><input type="text" id="user-search" placeholder="Ad, email, kullanıcı ara..." value="${searchVal}" /></div>
          <div class="form-group">
            <select id="user-role-filter">
              <option value="">Tüm Roller</option>
              <option value="admin" ${roleVal==='admin'?'selected':''}>Admin</option>
              <option value="user" ${roleVal==='user'?'selected':''}>Kullanıcı</option>
            </select>
          </div>
          <button class="btn btn-primary btn-sm" id="user-search-btn">Ara</button>
        </div>
        <div class="table-wrapper">
          <table>
            <thead><tr><th>Kullanıcı</th><th>E-posta</th><th>Rol</th><th>Durum</th><th>Kayıt Tarihi</th><th>İşlem</th></tr></thead>
            <tbody>
              ${users.length === 0 ? `<tr><td colspan="6">${empty()}</td></tr>` : users.map(u => `
              <tr>
                <td><strong>${u.username}</strong><br><small style="color:var(--text-muted)">${u.full_name || ''}</small></td>
                <td>${u.email}</td>
                <td>${roleBadge(u.role)}</td>
                <td>${activeBadge(u.is_active)}</td>
                <td>${fmt(u.created_at)}</td>
                <td>
                  <button class="btn btn-outline btn-sm" onclick="openEditUser('${u.id}')">Düzenle</button>
                  ${u.is_active
                    ? `<button class="btn btn-danger btn-sm" style="margin-left:4px" onclick="confirmDeactivateUser('${u.id}','${u.username}')">Pasife Al</button>`
                    : `<button class="btn btn-success btn-sm" style="margin-left:4px" onclick="activateUser('${u.id}')">Aktif Et</button>`}
                </td>
              </tr>`).join('')}
            </tbody>
          </table>
        </div>
        <div class="pagination">
          <span class="pagination-info">Toplam ${total} kullanıcı — Sayfa ${page}/${totalPages || 1}</span>
          <div class="pagination-btns">
            <button class="btn btn-outline btn-sm" ${page<=1?'disabled':''} onclick="renderUsers(${page-1})">← Önceki</button>
            <button class="btn btn-outline btn-sm" ${page>=totalPages?'disabled':''} onclick="renderUsers(${page+1})">Sonraki →</button>
          </div>
        </div>
      </div>`;

    document.getElementById('user-search-btn').addEventListener('click', () => renderUsers(1));
    document.getElementById('user-search').addEventListener('keydown', e => { if (e.key==='Enter') renderUsers(1); });
  } catch (ex) {
    document.getElementById('content').innerHTML = `<div class="alert alert-danger">Kullanıcılar yüklenemedi: ${ex.message}</div>`;
  }
}

function openCreateAdmin() {
  showModal('Yeni Admin Ekle', `
    <form id="create-admin-form">
      <div class="form-group"><label>Ad Soyad *</label><input type="text" id="ca-fullname" required /></div>
      <div class="form-group"><label>Kullanıcı Adı *</label><input type="text" id="ca-username" required /></div>
      <div class="form-group"><label>E-posta *</label><input type="email" id="ca-email" required /></div>
      <div class="form-group"><label>Şifre *</label><input type="password" id="ca-password" required minlength="6" /></div>
      <div class="form-group"><label>Telefon</label><input type="text" id="ca-phone" /></div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="hideModal()">İptal</button>
        <button type="submit" class="btn btn-primary">Admin Oluştur</button>
      </div>
    </form>`);
  document.getElementById('create-admin-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector('[type="submit"]');
    btn.disabled = true; btn.textContent = 'Oluşturuluyor...';
    try {
      await API.createUser({ full_name: document.getElementById('ca-fullname').value, username: document.getElementById('ca-username').value, email: document.getElementById('ca-email').value, password: document.getElementById('ca-password').value, phone: document.getElementById('ca-phone').value || undefined, role: 'admin' });
      hideModal(); toast('Admin hesabı oluşturuldu', 'success'); renderUsers(usersPage);
    } catch (ex) { toast(ex.message, 'error'); btn.disabled = false; btn.textContent = 'Admin Oluştur'; }
  });
}

function openCreateUser() {
  showModal('Yeni Kullanıcı Ekle', `
    <form id="create-user-form">
      <div class="form-group"><label>Ad Soyad *</label><input type="text" id="cu-fullname" required /></div>
      <div class="form-group"><label>Kullanıcı Adı *</label><input type="text" id="cu-username" required /></div>
      <div class="form-group"><label>E-posta *</label><input type="email" id="cu-email" required /></div>
      <div class="form-group"><label>Şifre *</label><input type="password" id="cu-password" required minlength="6" /></div>
      <div class="form-group"><label>Telefon</label><input type="text" id="cu-phone" /></div>
      <div class="form-group"><label>Rol</label><select id="cu-role"><option value="user">Kullanıcı</option><option value="admin">Admin</option></select></div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="hideModal()">İptal</button>
        <button type="submit" class="btn btn-primary">Oluştur</button>
      </div>
    </form>`);
  document.getElementById('create-user-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = e.target.querySelector('[type="submit"]');
    btn.disabled = true; btn.textContent = 'Oluşturuluyor...';
    try {
      await API.createUser({ full_name: document.getElementById('cu-fullname').value, username: document.getElementById('cu-username').value, email: document.getElementById('cu-email').value, password: document.getElementById('cu-password').value, phone: document.getElementById('cu-phone').value || undefined, role: document.getElementById('cu-role').value });
      hideModal(); toast('Kullanıcı oluşturuldu', 'success'); renderUsers(usersPage);
    } catch (ex) { toast(ex.message, 'error'); btn.disabled = false; btn.textContent = 'Oluştur'; }
  });
}

async function openEditUser(id) {
  try {
    const u = await API.getUser(id);
    showModal('Kullanıcı Düzenle', `
      <form id="edit-user-form">
        <div class="form-group"><label>Kullanıcı Adı</label><input type="text" value="${u.username}" disabled /></div>
        <div class="form-group"><label>Ad Soyad</label><input type="text" id="eu-fullname" value="${u.full_name || ''}" /></div>
        <div class="form-group"><label>Rol</label><select id="eu-role"><option value="user" ${u.role==='user'?'selected':''}>Kullanıcı</option><option value="admin" ${u.role==='admin'?'selected':''}>Admin</option></select></div>
        <div class="form-group"><label>Durum</label><select id="eu-active"><option value="true" ${u.is_active?'selected':''}>Aktif</option><option value="false" ${!u.is_active?'selected':''}>Pasif</option></select></div>
        <div class="form-group" style="background:#f8fafc;border-radius:8px;padding:12px">
          <small style="color:var(--text-muted)">Sipariş sayısı: <strong>${u.stats?.order_count ?? '-'}</strong> &nbsp;|&nbsp; Toplam harcama: <strong>${fmtMoney(u.stats?.total_spent)}</strong></small>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-outline" onclick="hideModal()">İptal</button>
          <button type="submit" class="btn btn-primary">Kaydet</button>
        </div>
      </form>`);
    document.getElementById('edit-user-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      try {
        await API.updateUser(id, { role: document.getElementById('eu-role').value, is_active: document.getElementById('eu-active').value === 'true', full_name: document.getElementById('eu-fullname').value || undefined });
        hideModal(); toast('Kullanıcı güncellendi', 'success'); renderUsers(usersPage);
      } catch (ex) { toast(ex.message, 'error'); }
    });
  } catch (ex) { toast(ex.message, 'error'); }
}

function confirmDeactivateUser(id, username) {
  showModal('Kullanıcıyı Pasife Al', `
    <p><strong>${username}</strong> adlı kullanıcıyı pasife almak istediğinize emin misiniz?</p>
    <p style="margin-top:8px;color:var(--text-muted);font-size:13px">Kullanıcı giriş yapamaz hale gelir.</p>
    <div class="modal-footer">
      <button class="btn btn-outline" onclick="hideModal()">İptal</button>
      <button class="btn btn-danger" onclick="deactivateUser('${id}')">Pasife Al</button>
    </div>`);
}

async function deactivateUser(id) {
  try { await API.deleteUser(id); hideModal(); toast('Kullanıcı pasife alındı', 'success'); renderUsers(usersPage); }
  catch (ex) { toast(ex.message, 'error'); }
}

async function activateUser(id) {
  try { await API.updateUser(id, { is_active: true }); toast('Kullanıcı aktif edildi', 'success'); renderUsers(usersPage); }
  catch (ex) { toast(ex.message, 'error'); }
}

/* ─── SİPARİŞLER ─────────────────────────────────────────────── */

let ordersPage = 1;
const ordersLimit = 20;

async function renderOrders(page = 1) {
  ordersPage = page;
  const statusVal = document.getElementById('order-status-filter')?.value || '';
  try {
    const params = { page, limit: ordersLimit };
    if (statusVal) params.status = statusVal;
    const { orders, total } = await API.getOrders(params);
    const totalPages = Math.ceil(total / ordersLimit);

    document.getElementById('content').innerHTML = `
      <div class="card">
        <div class="filters">
          <div class="form-group">
            <select id="order-status-filter">
              <option value="">Tüm Durumlar</option>
              <option value="pending" ${statusVal==='pending'?'selected':''}>Bekliyor</option>
              <option value="paid" ${statusVal==='paid'?'selected':''}>Ödendi</option>
              <option value="shipped" ${statusVal==='shipped'?'selected':''}>Kargoda</option>
              <option value="delivered" ${statusVal==='delivered'?'selected':''}>Teslim Edildi</option>
              <option value="cancelled" ${statusVal==='cancelled'?'selected':''}>İptal</option>
            </select>
          </div>
          <button class="btn btn-primary btn-sm" id="order-filter-btn">Filtrele</button>
        </div>
        <div class="table-wrapper">
          <table>
            <thead><tr><th>Sipariş ID</th><th>Kullanıcı</th><th>Toplam</th><th>Durum</th><th>Tarih</th><th>İşlem</th></tr></thead>
            <tbody>
              ${orders.length === 0 ? `<tr><td colspan="6">${empty('Sipariş bulunamadı', '📦')}</td></tr>` : orders.map(o => `
              <tr>
                <td><code style="font-size:11px">${o.id.slice(-8)}</code></td>
                <td>${o.user_id}</td>
                <td><strong>${fmtMoney(o.total)}</strong></td>
                <td>${statusBadge(o.status)}</td>
                <td>${fmt(o.created_at)}</td>
                <td>
                  <button class="btn btn-outline btn-sm" onclick="openOrderDetail('${o.id}')">Detay</button>
                  <button class="btn btn-primary btn-sm" style="margin-left:4px" onclick="openUpdateOrderStatus('${o.id}','${o.status}')">Durum</button>
                </td>
              </tr>`).join('')}
            </tbody>
          </table>
        </div>
        <div class="pagination">
          <span class="pagination-info">Toplam ${total} sipariş — Sayfa ${page}/${totalPages || 1}</span>
          <div class="pagination-btns">
            <button class="btn btn-outline btn-sm" ${page<=1?'disabled':''} onclick="renderOrders(${page-1})">← Önceki</button>
            <button class="btn btn-outline btn-sm" ${page>=totalPages?'disabled':''} onclick="renderOrders(${page+1})">Sonraki →</button>
          </div>
        </div>
      </div>`;
    document.getElementById('order-filter-btn').addEventListener('click', () => renderOrders(1));
  } catch (ex) {
    document.getElementById('content').innerHTML = `<div class="alert alert-danger">Siparişler yüklenemedi: ${ex.message}</div>`;
  }
}

async function openOrderDetail(id) {
  try {
    const o = await API.getOrder(id);
    showModal(`Sipariş Detayı`, `
      <div style="margin-bottom:12px"><small style="color:var(--text-muted)">Sipariş ID</small><div><code>${o.id}</code></div></div>
      ${o.user ? `<div style="margin-bottom:12px"><small style="color:var(--text-muted)">Kullanıcı</small><div><strong>${o.user.username}</strong> (${o.user.email})</div></div>` : ''}
      <div style="margin-bottom:12px"><small style="color:var(--text-muted)">Durum</small><div>${statusBadge(o.status)}</div></div>
      <div style="margin-bottom:12px">
        <small style="color:var(--text-muted)">Ürünler</small>
        <table style="width:100%;margin-top:6px">
          <thead><tr><th>Ürün</th><th>Adet</th><th>Fiyat</th></tr></thead>
          <tbody>${(o.items||[]).map(item => `<tr><td>${typeof item.name === 'object' ? item.name.tr : item.name}</td><td>${item.quantity}</td><td>${fmtMoney(item.price * item.quantity)}</td></tr>`).join('')}</tbody>
        </table>
      </div>
      <div style="text-align:right;font-size:16px;font-weight:700">Toplam: ${fmtMoney(o.total)}</div>
      <div class="modal-footer">
        <button class="btn btn-outline" onclick="hideModal()">Kapat</button>
        <button class="btn btn-primary" onclick="hideModal();openUpdateOrderStatus('${o.id}','${o.status}')">Durumu Güncelle</button>
      </div>`);
  } catch (ex) { toast(ex.message, 'error'); }
}

function openUpdateOrderStatus(id, currentStatus) {
  const statuses = ['pending', 'paid', 'shipped', 'delivered', 'cancelled'];
  const labels = { pending:'Bekliyor', paid:'Ödendi', shipped:'Kargoda', delivered:'Teslim Edildi', cancelled:'İptal' };
  showModal('Sipariş Durumunu Güncelle', `
    <form id="order-status-form">
      <div class="form-group"><label>Yeni Durum</label>
        <select id="new-order-status">${statuses.map(s => `<option value="${s}" ${s===currentStatus?'selected':''}>${labels[s]}</option>`).join('')}</select>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="hideModal()">İptal</button>
        <button type="submit" class="btn btn-primary">Güncelle</button>
      </div>
    </form>`);
  document.getElementById('order-status-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
      await API.updateOrderStatus(id, document.getElementById('new-order-status').value);
      hideModal(); toast('Sipariş durumu güncellendi', 'success'); renderOrders(ordersPage);
    } catch (ex) { toast(ex.message, 'error'); }
  });
}

/* ─── ÜRÜNLER ─────────────────────────────────────────────────── */

let productsPage = 1;
const productsLimit = 20;

async function renderProducts(page = 1) {
  productsPage = page;
  document.getElementById('topbar-actions').innerHTML = `<button class="btn btn-primary" onclick="openAddProduct()">+ Ürün Ekle</button>`;

  const lowStock = document.getElementById('low-stock-filter')?.checked || false;
  const showInactive = document.getElementById('inactive-filter')?.checked || false;

  try {
    const params = { page, limit: productsLimit };
    if (lowStock) params.low_stock_only = true;
    if (showInactive) params.include_inactive = true;

    const { products, total } = await API.getAdminProducts(params);
    const totalPages = Math.ceil(total / productsLimit);

    products.forEach(p => { _productCache[p.id] = p; });

    document.getElementById('content').innerHTML = `
      <div class="card">
        <div class="filters" style="align-items:center">
          <label style="display:flex;align-items:center;gap:6px;cursor:pointer"><input type="checkbox" id="low-stock-filter" ${lowStock?'checked':''} onchange="renderProducts(1)" /> Düşük Stok</label>
          <label style="display:flex;align-items:center;gap:6px;cursor:pointer"><input type="checkbox" id="inactive-filter" ${showInactive?'checked':''} onchange="renderProducts(1)" /> Pasifleri Göster</label>
        </div>
        <div class="table-wrapper">
          <table>
            <thead><tr><th>Ürün Adı</th><th>Fiyat</th><th>Stok</th><th>Kategori</th><th>Durum</th><th>İşlem</th></tr></thead>
            <tbody>
              ${products.length === 0 ? `<tr><td colspan="6">${empty('Ürün bulunamadı', '🛒')}</td></tr>` : products.map(p => `
              <tr>
                <td><strong>${p.name?.tr || p.name}</strong> ${(p.tags||[]).map(t => `<span class="tag">${t}</span>`).join('')}</td>
                <td>${fmtMoney(p.price)}</td>
                <td><span style="color:${p.stock<=5?'var(--danger)':p.stock<=20?'var(--warning)':'inherit'};font-weight:600">${p.stock}</span></td>
                <td>${p.category || '-'}</td>
                <td>${p.is_active ? badge('Aktif','active') : badge('Pasif','inactive')}</td>
                <td>
                  <button class="btn btn-outline btn-sm" onclick="openEditProduct('${p.id}')">Düzenle</button>
                  <button class="btn btn-danger btn-sm" style="margin-left:4px" onclick="confirmDeleteProduct('${p.id}','${(p.name?.tr||p.name||'').replace(/'/g,'')}')">Sil</button>
                </td>
              </tr>`).join('')}
            </tbody>
          </table>
        </div>
        <div class="pagination">
          <span class="pagination-info">Toplam ${total} ürün — Sayfa ${page}/${totalPages || 1}</span>
          <div class="pagination-btns">
            <button class="btn btn-outline btn-sm" ${page<=1?'disabled':''} onclick="renderProducts(${page-1})">← Önceki</button>
            <button class="btn btn-outline btn-sm" ${page>=totalPages?'disabled':''} onclick="renderProducts(${page+1})">Sonraki →</button>
          </div>
        </div>
      </div>`;
  } catch (ex) {
    document.getElementById('content').innerHTML = `<div class="alert alert-danger">Ürünler yüklenemedi: ${ex.message}</div>`;
  }
}

function productFormHTML(p = null) {
  const v = p || {};
  return `
    <form id="product-form" onsubmit="return false;">
      <div class="form-row">
        <div class="form-group"><label>Ürün Adı (TR)</label><input type="text" id="pf-name-tr" value="${v.name?.tr || ''}" required /></div>
        <div class="form-group"><label>Ürün Adı (EN)</label><input type="text" id="pf-name-en" value="${v.name?.en || ''}" required /></div>
      </div>
      <div class="form-group"><label>Açıklama (TR)</label><textarea id="pf-desc-tr">${v.description?.tr || ''}</textarea></div>
      <div class="form-group"><label>Açıklama (EN)</label><textarea id="pf-desc-en">${v.description?.en || ''}</textarea></div>
      <div class="form-row">
        <div class="form-group"><label>Fiyat (₺)</label><input type="number" id="pf-price" value="${v.price || ''}" min="0" step="0.01" required /></div>
        <div class="form-group"><label>Stok</label><input type="number" id="pf-stock" value="${v.stock ?? ''}" min="0" required /></div>
      </div>
      <div class="form-row">
        <div class="form-group"><label>Kategori</label><input type="text" id="pf-category" value="${v.category || ''}" required /></div>
        <div class="form-group"><label>Etiketler (virgülle)</label><input type="text" id="pf-tags" value="${(v.tags || []).join(', ')}" /></div>
      </div>
      <div class="form-group">
        <label>Görsel Yükle</label>
        <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap">
          <input type="file" id="pf-image-file" accept="image/*" />
          <button type="button" class="btn btn-outline btn-sm" id="pf-upload-btn">Yükle</button>
          <span id="pf-upload-status" style="font-size:12px;color:var(--text-muted)"></span>
        </div>
        <div id="pf-image-preview" style="margin-top:8px;display:flex;gap:8px;flex-wrap:wrap"></div>
      </div>
      <textarea id="pf-images" style="display:none">${(v.images || []).join('\n')}</textarea>
      ${p ? `<div class="form-group"><label>Durum</label><select id="pf-active"><option value="true" ${p.is_active?'selected':''}>Aktif</option><option value="false" ${!p.is_active?'selected':''}>Pasif</option></select></div>` : ''}
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" onclick="hideModal()">İptal</button>
        <button type="button" class="btn btn-primary" id="pf-submit-btn">${p ? 'Güncelle' : 'Ekle'}</button>
      </div>
    </form>`;
}

function bindUploadBtn() {
  const uploadBtn = document.getElementById('pf-upload-btn');
  if (!uploadBtn) return;
  uploadBtn.addEventListener('click', async () => {
    const fileInput = document.getElementById('pf-image-file');
    const status = document.getElementById('pf-upload-status');
    const preview = document.getElementById('pf-image-preview');
    const file = fileInput.files[0];
    if (!file) { status.textContent = 'Önce bir dosya seçin.'; return; }
    uploadBtn.disabled = true; status.textContent = 'Yükleniyor...'; status.style.color = 'var(--text-muted)';
    try {
      const result = await API.uploadImage(file);
      const fullUrl = result.url.startsWith('http') ? result.url : 'http://100.114.176.17:8000' + result.url;
      const imagesArea = document.getElementById('pf-images');
      imagesArea.value = imagesArea.value ? imagesArea.value + '\n' + fullUrl : fullUrl;
      const img = document.createElement('img');
      img.src = fullUrl;
      img.style.cssText = 'width:80px;height:80px;object-fit:cover;border-radius:8px;border:1px solid var(--border)';
      preview.appendChild(img);
      status.textContent = 'Yüklendi!'; status.style.color = 'var(--success)'; fileInput.value = '';
    } catch (ex) {
      status.textContent = 'Hata: ' + ex.message; status.style.color = 'var(--danger)';
    } finally { uploadBtn.disabled = false; }
  });
}

function getProductFormData(isEdit = false) {
  const data = {
    name: { tr: document.getElementById('pf-name-tr').value, en: document.getElementById('pf-name-en').value },
    description: { tr: document.getElementById('pf-desc-tr').value, en: document.getElementById('pf-desc-en').value },
    price: parseFloat(document.getElementById('pf-price').value),
    stock: parseInt(document.getElementById('pf-stock').value),
    category: document.getElementById('pf-category').value,
    tags: document.getElementById('pf-tags').value.split(',').map(t => t.trim()).filter(Boolean),
    images: document.getElementById('pf-images').value.split('\n').map(t => t.trim()).filter(Boolean),
  };
  if (isEdit) data.is_active = document.getElementById('pf-active').value === 'true';
  return data;
}

function openAddProduct() {
  showModal('Yeni Ürün Ekle', productFormHTML());
  bindUploadBtn();
  document.getElementById('pf-submit-btn').addEventListener('click', async () => {
    const btn = document.getElementById('pf-submit-btn');
    btn.disabled = true; btn.textContent = 'Ekleniyor...';
    try {
      await API.createProduct(getProductFormData(false));
      hideModal(); toast('Ürün eklendi', 'success'); renderProducts(productsPage);
    } catch (ex) { toast(ex.message, 'error'); btn.disabled = false; btn.textContent = 'Ekle'; }
  });
}

function openEditProduct(productId) {
  const p = _productCache[productId];
  if (!p) { toast('Ürün bulunamadı', 'error'); return; }
  showModal('Ürün Düzenle', productFormHTML(p));
  bindUploadBtn();
  const preview = document.getElementById('pf-image-preview');
  (p.images || []).forEach(url => {
    const img = document.createElement('img');
    img.src = url;
    img.style.cssText = 'width:80px;height:80px;object-fit:cover;border-radius:8px;border:1px solid var(--border)';
    preview.appendChild(img);
  });
  document.getElementById('pf-submit-btn').addEventListener('click', async () => {
    const btn = document.getElementById('pf-submit-btn');
    btn.disabled = true; btn.textContent = 'Güncelleniyor...';
    try {
      await API.updateProduct(p.id, getProductFormData(true));
      hideModal(); toast('Ürün güncellendi', 'success'); renderProducts(productsPage);
    } catch (ex) { toast(ex.message, 'error'); btn.disabled = false; btn.textContent = 'Güncelle'; }
  });
}

function confirmDeleteProduct(id, name) {
  showModal('Ürünü Sil', `
    <p><strong>${name}</strong> adlı ürünü silmek istediğinize emin misiniz?</p>
    <p style="margin-top:8px;color:var(--text-muted);font-size:13px">Ürün pasife alınır, kalıcı silinmez.</p>
    <div class="modal-footer">
      <button class="btn btn-outline" onclick="hideModal()">İptal</button>
      <button class="btn btn-danger" onclick="deleteProduct('${id}')">Sil</button>
    </div>`);
}

async function deleteProduct(id) {
  try { await API.deleteProduct(id); hideModal(); toast('Ürün silindi', 'success'); renderProducts(productsPage); }
  catch (ex) { toast(ex.message, 'error'); }
}

/* ─── BAĞLI ARABALAR ──────────────────────────────────────────── */

async function renderCars() {
  try {
    const data = await API.getConnectedCars();
    document.getElementById('content').innerHTML = `
      <div class="stats-grid" style="max-width:400px">
        <div class="stat-card green"><span class="stat-label">Bağlı Araba</span><span class="stat-value">${data.count}</span><span class="stat-sub">Anlık WebSocket bağlantısı</span></div>
      </div>
      <div class="card" style="max-width:600px">
        <div class="card-header"><span class="card-title">Araba Listesi</span><button class="btn btn-outline btn-sm" onclick="renderCars()">Yenile</button></div>
        ${data.count === 0 ? empty('Şu an bağlı araba yok', '🚗') : `
        <div class="table-wrapper">
          <table>
            <thead><tr><th>Araba ID</th><th>Controller Sayısı</th></tr></thead>
            <tbody>${data.car_ids.map(id => `<tr><td><code>${id}</code></td><td>${data.controller_counts?.[id] ?? 0}</td></tr>`).join('')}</tbody>
          </table>
        </div>`}
      </div>`;
  } catch (ex) {
    document.getElementById('content').innerHTML = `<div class="alert alert-danger">Arabalar yüklenemedi: ${ex.message}</div>`;
  }
}

/* ─── BAŞLAT ──────────────────────────────────────────────────── */
init();