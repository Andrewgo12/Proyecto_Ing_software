import axios from 'axios';
import api from '../../../../src/frontend/src/services/api';

jest.mock('axios');
const mockedAxios = axios;

describe('API Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should make GET request', async () => {
    const mockData = { data: { success: true, data: [] } };
    mockedAxios.get.mockResolvedValue(mockData);

    const result = await api.get('/products');

    expect(mockedAxios.get).toHaveBeenCalledWith('/products');
    expect(result).toEqual(mockData);
  });

  it('should make POST request', async () => {
    const mockData = { data: { success: true, data: { id: '1' } } };
    const postData = { name: 'Test Product' };
    
    mockedAxios.post.mockResolvedValue(mockData);

    const result = await api.post('/products', postData);

    expect(mockedAxios.post).toHaveBeenCalledWith('/products', postData);
    expect(result).toEqual(mockData);
  });

  it('should handle request errors', async () => {
    const errorResponse = {
      response: { status: 400, data: { message: 'Bad Request' } }
    };
    
    mockedAxios.get.mockRejectedValue(errorResponse);

    await expect(api.get('/products')).rejects.toEqual(errorResponse);
  });
});