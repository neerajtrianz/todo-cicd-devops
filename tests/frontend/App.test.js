import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import axios from 'axios';
import App from '../../app/src/App';

// Mock axios
jest.mock('axios');

const mockTodos = [
  { id: '1', text: 'Test todo 1', completed: false },
  { id: '2', text: 'Test todo 2', completed: true }
];

describe('App Component', () => {
  beforeEach(() => {
    axios.get.mockResolvedValue({ data: mockTodos });
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('renders todo app header', async () => {
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText('To-Do App')).toBeInTheDocument();
      expect(screen.getByText('Manage your tasks efficiently')).toBeInTheDocument();
    });
  });

  test('loads and displays todos', async () => {
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText('Test todo 1')).toBeInTheDocument();
      expect(screen.getByText('Test todo 2')).toBeInTheDocument();
    });
  });

  test('adds a new todo', async () => {
    const newTodo = { id: '3', text: 'New todo', completed: false };
    axios.post.mockResolvedValue({ data: newTodo });
    
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText('Test todo 1')).toBeInTheDocument();
    });

    const input = screen.getByPlaceholderText('Add a new task...');
    const addButton = screen.getByText('Add Task');

    fireEvent.change(input, { target: { value: 'New todo' } });
    fireEvent.click(addButton);

    await waitFor(() => {
      expect(axios.post).toHaveBeenCalledWith(
        expect.stringContaining('/api/todos'),
        { text: 'New todo', completed: false }
      );
    });
  });

  test('toggles todo completion', async () => {
    const updatedTodo = { id: '1', text: 'Test todo 1', completed: true };
    axios.put.mockResolvedValue({ data: updatedTodo });
    
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText('Test todo 1')).toBeInTheDocument();
    });

    const checkbox = screen.getAllByRole('checkbox')[0];
    fireEvent.click(checkbox);

    await waitFor(() => {
      expect(axios.put).toHaveBeenCalledWith(
        expect.stringContaining('/api/todos/1'),
        { completed: true }
      );
    });
  });

  test('deletes a todo', async () => {
    axios.delete.mockResolvedValue({});
    
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText('Test todo 1')).toBeInTheDocument();
    });

    const deleteButtons = screen.getAllByText('×');
    fireEvent.click(deleteButtons[0]);

    await waitFor(() => {
      expect(axios.delete).toHaveBeenCalledWith(
        expect.stringContaining('/api/todos/1')
      );
    });
  });

  test('displays error message on API failure', async () => {
    axios.get.mockRejectedValue(new Error('API Error'));
    
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText('Failed to load todos. Please try again.')).toBeInTheDocument();
    });
  });

  test('shows empty state when no todos', async () => {
    axios.get.mockResolvedValue({ data: [] });
    
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText('No tasks yet. Add your first task above!')).toBeInTheDocument();
    });
  });

  test('displays completion statistics', async () => {
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText('1 of 2 tasks completed (50%)')).toBeInTheDocument();
    });
  });
});
