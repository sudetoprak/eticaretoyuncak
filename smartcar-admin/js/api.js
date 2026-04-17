/* ─── API MODÜLÜ ─────────────────────────────────────────────── */

const BASE = 'http://100.114.176.17:8000/api/v1';

function getToken() { return localStorage.getItem('sc_token'); }

async function apiFetch(path, options = {}) {
  const token = getToken();
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(BASE + path, { ...options, headers });

  if (res.status === 401) {
    localStorage.removeItem('sc_token');
    localStorage.removeItem('sc_user');
    location.reload();
    throw new Error('Oturum süresi doldu');
  }

  const data = await res.json().catch(() => ({}));

  if (!res.ok) {
    throw new Error(data.detail || `HTTP ${res.status}`);
  }

  return data;
}

async function apiUpload(path, file) {
  const token = getToken();
  if (!token) {
    localStorage.removeItem('sc_token');
    localStorage.removeItem('sc_user');
    location.reload();
    throw new Error('Oturum bulunamadı');
  }
  const formData = new FormData();
  formData.append('file', file);

  let res;
  try {
    res = await fetch(BASE + path, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` },
      body: formData,
    });
  } catch (networkErr) {
    throw new Error('Sunucuya bağlanılamadı. Sunucunun çalıştığından emin olun.');
  }

  if (res.status === 401) {
    localStorage.removeItem('sc_token');
    localStorage.removeItem('sc_user');
    location.reload();
    throw new Error('Oturum süresi doldu');
  }

  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.detail || `HTTP ${res.status}`);
  return data;
}

const API = {
  // Auth
  login: (email, password) =>
    apiFetch('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),

  adminRegister: (data) =>
    apiFetch('/auth/admin-register', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  me: () => apiFetch('/auth/me'),

  // Admin - Dashboard
  dashboard:    () => apiFetch('/admin/dashboard'),
  charts:       () => apiFetch('/admin/charts'),
  recentOrders: () => apiFetch('/admin/recent-orders'),
  lowStock:     () => apiFetch('/admin/low-stock'),

  // Admin - Kullanıcılar
  getUsers:   (params = {}) => apiFetch('/admin/users?' + new URLSearchParams(params)),
  getUser:    (id)          => apiFetch(`/admin/users/${id}`),
  createUser: (data)        => apiFetch('/admin/users', { method: 'POST', body: JSON.stringify(data) }),
  updateUser: (id, data)    => apiFetch(`/admin/users/${id}`, { method: 'PATCH', body: JSON.stringify(data) }),
  deleteUser: (id)          => apiFetch(`/admin/users/${id}`, { method: 'DELETE' }),

  // Admin - Siparişler
  getOrders:         (params = {}) => apiFetch('/admin/orders?' + new URLSearchParams(params)),
  getOrder:          (id)          => apiFetch(`/admin/orders/${id}`),
  updateOrderStatus: (id, status)  => apiFetch(`/admin/orders/${id}/status`, {
    method: 'PATCH', body: JSON.stringify({ status }),
  }),

  // Admin - Ürünler
  getAdminProducts: (params = {}) => apiFetch('/admin/products?' + new URLSearchParams(params)),
  createProduct:    (data)        => apiFetch('/products', { method: 'POST', body: JSON.stringify(data) }),
  updateProduct:    (id, data)    => apiFetch(`/products/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  deleteProduct:    (id)          => apiFetch(`/products/${id}`, { method: 'DELETE' }),
  uploadImage:      (file)        => apiUpload('/products/upload-image', file),

  // Bağlı arabalar
  getConnectedCars: () => apiFetch('/admin/cars/connected'),
};