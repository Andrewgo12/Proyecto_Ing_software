"""
Python SDK para Sistema de Inventario PYMES
Versión: 1.0.0

Instalación:
pip install requests

Uso:
from python_sdk import InventoryAPI
client = InventoryAPI(api_key='your-api-key')
"""

import requests
import json
import time
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
import logging

class APIError(Exception):
    """Excepción personalizada para errores de la API"""
    
    def __init__(self, code: str, message: str, status: int, details: Dict = None, request_id: str = None):
        super().__init__(message)
        self.code = code
        self.message = message
        self.status = status
        self.details = details or {}
        self.request_id = request_id
    
    def is_retryable(self) -> bool:
        """Determina si el error es reintentable"""
        return self.status >= 500 or self.code == 'RATE_LIMIT_EXCEEDED'
    
    def __str__(self):
        return f"APIError [{self.code}]: {self.message} (Status: {self.status})"

class InventoryAPI:
    """Cliente Python para la API de Sistema de Inventario PYMES"""
    
    def __init__(self, base_url: str = None, api_key: str = None, access_token: str = None, 
                 refresh_token: str = None, timeout: int = 30, retry_attempts: int = 3, 
                 retry_delay: float = 1.0):
        self.base_url = base_url or 'https://api.inventario-pymes.com/v1'
        self.api_key = api_key
        self.access_token = access_token
        self.refresh_token = refresh_token
        self.timeout = timeout
        self.retry_attempts = retry_attempts
        self.retry_delay = retry_delay
        
        # Configurar logging
        self.logger = logging.getLogger(__name__)
        
        # Configurar sesión HTTP
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'InventoryAPI-Python-SDK/1.0.0'
        })
    
    def _get_auth_headers(self) -> Dict[str, str]:
        """Obtiene headers de autenticación"""
        headers = {}
        if self.access_token:
            headers['Authorization'] = f'Bearer {self.access_token}'
        elif self.api_key:
            headers['X-API-Key'] = self.api_key
        return headers
    
    def _calculate_retry_delay(self, attempt: int, status_code: int = None) -> float:
        """Calcula el delay para reintentos"""
        if status_code == 429:  # Rate limit
            return min(60.0, self.retry_delay * (2 ** attempt))
        return self.retry_delay * attempt
    
    def request(self, endpoint: str, method: str = 'GET', data: Dict = None, 
                params: Dict = None, headers: Dict = None, **kwargs) -> Any:
        """Realiza una petición HTTP con reintentos automáticos"""
        url = f"{self.base_url}{endpoint}"
        
        # Preparar headers
        request_headers = self.session.headers.copy()
        request_headers.update(self._get_auth_headers())
        if headers:
            request_headers.update(headers)
        
        # Preparar datos
        json_data = data if data else None
        
        last_error = None
        
        for attempt in range(1, self.retry_attempts + 1):
            try:
                response = self.session.request(
                    method=method,
                    url=url,
                    json=json_data,
                    params=params,
                    headers=request_headers,
                    timeout=self.timeout,
                    **kwargs
                )
                
                # Manejar respuestas exitosas
                if response.ok:
                    if response.headers.get('content-type', '').startswith('application/json'):
                        return response.json()
                    return response.text
                
                # Manejar errores
                try:
                    error_data = response.json()
                except:
                    error_data = {}
                
                error = APIError(
                    code=error_data.get('code', 'UNKNOWN_ERROR'),
                    message=error_data.get('message', response.reason),
                    status=response.status_code,
                    details=error_data.get('details', {}),
                    request_id=error_data.get('requestId')
                )
                
                # Renovar token si es necesario
                if response.status_code == 401 and self.refresh_token and attempt == 1:
                    self.refresh_access_token()
                    request_headers.update(self._get_auth_headers())
                    continue
                
                # No reintentar errores 4xx (excepto 429)
                if 400 <= response.status_code < 500 and response.status_code != 429:
                    raise error
                
                last_error = error
                
                # Esperar antes del siguiente intento
                if attempt < self.retry_attempts:
                    delay = self._calculate_retry_delay(attempt, response.status_code)
                    time.sleep(delay)
                    
            except requests.exceptions.RequestException as e:
                last_error = APIError('NETWORK_ERROR', str(e), 0)
                
                if attempt < self.retry_attempts:
                    time.sleep(self.retry_delay * attempt)
        
        raise last_error
    
    # ==================== AUTENTICACIÓN ====================
    
    def login(self, email: str, password: str) -> Dict:
        """Iniciar sesión y obtener tokens"""
        response = self.request('/auth/login', 'POST', {
            'email': email,
            'password': password
        })
        
        self.access_token = response['accessToken']
        self.refresh_token = response['refreshToken']
        
        return response
    
    def refresh_access_token(self) -> Dict:
        """Renovar el access token"""
        if not self.refresh_token:
            raise ValueError('No refresh token available')
        
        response = self.request('/auth/refresh', 'POST', {
            'refreshToken': self.refresh_token
        })
        
        self.access_token = response['accessToken']
        return response
    
    def logout(self) -> Dict:
        """Cerrar sesión"""
        response = self.request('/auth/logout', 'POST', {
            'refreshToken': self.refresh_token
        })
        
        self.access_token = None
        self.refresh_token = None
        
        return response
    
    def get_current_user(self) -> Dict:
        """Obtener información del usuario actual"""
        return self.request('/auth/me')
    
    # ==================== PRODUCTOS ====================
    
    def get_products(self, page: int = 1, limit: int = 20, search: str = None, 
                    category: str = None, is_active: bool = None) -> Dict:
        """Obtener lista de productos"""
        params = {'page': page, 'limit': limit}
        if search:
            params['search'] = search
        if category:
            params['category'] = category
        if is_active is not None:
            params['isActive'] = str(is_active).lower()
        
        return self.request('/products', params=params)
    
    def get_product(self, product_id: str) -> Dict:
        """Obtener producto específico"""
        return self.request(f'/products/{product_id}')
    
    def create_product(self, product_data: Dict) -> Dict:
        """Crear nuevo producto"""
        return self.request('/products', 'POST', product_data)
    
    def update_product(self, product_id: str, product_data: Dict) -> Dict:
        """Actualizar producto existente"""
        return self.request(f'/products/{product_id}', 'PUT', product_data)
    
    def delete_product(self, product_id: str) -> None:
        """Eliminar producto"""
        self.request(f'/products/{product_id}', 'DELETE')
    
    def search_products(self, query: str, **filters) -> Dict:
        """Buscar productos"""
        params = {'q': query, **filters}
        return self.request('/products/search', params=params)
    
    def create_products_batch(self, products: List[Dict]) -> Dict:
        """Crear múltiples productos"""
        return self.request('/products/batch', 'POST', {'products': products})
    
    # ==================== INVENTARIO ====================
    
    def get_stock_levels(self, product_id: str = None, location_id: str = None, 
                        low_stock: bool = None) -> List[Dict]:
        """Obtener niveles de stock"""
        params = {}
        if product_id:
            params['productId'] = product_id
        if location_id:
            params['locationId'] = location_id
        if low_stock is not None:
            params['lowStock'] = str(low_stock).lower()
        
        return self.request('/inventory/stock', params=params)
    
    def get_product_stock(self, product_id: str, location_id: str = None) -> List[Dict]:
        """Obtener stock de producto específico"""
        params = {'productId': product_id}
        if location_id:
            params['locationId'] = location_id
        
        return self.request('/inventory/stock', params=params)
    
    def create_movement(self, movement_data: Dict) -> Dict:
        """Crear movimiento de inventario"""
        return self.request('/inventory/movements', 'POST', movement_data)
    
    def get_movements(self, product_id: str = None, location_id: str = None, 
                     movement_type: str = None, start_date: str = None, 
                     end_date: str = None, page: int = 1, limit: int = 20) -> List[Dict]:
        """Obtener movimientos de inventario"""
        params = {'page': page, 'limit': limit}
        if product_id:
            params['productId'] = product_id
        if location_id:
            params['locationId'] = location_id
        if movement_type:
            params['movementType'] = movement_type
        if start_date:
            params['startDate'] = start_date
        if end_date:
            params['endDate'] = end_date
        
        return self.request('/inventory/movements', params=params)
    
    def adjust_stock(self, product_id: str, location_id: str, quantity: float, 
                    reason: str = '') -> Dict:
        """Ajustar stock de producto"""
        return self.create_movement({
            'productId': product_id,
            'locationId': location_id,
            'movementType': 'adjustment',
            'quantity': quantity,
            'notes': reason
        })
    
    def transfer_stock(self, product_id: str, from_location_id: str, 
                      to_location_id: str, quantity: float, notes: str = '') -> Dict:
        """Transferir stock entre ubicaciones"""
        return self.create_movement({
            'productId': product_id,
            'locationId': from_location_id,
            'movementType': 'transfer',
            'quantity': -abs(quantity),
            'destinationLocationId': to_location_id,
            'notes': notes
        })
    
    def update_stock_batch(self, updates: List[Dict], reference_number: str = '', 
                          notes: str = '') -> Dict:
        """Actualizar stock en lote"""
        return self.request('/inventory/stock/batch-update', 'POST', {
            'updates': updates,
            'referenceNumber': reference_number,
            'notes': notes
        })
    
    # ==================== REPORTES ====================
    
    def get_stock_summary(self, location_id: str = None, category_id: str = None) -> Dict:
        """Obtener resumen de stock"""
        params = {}
        if location_id:
            params['locationId'] = location_id
        if category_id:
            params['categoryId'] = category_id
        
        return self.request('/reports/stock-summary', params=params)
    
    def get_movement_summary(self, start_date: str, end_date: str, 
                           group_by: str = None) -> Dict:
        """Obtener resumen de movimientos"""
        params = {'startDate': start_date, 'endDate': end_date}
        if group_by:
            params['groupBy'] = group_by
        
        return self.request('/reports/movement-summary', params=params)
    
    def get_top_products(self, period: str = '30days', product_type: str = 'sold', 
                        limit: int = 10) -> Dict:
        """Obtener productos más vendidos/comprados"""
        params = {'period': period, 'type': product_type, 'limit': limit}
        return self.request('/reports/top-products', params=params)
    
    def export_report(self, report_type: str, format: str = 'csv', **params) -> bytes:
        """Exportar reporte"""
        params['format'] = format
        
        accept_headers = {
            'csv': 'text/csv',
            'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'pdf': 'application/pdf'
        }
        
        headers = {'Accept': accept_headers.get(format, 'application/json')}
        
        response = self.session.get(
            f"{self.base_url}/reports/{report_type}/export",
            params=params,
            headers={**self._get_auth_headers(), **headers},
            timeout=self.timeout
        )
        
        if response.ok:
            return response.content
        else:
            raise APIError('EXPORT_ERROR', 'Failed to export report', response.status_code)
    
    # ==================== ALERTAS ====================
    
    def get_alerts(self, status: str = None, product_id: str = None) -> List[Dict]:
        """Obtener alertas"""
        params = {}
        if status:
            params['status'] = status
        if product_id:
            params['productId'] = product_id
        
        return self.request('/alerts', params=params)
    
    def create_alert(self, alert_data: Dict) -> Dict:
        """Crear alerta"""
        return self.request('/alerts', 'POST', alert_data)
    
    def update_alert(self, alert_id: str, alert_data: Dict) -> Dict:
        """Actualizar alerta"""
        return self.request(f'/alerts/{alert_id}', 'PUT', alert_data)
    
    def delete_alert(self, alert_id: str) -> None:
        """Eliminar alerta"""
        self.request(f'/alerts/{alert_id}', 'DELETE')
    
    def get_active_alerts(self) -> List[Dict]:
        """Obtener alertas activas"""
        return self.get_alerts(status='active')
    
    # ==================== WEBHOOKS ====================
    
    def get_webhooks(self) -> List[Dict]:
        """Obtener webhooks"""
        return self.request('/webhooks')
    
    def create_webhook(self, webhook_data: Dict) -> Dict:
        """Crear webhook"""
        return self.request('/webhooks', 'POST', webhook_data)
    
    def get_webhook(self, webhook_id: str) -> Dict:
        """Obtener webhook específico"""
        return self.request(f'/webhooks/{webhook_id}')
    
    def update_webhook(self, webhook_id: str, webhook_data: Dict) -> Dict:
        """Actualizar webhook"""
        return self.request(f'/webhooks/{webhook_id}', 'PUT', webhook_data)
    
    def delete_webhook(self, webhook_id: str) -> None:
        """Eliminar webhook"""
        self.request(f'/webhooks/{webhook_id}', 'DELETE')
    
    def test_webhook(self, webhook_id: str, test_data: Dict = None) -> Dict:
        """Probar webhook"""
        return self.request(f'/webhooks/{webhook_id}/test', 'POST', test_data or {})
    
    def get_webhook_stats(self, webhook_id: str) -> Dict:
        """Obtener estadísticas de webhook"""
        return self.request(f'/webhooks/{webhook_id}/stats')
    
    def get_webhook_logs(self, webhook_id: str, limit: int = 50, offset: int = 0) -> Dict:
        """Obtener logs de webhook"""
        params = {'limit': limit, 'offset': offset}
        return self.request(f'/webhooks/{webhook_id}/logs', params=params)
    
    # ==================== USUARIOS (ADMIN) ====================
    
    def get_users(self, role: str = None, is_active: bool = None) -> List[Dict]:
        """Obtener usuarios"""
        params = {}
        if role:
            params['role'] = role
        if is_active is not None:
            params['isActive'] = str(is_active).lower()
        
        return self.request('/users', params=params)
    
    def create_user(self, user_data: Dict) -> Dict:
        """Crear usuario"""
        return self.request('/users', 'POST', user_data)
    
    def get_user(self, user_id: str) -> Dict:
        """Obtener usuario específico"""
        return self.request(f'/users/{user_id}')
    
    def update_user(self, user_id: str, user_data: Dict) -> Dict:
        """Actualizar usuario"""
        return self.request(f'/users/{user_id}', 'PUT', user_data)
    
    def deactivate_user(self, user_id: str) -> Dict:
        """Desactivar usuario"""
        return self.request(f'/users/{user_id}/deactivate', 'PATCH')
    
    def activate_user(self, user_id: str) -> Dict:
        """Activar usuario"""
        return self.request(f'/users/{user_id}/activate', 'PATCH')
    
    # ==================== UTILIDADES DE ALTO NIVEL ====================
    
    def ensure_stock(self, product_id: str, location_id: str, minimum_quantity: float) -> Dict:
        """Asegurar stock mínimo"""
        stock = self.get_product_stock(product_id, location_id)
        current_stock = stock[0]['quantity'] if stock else 0
        
        if current_stock < minimum_quantity:
            needed = minimum_quantity - current_stock
            self.create_movement({
                'productId': product_id,
                'locationId': location_id,
                'movementType': 'in',
                'quantity': needed,
                'notes': f'Reposición automática - mínimo requerido: {minimum_quantity}'
            })
            
            return {'restocked': True, 'quantity': needed}
        
        return {'restocked': False, 'currentStock': current_stock}
    
    def get_low_stock_products(self, threshold: float = None) -> List[Dict]:
        """Obtener productos con stock bajo"""
        params = {'lowStock': True}
        if threshold:
            params['threshold'] = threshold
        
        return self.get_stock_levels(**params)
    
    def bulk_stock_update(self, updates: List[Dict], batch_size: int = 100) -> List[Dict]:
        """Actualizar stock en lotes"""
        results = []
        
        for i in range(0, len(updates), batch_size):
            batch = updates[i:i + batch_size]
            result = self.update_stock_batch(batch, f'BULK-{int(time.time())}-{i}')
            results.append(result)
        
        return results
    
    def get_inventory_value(self, location_id: str = None) -> Dict:
        """Obtener valor total del inventario"""
        params = {}
        if location_id:
            params['locationId'] = location_id
        
        summary = self.get_stock_summary(**params)
        return {
            'totalValue': summary['totalValue'],
            'totalProducts': summary['totalProducts'],
            'averageValue': summary['totalValue'] / summary['totalProducts'] if summary['totalProducts'] > 0 else 0
        }
    
    # ==================== CONTEXT MANAGERS ====================
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.access_token:
            try:
                self.logout()
            except:
                pass  # Ignorar errores al cerrar sesión

