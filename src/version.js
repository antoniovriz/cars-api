const fs = require('fs');

const APP_VERSION = JSON.parse(fs.readFileSync('./package.json', 'utf8')).version;

module.exports = {
    APP_VERSION
};