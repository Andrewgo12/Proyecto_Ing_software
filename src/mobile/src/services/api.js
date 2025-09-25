import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';

const API_URL = 'http://localhost:3001/api'; // Change for production

const api = axios.create({
  baseURL: API_URL,
  timeout: 10000,
});

// Request interceptor
api.interceptors.request.use(
  async (config) => {
    const token = await AsyncStorage.getItem('accessToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const refreshToken = await AsyncStorage.getItem('refreshToken');
        if (refreshToken) {
          const response = await axios.post(`${API_URL}/auth/refresh`, {
            refreshToken,
          });
          
          const { accessToken } = response.data.data;
          await AsyncStorage.setItem('accessToken', accessToken);
          
          return api(originalRequest);
        }
      } catch (refreshError) {
        await AsyncStorage.multiRemove(['accessToken', 'refreshToken', 'user']);
        return Promise.reject(refreshError);
      }
    }

    return Promise.reject(error);
  }
);

export const apiService = {
  // Auth
  async login(email, password) {
    const response = await api.post('/auth/login', { email, password });
    const { user, accessToken, refreshToken } = response.data.data;
    
    await AsyncStorage.multiSet([
      ['accessToken', accessToken],
      ['refreshToken', refreshToken],
      ['user', JSON.stringify(user)]
    ]);
    
    return user;
  },

  async logout() {
    try {
      await api.post('/auth/logout');
    } finally {
      await AsyncStorage.multiRemove(['accessToken', 'refreshToken', 'user']);
    }
  },

  // Dashboard
  async getDashboardMetrics() {
    const response = await api.get('/reports/dashboard');
    return response.data.data;
  },

  // Products
  async getProducts(params = {}) {
    const response = await api.get('/products', { params });
    return response.data;
  },

  async createProduct(productData) {
    const response = await api.post('/products', productData);
    return response.data.data;
  },

  // Inventory
  async getStock(params = {}) {
    const response = await api.get('/inventory/stock', { params });
    return response.data.data;
  },

  async createMovement(movementData) {
    const response = await api.post('/inventory/movements', movementData);
    return response.data.data;
  },

  async getLowStock(locationId) {
    const params = locationId ? { location_id: locationId } : {};
    const response = await api.get('/inventory/stock/low', { params });
    return response.data.data;
  }
};

export default api;