# ==================== EJEMPLOS DE USO ====================

def examples():
    """Ejemplos de uso del SDK"""
    
    # Configurar logging
    logging.basicConfig(level=logging.INFO)
    
    # Inicializar cliente
    client = InventoryAPI()
    
    try:
        # 1. Login
        client.login('admin@empresa.com', 'password123')
        print('✅ Login exitoso')
        
        # 2. Crear producto
        product = client.create_product({
            'sku': 'LAPTOP-001',
            'name': 'Laptop Dell Inspiron 15',
            'description': 'Laptop para uso empresarial',
            'categoryId': '123e4567-e89b-12d3-a456-426614174000',
            'unitPrice': 1500000.00,
            'unitOfMeasure': 'unidad'
        })
        print(f'✅ Producto creado: {product["name"]}')
        
        # 3. Agregar stock inicial
        client.create_movement({
            'productId': product['id'],
            'locationId': '123e4567-e89b-12d3-a456-426614174001',
            'movementType': 'in',
            'quantity': 50,
            'referenceNumber': 'INITIAL-STOCK',
            'notes': 'Stock inicial'
        })
        print('✅ Stock inicial agregado')
        
        # 4. Consultar stock
        stock = client.get_product_stock(product['id'])
        print(f'📦 Stock actual: {stock[0]["quantity"]}')
        
        # 5. Crear alerta de stock bajo
        client.create_alert({
            'productId': product['id'],
            'alertType': 'low_stock',
            'threshold': 10,
            'enabled': True,
            'notificationMethods': ['email']
        })
        print('🔔 Alerta creada')
        
        # 6. Obtener reporte de inventario
        summary = client.get_stock_summary()
        print(f'📊 Resumen de inventario: {summary["totalProducts"]} productos, valor total: ${summary["totalValue"]:,.2f}')
        
        # 7. Configurar webhook
        webhook = client.create_webhook({
            'url': 'https://mi-sistema.com/webhooks/inventario',
            'events': ['inventory.stock.low', 'product.created'],
            'secret': 'mi-secreto-seguro',
            'active': True
        })
        print(f'🔗 Webhook configurado: {webhook["id"]}')
        
        # 8. Exportar reporte
        csv_data = client.export_report('stock-summary', 'csv')
        with open('stock-summary.csv', 'wb') as f:
            f.write(csv_data)
        print('📄 Reporte exportado a CSV')
        
    except APIError as e:
        print(f'❌ Error de API: {e}')
        print(f'Detalles: {e.details}')
    except Exception as e:
        print(f'❌ Error: {e}')
    finally:
        # Logout automático
        try:
            client.logout()
            print('👋 Logout exitoso')
        except:
            pass

