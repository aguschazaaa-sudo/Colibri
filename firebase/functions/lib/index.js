"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.appointments = exports.workers = exports.cron = exports.payments = void 0;
const admin = require("firebase-admin");
admin.initializeApp();
// Export payments module
exports.payments = require("./payments");
// Export cron module
exports.cron = require("./cron");
// Export background workers
exports.workers = require("./workers");
// Export appointments module
exports.appointments = require("./appointments");
//# sourceMappingURL=index.js.map