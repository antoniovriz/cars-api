const express = require('express');
const carRoutes = require('./routes');
const db = require('./db');

const startServer = async () => {
    // Initialize the database
    await db.initializeDatabase();

    const app = express();
    const port = process.env.PORT || 7007;

    app.use(express.json());
    app.use(carRoutes);

    app.listen(port, () => {
        console.log(`Server listening on port ${port}`);
    });
};

startServer().catch((err) => {
    console.error('Failed to start server:', err);
});

