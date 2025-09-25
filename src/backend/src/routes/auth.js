const express = require('express');
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/auth');
const validation = require('../middleware/validation');
const Joi = require('joi');

const router = express.Router();

// Validation schemas
const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required()
});

const registerSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(8).required(),
  firstName: Joi.string().min(2).max(50).required(),
  lastName: Joi.string().min(2).max(50).required(),
  role: Joi.string().valid('admin', 'manager', 'warehouse', 'sales', 'viewer').default('viewer')
});

const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required()
});

// Routes
router.post('/login', validation(loginSchema), authController.login);
router.post('/register', validation(registerSchema), authController.register);
router.post('/refresh', validation(refreshTokenSchema), authController.refreshToken);
router.post('/logout', authMiddleware, authController.logout);
router.get('/profile', authMiddleware, authController.getProfile);

module.exports = router;