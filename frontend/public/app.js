const $ = id => document.getElementById(id);
async function api(path, options = {}) {
  const response = await fetch(`/api/${path}`, {credentials:'same-origin', ...options});
  const data = await response.json();
  if (!response.ok) throw new Error(data.message || 'Request failed.');
  return data;
}
function showUser(user) {
  $('login-view').hidden = !!user;
  $('dashboard').hidden = !user;
  $('name').textContent = user?.name || '';
  $('user-email').textContent = user?.email || '';
}
$('login-form').addEventListener('submit',async event => {
  event.preventDefault(); $('message').textContent = ''; $('submit').disabled = true;
  try {
    const data = await api('login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:$('email').value.trim(),password:$('password').value})});
    $('password').value = ''; showUser(data.user);
  } catch(error) {$('message').textContent = error.message;}
  finally {$('submit').disabled = false;}
});
$('logout').addEventListener('click',async () => {
  $('message').textContent = '';
  try {await api('logout',{method:'POST'}); showUser(null);} catch(error) {$('message').textContent=error.message;}
});
api('health').then(() => {$('backend-status').textContent='Backend connected';$('status-dot').classList.add('online');}).catch(() => {$('backend-status').textContent='Backend offline — start the backend server';});
api('me').then(data => showUser(data.user)).catch(() => showUser(null));