# Ejemplo con context manager
def example_with_context_manager():
    """Ejemplo usando context manager para manejo automático de sesión"""
    
    with InventoryAPI() as client:
        # Login automático si se configuran credenciales
        client.login('admin@empresa.com', 'password123')
        
        # Obtener productos con stock bajo
        low_stock_products = client.get_low_stock_products()
        print(f'Productos con stock bajo: {len(low_stock_products)}')
        
        # Obtener valor total del inventario
        inventory_value = client.get_inventory_value()
        print(f'Valor total del inventario: ${inventory_value["totalValue"]:,.2f}')
        
        # El logout se hace automáticamente al salir del context

# Ejemplo de manejo de webhooks
class WebhookHandler:
    """Manejador de webhooks"""
    
    def __init__(self, client: InventoryAPI):
        self.client = client
    
    def process_webhook(self, webhook_data: Dict):
        """Procesar webhook recibido"""
        event = webhook_data.get('event')
        data = webhook_data.get('data', {})
        
        if event == 'inventory.stock.low':
            self.handle_low_stock(data)
        elif event == 'product.created':
            self.handle_product_created(data)
        elif event == 'inventory.movement.created':
            self.handle_movement_created(data)
    
    def handle_low_stock(self, data: Dict):
        """Manejar alerta de stock bajo"""
        product = data['product']
        stock = data['stock']
        
        print(f'⚠️ Stock bajo para {product["name"]}: {stock["currentQuantity"]} unidades')
        
        # Crear orden de compra automática si el stock es crítico
        if stock['currentQuantity'] < 5:
            print('🛒 Creando orden de compra automática...')
            # Lógica para crear orden de compra
    
    def handle_product_created(self, data: Dict):
        """Manejar creación de producto"""
        product = data['product']
        print(f'📦 Nuevo producto creado: {product["name"]}')
        
        # Configurar stock inicial automáticamente
        try:
            self.client.create_movement({
                'productId': product['id'],
                'locationId': 'default-location-id',
                'movementType': 'in',
                'quantity': 10,
                'notes': 'Stock inicial automático'
            })
            print('✅ Stock inicial configurado automáticamente')
        except APIError as e:
            print(f'❌ Error configurando stock inicial: {e}')
    
    def handle_movement_created(self, data: Dict):
        """Manejar creación de movimiento"""
        movement = data['movement']
        product = data['product']
        
        print(f'📋 Nuevo movimiento: {movement["movementType"]} {movement["quantity"]} de {product["name"]}')

if __name__ == '__main__':
    examples()