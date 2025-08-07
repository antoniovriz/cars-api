const fs = require('fs');

const APP_VERSION = JSON.parse(
    fs.readFileSync(
        process.env.NODE_ENV === 'production' ? '/app/dist/package.json' : '/app/package.json', 'utf8'
    )
).version;

module.exports = {
    APP_VERSION
};