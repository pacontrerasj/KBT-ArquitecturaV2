// FreshBox SpA - Frontend estatico EP3 (S3 + API Gateway)
const API_BASE = (window.FRESHBOX_API_BASE || window.location.origin).replace(/\/$/, '');
const API_PRODUCTS = API_BASE + '/api/products';
const API_CART = API_BASE + '/api/cart';
const API_ORDERS = API_BASE + '/api/orders';
const USER_ID = obtenerUserId();

document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('cart-user').textContent = USER_ID;
    cargarProductos();
    cargarCarrito();
});

function obtenerUserId() {
    let id = localStorage.getItem('freshboxUserId');
    if (!id) {
        id = 'guest-' + Math.random().toString(36).slice(2, 10);
        localStorage.setItem('freshboxUserId', id);
    }
    return id;
}

async function pedir(url, opciones) {
    const response = await fetch(url, opciones);
    const data = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(data.error || data.message || 'Error HTTP ' + response.status);
    return data;
}

async function cargarProductos() {
    try {
        const productos = await pedir(API_PRODUCTS);
        renderizarTabla(productos);
        mostrarMensaje('Productos cargados', 'exito');
    } catch (error) {
        mostrarMensaje('Error al cargar productos: ' + error.message, 'error');
    }
}

function renderizarTabla(productos) {
    const tbody = document.getElementById('productos-body');
    tbody.innerHTML = '';
    if (!productos.length) {
        tbody.innerHTML = '<tr><td colspan="7">No hay productos</td></tr>';
        return;
    }
    productos.forEach(p => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${p.id}</td>
            <td>${escapar(p.nombre)}</td>
            <td>${escapar(p.descripcion || '-')}</td>
            <td>$${Number(p.precio).toLocaleString('es-CL')}</td>
            <td>${p.stock}</td>
            <td>${escapar(p.categoria || '-')}</td>
            <td>
                <button class="btn-agregar" onclick="agregarAlCarrito(${p.id}, '${escapar(p.nombre)}', ${Number(p.precio)})">Agregar</button>
                <button class="btn-editar" onclick="editarProducto(${p.id},'${escapar(p.nombre)}','${escapar(p.descripcion || '')}',${Number(p.precio)},${p.stock},'${escapar(p.categoria || '')}')">Editar</button>
                <button class="btn-eliminar" onclick="eliminarProducto(${p.id})">Eliminar</button>
            </td>`;
        tbody.appendChild(tr);
    });
}

async function guardarProducto(event) {
    event.preventDefault();
    const id = document.getElementById('producto-id').value;
    const datos = {
        nombre: document.getElementById('nombre').value,
        descripcion: document.getElementById('descripcion').value,
        precio: parseFloat(document.getElementById('precio').value),
        stock: parseInt(document.getElementById('stock').value),
        categoria: document.getElementById('categoria').value
    };
    try {
        if (id) {
            await pedir(API_PRODUCTS + '/' + id, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(datos) });
        } else {
            await pedir(API_PRODUCTS, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(datos) });
        }
        mostrarMensaje(id ? 'Producto modificado' : 'Producto creado', 'exito');
        limpiarFormulario();
        cargarProductos();
    } catch (error) {
        mostrarMensaje('Error al guardar producto: ' + error.message, 'error');
    }
}

async function eliminarProducto(id) {
    if (!confirm('Eliminar producto ' + id + '?')) return;
    try {
        await pedir(API_PRODUCTS + '/' + id, { method: 'DELETE' });
        mostrarMensaje('Producto eliminado', 'exito');
        cargarProductos();
    } catch (error) {
        mostrarMensaje('Error al eliminar producto: ' + error.message, 'error');
    }
}

async function agregarAlCarrito(productId, nombre, precio) {
    try {
        await pedir(API_CART, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ userId: USER_ID, productId, nombre, precio, cantidad: 1 })
        });
        mostrarMensaje(nombre + ' agregado al carrito', 'exito');
        cargarCarrito();
    } catch (error) {
        mostrarMensaje('Error al agregar al carrito: ' + error.message, 'error');
    }
}

async function cargarCarrito() {
    try {
        const data = await pedir(API_CART + '?userId=' + encodeURIComponent(USER_ID));
        renderizarCarrito(data);
    } catch (error) {
        mostrarMensaje('Error al cargar carrito: ' + error.message, 'error');
    }
}

function renderizarCarrito(data) {
    const tbody = document.getElementById('cart-body');
    const items = data.items || [];
    tbody.innerHTML = '';
    if (!items.length) {
        tbody.innerHTML = '<tr><td colspan="5">El carrito esta vacio</td></tr>';
    } else {
        items.forEach(item => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>${escapar(item.nombre)}</td>
                <td>${item.cantidad}</td>
                <td>$${Number(item.precio).toLocaleString('es-CL')}</td>
                <td>$${(Number(item.precio) * Number(item.cantidad)).toLocaleString('es-CL')}</td>
                <td><button class="btn-quitar" onclick="quitarDelCarrito('${escapar(item.productId)}')">Quitar</button></td>`;
            tbody.appendChild(tr);
        });
    }
    document.getElementById('cart-total').textContent = '$' + Number(data.total || 0).toLocaleString('es-CL');
}

async function quitarDelCarrito(productId) {
    try {
        await pedir(API_CART + '/' + encodeURIComponent(productId) + '?userId=' + encodeURIComponent(USER_ID), { method: 'DELETE' });
        mostrarMensaje('Producto quitado del carrito', 'exito');
        cargarCarrito();
    } catch (error) {
        mostrarMensaje('Error al quitar del carrito: ' + error.message, 'error');
    }
}

async function confirmarOrden() {
    try {
        const data = await pedir(API_ORDERS, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ userId: USER_ID })
        });
        mostrarMensaje(`${data.message}: ${data.orderId} por $${Number(data.total).toLocaleString('es-CL')}`, 'exito');
        cargarCarrito();
    } catch (error) {
        mostrarMensaje('Error al confirmar pedido: ' + error.message, 'error');
    }
}

function editarProducto(id, n, d, p, s, c) {
    document.getElementById('producto-id').value = id;
    document.getElementById('nombre').value = n;
    document.getElementById('descripcion').value = d;
    document.getElementById('precio').value = p;
    document.getElementById('stock').value = s;
    document.getElementById('categoria').value = c;
    document.getElementById('form-titulo').textContent = 'Editar producto (ID: ' + id + ')';
}

function cancelarEdicion() { limpiarFormulario(); }

function limpiarFormulario() {
    document.getElementById('producto-form').reset();
    document.getElementById('producto-id').value = '';
    document.getElementById('form-titulo').textContent = 'Nuevo producto';
}

function mostrarMensaje(texto, tipo) {
    const mensaje = document.getElementById('mensaje');
    mensaje.textContent = texto;
    mensaje.className = tipo === 'exito' ? 'mensaje-exito' : 'mensaje-error';
    setTimeout(() => { mensaje.textContent = ''; mensaje.className = ''; }, 5000);
}

function escapar(valor) {
    return String(valor).replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/</g, '&lt;');
}
