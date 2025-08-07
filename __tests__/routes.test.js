const express = require('express');
const request = require('supertest');
const db = require('../src/db');
const router = require('../src/routes');

jest.mock('../src/db'); // mockeamos la base de datos

const app = express();
app.use(express.json());
app.use(router);

describe('Cars API', () => {
  beforeEach(() => {
    jest.clearAllMocks(); // limpiamos los mocks antes de cada test
  });

  // Health check
  describe('GET /', () => {
    it('should return 200 and health check message', async () => {
      const res = await request(app).get('/');
      expect(res.status).toBe(200);
      expect(res.body).toEqual({ message: 'OK' });
    });
  });

  // POST /cars
  describe('POST /cars', () => {
    it('should create a new Volkswagen car', async () => {
      const mockCar = { id: 1, brand: 'Volkswagen', model: 'Golf', year: 2020, color: 'Blue' };
      db.saveCar.mockResolvedValue(mockCar);

      const res = await request(app)
        .post('/cars')
        .send(mockCar);

      expect(res.status).toBe(201);
      expect(res.body).toEqual(mockCar);
      expect(db.saveCar).toHaveBeenCalledWith('Volkswagen', 'Golf', 2020, 'Blue');
    });

    it('should return 400 if required fields are missing', async () => {
      const res = await request(app)
        .post('/cars')
        .send({ brand: 'Volkswagen' });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error');
    });
  });

  // GET /cars/:id
  describe('GET /cars/:id', () => {
    it('should return a Volkswagen car by ID', async () => {
      const car = { id: 1, brand: 'Volkswagen', model: 'Golf', year: 2020, color: 'Blue' };
      db.findCarById.mockResolvedValue(car);

      const res = await request(app).get('/cars/1');

      expect(res.status).toBe(200);
      expect(res.body).toEqual(car);
    });

    it('should return 404 if car not found', async () => {
      db.findCarById.mockResolvedValue(null);

      const res = await request(app).get('/cars/999');

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 400 for invalid ID', async () => {
      const res = await request(app).get('/cars/invalid');

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error');
    });
  });

  // GET /cars
  describe('GET /cars', () => {
    it('should return a list of Volkswagen cars', async () => {
      const cars = [
        { id: 1, brand: 'Volkswagen', model: 'Golf', year: 2020, color: 'Blue' },
        { id: 2, brand: 'Volkswagen', model: 'Passat', year: 2021, color: 'Red' }
      ];
      db.findAllCars.mockResolvedValue(cars);

      const res = await request(app).get('/cars');

      expect(res.status).toBe(200);
      expect(res.body).toEqual(cars);
    });
  });

  // PUT /cars/:id
  describe('PUT /cars/:id', () => {
    it('should update a Volkswagen car by ID', async () => {
      const updatedCar = { id: 1, brand: 'Volkswagen', model: 'Tiguan', year: 2022, color: 'Black' };
      db.updateCar.mockResolvedValue(updatedCar);

      const res = await request(app)
        .put('/cars/1')
        .send(updatedCar);

      expect(res.status).toBe(200);
      expect(res.body).toEqual(updatedCar);
    });

    it('should return 404 if car not found', async () => {
      db.updateCar.mockResolvedValue(null);

      const res = await request(app)
        .put('/cars/99')
        .send({ brand: 'Volkswagen', model: 'Tiguan', year: 2022, color: 'Black' });

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 400 if missing fields', async () => {
      const res = await request(app)
        .put('/cars/1')
        .send({ brand: 'Volkswagen' });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should return 400 if invalid ID', async () => {
      const res = await request(app)
        .put('/cars/invalid')
        .send({ brand: 'Volkswagen', model: 'Tiguan', year: 2022, color: 'Black' });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error');
    });
  });

  // DELETE /cars/:id
  describe('DELETE /cars/:id', () => {
    it('should delete a Volkswagen car by ID', async () => {
      db.deleteCar.mockResolvedValue();

      const res = await request(app).delete('/cars/1');

      expect(res.status).toBe(204);
      expect(db.deleteCar).toHaveBeenCalledWith(1);
    });

    it('should return 400 if ID is invalid', async () => {
      const res = await request(app).delete('/cars/invalid');

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error');
    });
  });
});
