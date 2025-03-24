import React, { useState, useEffect } from 'react';
import { Box, Button, TextField, Typography, FormControl, InputLabel, Select, MenuItem, Grid, Alert, Paper, Container } from '@mui/material';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { format } from 'date-fns';

const Budget = () => {
  console.log('Budget component rendering');
  const [budgets, setBudgets] = useState([]);
  const [selectedBudget, setSelectedBudget] = useState(null);
  const [newBudget, setNewBudget] = useState({
    name: '',
    amount: '',
    start_date: null,
    end_date: null,
    currency: 'USD',
    is_active: true,
    is_deleted: false,
    frequency: null,
  });
  const [alert, setAlert] = useState({ show: false, severity: 'success', message: '' });

  const token = localStorage.getItem('authToken');
  console.log('Auth token:', token ? 'Present' : 'Missing');

  useEffect(() => {
    console.log('useEffect running');
    if (!token) {
      console.log('No token found, redirecting to login');
      alert("You need to log in.");
      window.location.href = '/';
      return;
    }
    fetchBudgets();
  }, [token]);

  const fetchBudgets = async () => {
    console.log('Fetching budgets...');
    try {
      const response = await fetch('http://localhost:8000/budgets/', {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      console.log('Response status:', response.status);
      const data = await response.json();
      console.log('Fetched budgets:', data);

      if (!response.ok) {
        throw new Error("Failed to fetch budgets");
      }

      setBudgets(data);
    } catch (error) {
      console.error("Error fetching budgets:", error);
      showAlert('error', 'Failed to fetch budgets');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!newBudget.name || !newBudget.amount || !newBudget.start_date || !newBudget.end_date || !newBudget.frequency) {
      showAlert('error', 'Please fill in all required fields');
      return;
    }

    if (new Date(newBudget.end_date) <= new Date(newBudget.start_date)) {
      showAlert('error', 'End date must be after start date');
      return;
    }

    try {
      // For recurring budgets, we need to create a budget for each period
      const startDate = new Date(newBudget.start_date);
      const endDate = new Date(newBudget.end_date);
      
      // Set to first day of month for start date
      startDate.setDate(1);
      
      // Set to last day of month for end date
      endDate.setDate(1);
      endDate.setMonth(endDate.getMonth() + 1);
      endDate.setDate(0);

      // Create array of months between start and end date
      const months = [];
      let currentDate = new Date(startDate);
      
      while (currentDate <= endDate) {
        months.push(new Date(currentDate));
        currentDate.setMonth(currentDate.getMonth() + 1);
      }

      // Create a budget for each month
      for (const month of months) {
        const monthEndDate = new Date(month.getFullYear(), month.getMonth() + 1, 0);
        
        const data = {
          name: `${newBudget.name} - ${month.toLocaleString('default', { month: 'long', year: 'numeric' })}`,
          total_limit: parseFloat(newBudget.amount),
          start_date: format(month, 'yyyy-MM-dd'),
          end_date: format(monthEndDate, 'yyyy-MM-dd'),
          currency: newBudget.currency,
          is_active: newBudget.is_active,
          frequency: newBudget.frequency,
        };

        const response = await fetch('http://localhost:8000/budgets/', {
          method: "POST",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(data),
        });

        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.detail || "Failed to create budget");
        }
      }

      showAlert('success', 'Budget(s) created successfully');
      fetchBudgets();
      resetForm();
    } catch (error) {
      console.error('Error creating budget:', error);
      showAlert('error', error.message || 'Failed to create budget');
    }
  };

  const handleDelete = async (budget) => {
    try {
      // Use the budget name for the URL
      const encodedCategory = encodeURIComponent(budget.name);
      const response = await fetch(`http://localhost:8000/budgets/${encodedCategory}/`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.detail || "Failed to delete budget");
      }

      showAlert('success', 'Budget deleted successfully');
      fetchBudgets();
    } catch (error) {
      console.error('Error deleting budget:', error);
      showAlert('error', error.message || 'Failed to delete budget');
    }
  };

  const resetForm = () => {
    setNewBudget({
      name: '',
      amount: '',
      start_date: null,
      end_date: null,
      currency: 'USD',
      is_active: true,
      is_deleted: false,
      frequency: null,
    });
  };

  const showAlert = (severity, message) => {
    setAlert({ show: true, severity, message });
    setTimeout(() => setAlert({ show: false, severity: '', message: '' }), 5000);
  };

  return (
      <Box sx={{ p: 3 }}>
        <Typography variant="h4" gutterBottom>
          {/* Budget */}
        </Typography>

        {alert.show && (
          <Alert severity={alert.severity} sx={{ mb: 2 }}>
            {alert.message}
          </Alert>
        )}

        <Paper elevation={3} sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>
            Create New Budget
          </Typography>

          <form onSubmit={handleSubmit}>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Budget Name"
                  value={newBudget.name}
                  onChange={(e) => setNewBudget({ ...newBudget, name: e.target.value })}
                  required
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Amount"
                  type="number"
                  value={newBudget.amount}
                  onChange={(e) => setNewBudget({ ...newBudget, amount: e.target.value })}
                  required
                  helperText={newBudget.frequency !== null ? `${newBudget.amount} ${newBudget.frequency}` : ''}
                />
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControl fullWidth required>
                  <InputLabel>Frequency</InputLabel>
                  <Select
                    value={newBudget.frequency}
                    onChange={(e) => setNewBudget({ ...newBudget, frequency: e.target.value })}
                    label="Frequency"
                  >
                    <MenuItem value="one-time">One-Time</MenuItem>
                    <MenuItem value="monthly">Monthly</MenuItem>
                    <MenuItem value="quarterly">Quarterly</MenuItem>
                    <MenuItem value="yearly">Yearly</MenuItem>
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Currency</InputLabel>
                  <Select
                    value={newBudget.currency}
                    onChange={(e) => setNewBudget({ ...newBudget, currency: e.target.value })}
                    label="Currency"
                    required
                  >
                    <MenuItem value="USD">USD</MenuItem>
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} sm={6}>
                <LocalizationProvider dateAdapter={AdapterDateFns}>
                  <DatePicker
                    label="Start Date"
                    value={newBudget.start_date}
                    onChange={(newValue) => {
                      setNewBudget({ ...newBudget, start_date: newValue });
                      if (newBudget.end_date && newValue && new Date(newBudget.end_date) <= new Date(newValue)) {
                        setNewBudget(prev => ({ ...prev, end_date: null }));
                      }
                    }}
                    slotProps={{ 
                      textField: { 
                        fullWidth: true, 
                        required: true,
                        helperText: newBudget.frequency !== 'one-time' ? `Budget will start from the 1st of the selected month` : "Select start date"
                      } 
                    }}
                  />
                </LocalizationProvider>
              </Grid>

              <Grid item xs={12} sm={6}>
                <LocalizationProvider dateAdapter={AdapterDateFns}>
                  <DatePicker
                    label="End Date"
                    value={newBudget.end_date}
                    onChange={(newValue) => setNewBudget({ ...newBudget, end_date: newValue })}
                    slotProps={{ 
                      textField: { 
                        fullWidth: true, 
                        required: true,
                        helperText: newBudget.frequency !== 'one-time' ? `Budget will end on the last day of the selected month` : "Must be after start date"
                      } 
                    }}
                    minDate={newBudget.start_date ? new Date(newBudget.start_date) : undefined}
                  />
                </LocalizationProvider>
              </Grid>

              <Grid item xs={12}>
                <Button type="submit" variant="contained" color="primary">
                  Create Budget
                </Button>
              </Grid>
            </Grid>
          </form>
        </Paper>

        <Paper elevation={3} sx={{ p: 3, mt: 4 }}>
          <Typography variant="h6" gutterBottom>
            Active Budgets
          </Typography>

          {budgets.length === 0 ? (
            <Typography color="textSecondary" sx={{ py: 2 }}>
              No budgets found. Create your first budget above.
            </Typography>
          ) : (
            <Grid container spacing={2}>
              {budgets.map((budget) => (
                <Grid item xs={12} key={budget.id}>
                  <Paper elevation={1} sx={{ p: 2 }}>
                    <Grid container spacing={2} alignItems="center">
                      <Grid item xs={12} sm={3}>
                        <Typography variant="subtitle1">
                          {budget.name}
                        </Typography>
                      </Grid>
                      <Grid item xs={12} sm={2}>
                        <Typography>
                          {budget.total_limit} {budget.currency}
                          {budget.frequency !== 'one-time' && (
                            <Typography variant="caption" display="block">{budget.frequency}
                            </Typography>
                          )}
                        </Typography>
                      </Grid>
                      <Grid item xs={12} sm={3}>
                        <Typography>
                          {new Date(budget.start_date).toLocaleDateString()} - 
                          {new Date(budget.end_date).toLocaleDateString()}
                        </Typography>
                      </Grid>
                      <Grid item xs={12} sm={2}>
                        <Typography>
                          {budget.frequency}
                        </Typography>
                      </Grid>
                      <Grid item xs={12} sm={2}>
                        <Button
                          variant="outlined"
                          color="error"
                          size="small"
                          onClick={() => handleDelete(budget)}
                        >
                          Delete
                        </Button>
                      </Grid>
                    </Grid>
                  </Paper>
                </Grid>
              ))}
            </Grid>
          )}
        </Paper>
      </Box>
  );
};

export default Budget; 