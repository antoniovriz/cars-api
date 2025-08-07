
const log = (message, level = 'info') => {
    const timestamp = new Date().toUTCString();
    console.log(JSON.stringify({
        timestamp,
        level,
        message
    }));
}

module.exports = {
    log
};