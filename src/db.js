const { Pool, Client } = require('pg');
const Car = require('./car');
const { log } = require('./log');
// Configura el pool de conexiones
const pool = new Pool({
    user: process.env.PG_USER,
    host: process.env.PG_HOST,
    database: process.env.PG_DATABASE,
    password: process.env.PG_PASSWORD,
    port: process.env.PG_PORT || 5432,
});

// Inicializa la base de datos y la tabla
const initializeDatabase = async () => {
    const client = new Client({
        user: process.env.PG_USER,
        host: process.env.PG_HOST,
        database: 'postgres',
        password: process.env.PG_PASSWORD,
        port: process.env.PG_PORT || 5432,
    });

    try {
        log('Connecting to PostgreSQL...');
        await client.connect();



        log(`Checking if database ${process.env.PG_DATABASE} exists...`);
        const dbExists = await client.query(`
            SELECT 1 FROM pg_database WHERE datname = $1
        `, [process.env.PG_DATABASE]);

        log(`Database ${process.env.PG_DATABASE} exists: ${dbExists.rowCount > 0}`);

        if (dbExists.rowCount === 0) {
            await client.query(`CREATE DATABASE ${escapeIdentifier(process.env.PG_DATABASE)}`);
            log(`Database ${process.env.PG_DATABASE} created`);
        } else {
            log(`Database ${process.env.PG_DATABASE} already exists`);
        }

        await client.end();

        const createTableQuery = `
            CREATE TABLE IF NOT EXISTS cars (
                id SERIAL PRIMARY KEY,
                brand VARCHAR(100) NOT NULL,
                model VARCHAR(100) NOT NULL,
                year INTEGER NOT NULL,
                color VARCHAR(50) NOT NULL
            )
        `;
        await pool.query(createTableQuery);
        log('Table cars created or already exists');
    } catch (error) {
        log(`Error initializing database: ${error.message}`, 'error');
        throw error;
    }
};

const saveCar = async (brand, model, year, color) => {
    const query = `
        INSERT INTO cars (brand, model, year, color)
        VALUES ($1, $2, $3, $4)
        RETURNING id, brand, model, year, color
    `;
    const result = await pool.query(query, [brand, model, year, color]);
    const car = result.rows[0];
    return new Car(car.id, car.brand, car.model, car.year, car.color);
};

const findCarById = async (id) => {
    const query = 'SELECT * FROM cars WHERE id = $1';
    const result = await pool.query(query, [id]);
    if (result.rows.length === 0) return null;
    const car = result.rows[0];
    return new Car(car.id, car.brand, car.model, car.year, car.color);
};

const findAllCars = async () => {
    const query = 'SELECT * FROM cars';
    const result = await pool.query(query);
    return result.rows.map(car => new Car(car.id, car.brand, car.model, car.year, car.color));
};

const updateCar = async (id, brand, model, year, color) => {
    const query = `
        UPDATE cars
        SET brand = $1, model = $2, year = $3, color = $4
        WHERE id = $5
        RETURNING id, brand, model, year, color
    `;
    const result = await pool.query(query, [brand, model, year, color, id]);
    if (result.rows.length === 0) return null;
    const car = result.rows[0];
    return new Car(car.id, car.brand, car.model, car.year, car.color);
};

const deleteCar = async (id) => {
    const query = 'DELETE FROM cars WHERE id = $1';
    await pool.query(query, [id]);
};

const isAlive = async () => {
    try {
        const res = await pool.query('SELECT NOW()');
       return res.rowCount > 0;
    } catch (error) {
        console.error('Database is not reachable:', error.message);
        return false;
    }
};

function escapeIdentifier(identifier) {
    return '"' + identifier.replace(/"/g, '""') + '"';
}

module.exports = {
    saveCar,
    findCarById,
    findAllCars,
    isAlive,
    updateCar,
    deleteCar,
    initializeDatabase
};
