const request = require('supertest');
const app = require('../../app/server/server');

describe('Todo API', () => {
  let server;

  beforeAll(() => {
    server = app.listen(0); // Use random port for testing
  });

  afterAll((done) => {
    server.close(done);
  });

  describe('GET /api/health', () => {
    it('should return health status', async () => {
      const response = await request(app).get('/api/health');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'OK');
      expect(response.body).toHaveProperty('timestamp');
    });
  });

  describe('GET /api/todos', () => {
    it('should return all todos', async () => {
      const response = await request(app).get('/api/todos');
      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThan(0);
      expect(response.body[0]).toHaveProperty('id');
      expect(response.body[0]).toHaveProperty('text');
      expect(response.body[0]).toHaveProperty('completed');
    });
  });

  describe('POST /api/todos', () => {
    it('should create a new todo', async () => {
      const newTodo = { text: 'Test todo', completed: false };
      const response = await request(app)
        .post('/api/todos')
        .send(newTodo);
      
      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
      expect(response.body.text).toBe('Test todo');
      expect(response.body.completed).toBe(false);
      expect(response.body).toHaveProperty('createdAt');
    });

    it('should return 400 for empty text', async () => {
      const response = await request(app)
        .post('/api/todos')
        .send({ text: '', completed: false });
      
      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });

    it('should return 400 for missing text', async () => {
      const response = await request(app)
        .post('/api/todos')
        .send({ completed: false });
      
      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('PUT /api/todos/:id', () => {
    it('should update an existing todo', async () => {
      // First create a todo
      const createResponse = await request(app)
        .post('/api/todos')
        .send({ text: 'Todo to update', completed: false });
      
      const todoId = createResponse.body.id;
      
      // Update the todo
      const updateResponse = await request(app)
        .put(`/api/todos/${todoId}`)
        .send({ completed: true });
      
      expect(updateResponse.status).toBe(200);
      expect(updateResponse.body.completed).toBe(true);
      expect(updateResponse.body).toHaveProperty('updatedAt');
    });

    it('should return 404 for non-existent todo', async () => {
      const response = await request(app)
        .put('/api/todos/nonexistent')
        .send({ completed: true });
      
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('DELETE /api/todos/:id', () => {
    it('should delete an existing todo', async () => {
      // First create a todo
      const createResponse = await request(app)
        .post('/api/todos')
        .send({ text: 'Todo to delete', completed: false });
      
      const todoId = createResponse.body.id;
      
      // Delete the todo
      const deleteResponse = await request(app)
        .delete(`/api/todos/${todoId}`);
      
      expect(deleteResponse.status).toBe(204);
      
      // Verify it's deleted
      const getResponse = await request(app).get('/api/todos');
      const deletedTodo = getResponse.body.find(todo => todo.id === todoId);
      expect(deletedTodo).toBeUndefined();
    });

    it('should return 404 for non-existent todo', async () => {
      const response = await request(app)
        .delete('/api/todos/nonexistent');
      
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('Error handling', () => {
    it('should return 404 for unknown routes', async () => {
      const response = await request(app).get('/api/unknown');
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error');
    });
  });
});
