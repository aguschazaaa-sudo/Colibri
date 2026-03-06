import * as admin from "firebase-admin";

admin.initializeApp();

// Export payments module
export const payments = require("./payments");

// Export cron module
export const cron = require("./cron");

// Export background workers
export const workers = require("./workers");

// Export appointments module
export const appointments = require("./appointments");

// Export auth module
export const auth = require("./auth");

// Export admin module (temporary migrations)
export const migrations = require("./admin");



