const express = require('express');
const carRoutes = require('./routes');
const db = require('./db');
const { log } = require('./log');
const fs = require('fs');
const APP_VERSION = JSON.parse(fs.readFileSync('./package.json', 'utf8')).version;

const startServer = async () => {
    // Initialize the database
    await db.initializeDatabase();

    const app = express();
    const port = process.env.PORT || 7007;

    app.use(express.json());
    app.use(carRoutes);

    app.listen(port, () => {
        log(`Server listening on port ${port}`);
    });
};

startServer().catch((err) => {
    log(`Failed to start server: ${err.message}`, 'error');
});

