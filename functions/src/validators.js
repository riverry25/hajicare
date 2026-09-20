'use strict';

const {BackendError} = require('./errors');

const MAX_SAFE_RADIUS_METERS = 10000;

function requiredString(value, field, maxLength) {
  if (typeof value !== 'string') {
    throw new BackendError('invalid-argument', `${field} harus berupa teks.`);
  }
  const normalized = value.trim();
  if (!normalized) {
    throw new BackendError('invalid-argument', `${field} wajib diisi.`);
  }
  if (normalized.length > maxLength) {
    throw new BackendError(
      'invalid-argument',
      `${field} maksimal ${maxLength} karakter.`,
    );
  }
  return normalized;
}

function optionalString(value, field, maxLength) {
  if (value == null) return null;
  if (typeof value !== 'string') {
    throw new BackendError('invalid-argument', `${field} harus berupa teks.`);
  }
  const normalized = value.trim();
  if (normalized.length > maxLength) {
    throw new BackendError(
      'invalid-argument',
      `${field} maksimal ${maxLength} karakter.`,
    );
  }
  return normalized || null;
}

function normalizedEmail(value) {
  const email = requiredString(value, 'Email', 254).toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new BackendError('invalid-argument', 'Format email tidak valid.');
  }
  return email;
}

function safeRadius(value) {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    throw new BackendError('invalid-argument', 'Radius aman harus berupa angka.');
  }
  if (value <= 0 || value > MAX_SAFE_RADIUS_METERS) {
    throw new BackendError(
      'invalid-argument',
      `Radius aman harus lebih dari 0 dan maksimal ${MAX_SAFE_RADIUS_METERS} meter.`,
    );
  }
  return value;
}

function titleCase(value) {
  return value
    .trim()
    .split(/\s+/)
    .map((word) => {
      if (word.length <= 1 || word === word.toUpperCase()) return word.toUpperCase();
      return `${word[0].toUpperCase()}${word.slice(1)}`;
    })
    .join(' ');
}

module.exports = {
  MAX_SAFE_RADIUS_METERS,
  normalizedEmail,
  optionalString,
  requiredString,
  safeRadius,
  titleCase,
};
