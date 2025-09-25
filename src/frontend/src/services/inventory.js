import api from './api';

export const inventoryService = {
  async getStock(filters = {}) {
    const response = await api.get('/inventory/stock', { params: filters });
    return response.data.data;
  },

  async getLowStock(locationId) {
    const params = locationId ? { location_id: locationId } : {};
    const response = await api.get('/inventory/stock/low', { params });
    return response.data.data;
  },

  async getMovements(filters = {}) {
    const response = await api.get('/inventory/movements', { params: filters });
    return response.data;
  },

  async createMovement(movementData) {
    const response = await api.post('/inventory/movements', movementData);
    return response.data.data;
  },

  async adjustStock(adjustmentData) {
    const response = await api.post('/inventory/adjust', adjustmentData);
    return response.data.data;
  },

  async transferStock(transferData) {
    const response = await api.post('/inventory/transfer', transferData);
    return response.data.data;
  }
};