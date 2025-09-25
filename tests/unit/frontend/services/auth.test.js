import { authService } from '../../../../src/frontend/src/services/auth';
import api from '../../../../src/frontend/src/services/api';

jest.mock('../../../../src/frontend/src/services/api');

// Mock localStorage
const localStorageMock = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn(),
};
global.localStorage = localStorageMock;

describe('AuthService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    localStorageMock.getItem.mockClear();
    localStorageMock.setItem.mockClear();
    localStorageMock.removeItem.mockClear();
  });

  describe('login', () => {
    it('should login successfully and store tokens', async () => {
      const mockResponse = {
        data: {
          data: {
            user: { id: '1', email: 'test@example.com', firstName: 'John' },
            accessToken: 'mock-access-token',
            refreshToken: 'mock-refresh-token'
          }
        }
      };

      api.post.mockResolvedValue(mockResponse);

      const result = await authService.login('test@example.com', 'password');

      expect(api.post).toHaveBeenCalledWith('/auth/login', {
        email: 'test@example.com',
        password: 'password'
      });

      expect(localStorageMock.setItem).toHaveBeenCalledWith('accessToken', 'mock-access-token');
      expect(localStorageMock.setItem).toHaveBeenCalledWith('refreshToken', 'mock-refresh-token');
      expect(localStorageMock.setItem).toHaveBeenCalledWith('user', JSON.stringify(mockResponse.data.data.user));

      expect(result).toEqual(mockResponse.data.data.user);
    });

    it('should throw error on failed login', async () => {
      const mockError = new Error('Invalid credentials');
      api.post.mockRejectedValue(mockError);

      await expect(authService.login('test@example.com', 'wrong-password'))
        .rejects.toThrow('Invalid credentials');

      expect(localStorageMock.setItem).not.toHaveBeenCalled();
    });
  });

  describe('logout', () => {
    it('should logout and clear storage', async () => {
      api.post.mockResolvedValue({});

      await authService.logout();

      expect(api.post).toHaveBeenCalledWith('/auth/logout');
      expect(localStorageMock.removeItem).toHaveBeenCalledWith('accessToken');
      expect(localStorageMock.removeItem).toHaveBeenCalledWith('refreshToken');
      expect(localStorageMock.removeItem).toHaveBeenCalledWith('user');
    });

    it('should clear storage even if API call fails', async () => {
      api.post.mockRejectedValue(new Error('Network error'));

      await authService.logout();

      expect(localStorageMock.removeItem).toHaveBeenCalledWith('accessToken');
      expect(localStorageMock.removeItem).toHaveBeenCalledWith('refreshToken');
      expect(localStorageMock.removeItem).toHaveBeenCalledWith('user');
    });
  });

  describe('getProfile', () => {
    it('should fetch user profile', async () => {
      const mockUser = { id: '1', email: 'test@example.com', firstName: 'John' };
      api.get.mockResolvedValue({
        data: { data: { user: mockUser } }
      });

      const result = await authService.getProfile();

      expect(api.get).toHaveBeenCalledWith('/auth/profile');
      expect(result).toEqual(mockUser);
    });
  });

  describe('getCurrentUser', () => {
    it('should return parsed user from localStorage', () => {
      const mockUser = { id: '1', email: 'test@example.com' };
      localStorageMock.getItem.mockReturnValue(JSON.stringify(mockUser));

      const result = authService.getCurrentUser();

      expect(localStorageMock.getItem).toHaveBeenCalledWith('user');
      expect(result).toEqual(mockUser);
    });

    it('should return null if no user in localStorage', () => {
      localStorageMock.getItem.mockReturnValue(null);

      const result = authService.getCurrentUser();

      expect(result).toBeNull();
    });

    it('should return null if invalid JSON in localStorage', () => {
      localStorageMock.getItem.mockReturnValue('invalid-json');

      const result = authService.getCurrentUser();

      expect(result).toBeNull();
    });
  });

  describe('getToken', () => {
    it('should return access token from localStorage', () => {
      localStorageMock.getItem.mockReturnValue('mock-token');

      const result = authService.getToken();

      expect(localStorageMock.getItem).toHaveBeenCalledWith('accessToken');
      expect(result).toBe('mock-token');
    });
  });

  describe('isAuthenticated', () => {
    it('should return true if token exists', () => {
      localStorageMock.getItem.mockReturnValue('mock-token');

      const result = authService.isAuthenticated();

      expect(result).toBe(true);
    });

    it('should return false if no token', () => {
      localStorageMock.getItem.mockReturnValue(null);

      const result = authService.isAuthenticated();

      expect(result).toBe(false);
    });
  });
});