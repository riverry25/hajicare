'use strict';

class BackendError extends Error {
  constructor(code, message, details) {
    super(message);
    this.name = 'BackendError';
    this.code = code;
    this.details = details;
  }
}

module.exports = {BackendError};
