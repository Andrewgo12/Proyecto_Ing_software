import http from 'k6/http';
import { check } from 'k6';

export let options = {
  vus: 10,
  duration: '30s',
  thresholds: {
    http_req_duration: ['p(95)<200'],
  },
};

const BASE_URL = 'http://localhost:3001/api';

export default function() {
  const endpoints = [
    '/products',
    '/inventory/stock',
    '/reports/dashboard',
    '/categories',
    '/locations'
  ];

  endpoints.forEach(endpoint => {
    let response = http.get(`${BASE_URL}${endpoint}`, {
      headers: { 'Authorization': 'Bearer test-token' }
    });
    
    check(response, {
      [`${endpoint} status is 200`]: (r) => r.status === 200,
      [`${endpoint} response time < 200ms`]: (r) => r.timings.duration < 200,
    });
  });
}