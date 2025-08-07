const express = require('express');
const db = require('./db');
const { log } = require('./log');
const router = express.Router();

router.post('/cars', async (req, res) => {
    try {
        const { brand, model, year, color } = req.body;
        if (!brand || !model || !year || !color) {
            return res.status(400).json({ error: 'All fields (brand, model, year, color) are required' });
        }
        const car = await db.saveCar(brand, model, year, color);
        res.status(201).json(car);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.get('/cars/:id', async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        if (isNaN(id)) {
            return res.status(400).json({ error: 'Invalid ID' });
        }
        const car = await db.findCarById(id);
        if (!car) {
            return res.status(404).json({ error: `Car with ID ${id} not found` });
        }
        res.json(car);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.get('/cars', async (req, res) => {
    try {
        const cars = await db.findAllCars();
        res.json(cars);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.put('/cars/:id', async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        const { brand, model, year, color } = req.body;
        if (isNaN(id)) {
            return res.status(400).json({ error: 'Invalid ID' });
        }
        if (!brand || !model || !year || !color) {
            return res.status(400).json({ error: 'All fields (brand, model, year, color) are required' });
        }
        const car = await db.updateCar(id, brand, model, year, color);
        if (!car) {
            return res.status(404).json({ error: `Car with ID ${id} not found` });
        }
        res.json(car);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.delete('/cars/:id', async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        if (isNaN(id)) {
            return res.status(400).json({ error: 'Invalid ID' });
        }
        await db.deleteCar(id);
        res.status(204).send();
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Health check
router.get('/', async (req, res) => {

    const dbIsAlive = await db.isAlive();
    
    log(`Health check: Database is ${dbIsAlive ? 'alive' : 'not reachable'}`);

    if (!dbIsAlive) {
        return res.status(500).json({ error: 'Database is not reachable' });
    }

    res.status(200).json(
        { 
          message: `APP IS RUNNING`,
          version: `v${APP_VERSION}`,
          dbIsAlive 
        }
    );
});

module.exports = router;
