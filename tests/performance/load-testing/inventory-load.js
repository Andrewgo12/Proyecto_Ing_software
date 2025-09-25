import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 20 },
    { duration: '5m', target: 20 },
    { duration: '2m', target: 50 },
    { duration: '5m', target: 50 },
    { duration: '2m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.1'],
  },
};

const BASE_URL = 'http://localhost:3001/api';

export default function() {
  const headers = {
    'Authorization': 'Bearer test-token',
    'Content-Type': 'application/json',
  };

  let response = http.get(`${BASE_URL}/inventory/stock`, { headers });
  
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });

  response = http.get(`${BASE_URL}/products`, { headers });
  
  check(response, {
    'products status is 200': (r) => r.status === 200,
  });

  sleep(1);
}