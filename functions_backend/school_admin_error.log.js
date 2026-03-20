// school_admin_error.log
// This file logs the latest error from createSchoolAdminUser

const fs = require('fs');
const path = require('path');

const logFilePath = path.join(__dirname, 'school_admin_error.log');

function logLatestError(error) {
  const logEntry = `${new Date().toISOString()}\n${JSON.stringify(error, null, 2)}\n`;
  fs.writeFileSync(logFilePath, logEntry, { flag: 'w' });
}

module.exports = { logLatestError, logFilePath };
