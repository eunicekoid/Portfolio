import React, { useState, useEffect } from 'react';
import { Box, Button, TextField, Typography, FormControl, InputLabel, Select, MenuItem, Grid, Alert, Paper } from '@mui/material';
import { AdapterDateFns } from '@mui/x-date-pickers/AdapterDateFns';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import { format } from 'date-fns';

const Settings = () => {
  const [date, setDate] = useState("");
  const [categories, setCategories] = useState([]);
  const [subcategories, setSubcategories] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState('');
  const [selectedSubcategory, setSelectedSubcategory] = useState('');
  const [amount, setAmount] = useState('');
  const [description, setDescription] = useState('');
  const [startDate, setStartDate] = useState(null);
  const [endDate, setEndDate] = useState(null);
  const [dayOfMonth, setDayOfMonth] = useState('');
  const [frequency, setFrequency] = useState('monthly');
  const [currency, setCurrency] = useState('USD');
  const [alert, setAlert] = useState({ show: false, severity: 'success', message: '' });
  const [recurringTransactions, setRecurringTransactions] = useState([]);

  const token = localStorage.getItem('authToken');

  useEffect(() => {
    if (!token) {
      alert("You need to log in.");
      window.location.href = '/';
      return;
    }

    const today = new Date().toISOString().split("T")[0];
    setDate(today);

    fetchCategories();
    fetchRecurringTransactions();
  }, []);

  useEffect(() => {
    if (selectedCategory) {
      fetchSubcategories(selectedCategory);
    }
  }, [selectedCategory]);

  const fetchCategories = async () => {
    try {
      const response = await fetch("http://localhost:8000/categories/", {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        throw new Error("Failed to fetch categories");
      }

      const data = await response.json();
      console.log('Fetched categories:', data);

      if (Array.isArray(data)) {
        setCategories(data);
      } else {
        console.error("Categories response is not an array:", data);
        showAlert('error', 'Failed to load categories');
      }
    } catch (error) {
      console.error("Error fetching categories:", error);
      showAlert('error', 'Failed to fetch categories');
    }
  };

  const fetchSubcategories = async (categoryId) => {
    try {
      const response = await fetch(`http://localhost:8000/subcategories/?category_id=${categoryId}`, {
        method: "GET",
        credentials: "include",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        throw new Error("Failed to fetch subcategories");
      } 

      if (response.status === 401) {
        alert("Session expired. Please log in again.");
        window.location.href = "/";
        return;
      }

      const data = await response.json();
      setSubcategories(data);
    } catch (error) {
      console.error("Error fetching subcategories:", error);
    }
  };

  const fetchRecurringTransactions = async () => {
    try {
      const response = await fetch('http://localhost:8000/transactions/recurring-transactions/', {
        method: "GET",
        credentials: "include",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },  
      });

      if (!response.ok) {
        throw new Error("Failed to fetch recurring transactions");
      }

      if (response.status === 401) {
        alert("Session expired. Please log in again.");
        window.location.href = "/";
        return;
      }

      const data = await response.json();
      setRecurringTransactions(data);
    } catch (error) {
      console.error("Error fetching recurring transactions:", error);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!startDate || !endDate || !dayOfMonth || !amount || !selectedCategory) {
      showAlert('error', 'Please fill in all required fields');
      return;
    }

    try {
      // Validate day of month
      const dayNum = parseInt(dayOfMonth);
      if (dayNum < 1 || dayNum > 31) {
        showAlert('error', 'Day of month must be between 1 and 31');
        return;
      }

      const data = {
        category: parseInt(selectedCategory),
        subcategory: selectedSubcategory ? parseInt(selectedSubcategory) : null,
        amount_currency: parseFloat(amount),
        currency,
        description: description || "",
        start_date: format(startDate, 'yyyy-MM-dd'),
        end_date: format(endDate, 'yyyy-MM-dd'),
        day_of_month: dayNum,
        frequency
      };

      console.log('Sending data to server:', data);

      const response = await fetch('http://localhost:8000/transactions/recurring-transactions/', {
        method: "POST",
        credentials: "include",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      });

      const responseData = await response.json();
      console.log('Response status:', response.status);
      console.log('Response data:', responseData);

      if (!response.ok) {
        throw new Error(responseData.detail || responseData.message || JSON.stringify(responseData));
      }

      showAlert('success', 'Recurring transaction created successfully');
      fetchRecurringTransactions();
      resetForm();
    } catch (error) {
      console.error('Error creating recurring transaction:', error);
      showAlert('error', error.message || 'Failed to create recurring transaction');
    }
  };

  const handleDelete = async (id) => {
    try {
      const response = await fetch(`http://localhost:8000/transactions/recurring-transactions/${id}/`, {
        method: "DELETE",
        credentials: "include",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        throw new Error("Failed to delete recurring transaction");
      }

      if (response.status === 401) {
        alert("Session expired. Please log in again.");
        window.location.href = "/";
        return;
      }
      showAlert('success', 'Recurring transaction deleted successfully');
      fetchRecurringTransactions();
    } catch (error) {
      console.error('Error deleting recurring transaction:', error);
      showAlert('error', 'Failed to delete recurring transaction');
    }
  };

  const resetForm = () => {
    setSelectedCategory('');
    setSelectedSubcategory('');
    setAmount('');
    setDescription('');
    setStartDate(null);
    setEndDate(null);
    setDayOfMonth('');
    setFrequency('monthly');
    setCurrency('USD');
  };

  const showAlert = (severity, message) => {
    setAlert({ show: true, severity, message });
    setTimeout(() => setAlert({ show: false, severity: '', message: '' }), 5000);
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        {/* Settings */}
      </Typography>

      {alert.show && (
        <Alert severity={alert.severity} sx={{ mb: 2 }}>
          {alert.message}
        </Alert>
      )}

      <Paper elevation={3} sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          Create Recurring Transaction
        </Typography>

        <form onSubmit={handleSubmit}>
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Category</InputLabel>
                <Select
                  value={selectedCategory}
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  label="Category"
                  required
                >
                  {categories.map((category) => (
                    <MenuItem key={category.id} value={category.id}>
                      {category.category}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Subcategory</InputLabel>
                <Select
                  value={selectedSubcategory}
                  onChange={(e) => setSelectedSubcategory(e.target.value)}
                  label="Subcategory"
                >
                  <MenuItem value=""><em>Select a subcategory</em></MenuItem>
                  {subcategories.map((subcategory) => (
                    <MenuItem key={subcategory.id} value={subcategory.id}>
                      {subcategory.subcategory_name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Amount"
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                required
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Currency</InputLabel>
                <Select
                  value={currency}
                  onChange={(e) => setCurrency(e.target.value)}
                  label="Currency"
                  required
                >
                  <MenuItem value="USD">USD</MenuItem>
                  <MenuItem value="EUR">EUR</MenuItem>
                  <MenuItem value="GBP">GBP</MenuItem>
                </Select>
              </FormControl>
            </Grid>

            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                multiline
                rows={2}
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <LocalizationProvider dateAdapter={AdapterDateFns}>
                <DatePicker
                  label="Start Date"
                  value={startDate}
                  onChange={(newValue) => setStartDate(newValue)}
                  slotProps={{ textField: { fullWidth: true, required: true } }}
                  minDate={new Date()}
                />
              </LocalizationProvider>
            </Grid>

            <Grid item xs={12} sm={6}>
              <LocalizationProvider dateAdapter={AdapterDateFns}>
                <DatePicker
                  label="End Date"
                  value={endDate}
                  onChange={(newValue) => setEndDate(newValue)}
                  slotProps={{ textField: { fullWidth: true, required: true } }}
                  minDate={startDate || new Date()}
                />
              </LocalizationProvider>
            </Grid>

            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Day of Month"
                type="number"
                value={dayOfMonth}
                onChange={(e) => setDayOfMonth(e.target.value)}
                inputProps={{ min: 1, max: 31 }}
                required
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Frequency</InputLabel>
                <Select
                  value={frequency}
                  onChange={(e) => setFrequency(e.target.value)}
                  label="Frequency"
                  required
                >
                  <MenuItem value="monthly">Monthly</MenuItem>
                  <MenuItem value="quarterly">Quarterly</MenuItem>
                  <MenuItem value="yearly">Yearly</MenuItem>
                </Select>
              </FormControl>
            </Grid>

            <Grid item xs={12}>
              <Button type="submit" variant="contained" color="primary">
                Create Recurring Transaction
              </Button>
            </Grid>
          </Grid>
        </form>
      </Paper>

      <Paper elevation={3} sx={{ p: 3, mt: 4 }}>
        <Typography variant="h6" gutterBottom>
          Active Recurring Transactions
        </Typography>

        <Grid container spacing={2}>
          {recurringTransactions.map((transaction) => (
            <Grid item xs={12} key={transaction.id}>
              <Paper elevation={1} sx={{ p: 2 }}>
                <Grid container spacing={2} alignItems="center">
                  <Grid item xs={12} sm={3}>
                    <Typography variant="subtitle1">
                      {categories.find(c => c.id === transaction.category)?.category || 'Loading...'}
                    </Typography>
                  </Grid>
                  <Grid item xs={12} sm={2}>
                    <Typography>
                      {transaction.amount_currency} {transaction.currency}
                    </Typography>
                  </Grid>
                  <Grid item xs={12} sm={3}>
                    <Typography>
                      {transaction.frequency} (Day {transaction.day_of_month})
                    </Typography>
                  </Grid>
                  <Grid item xs={12} sm={3}>
                    <Typography>
                      {new Date(transaction.start_date).toLocaleDateString()} - 
                      {new Date(transaction.end_date).toLocaleDateString()}
                    </Typography>
                  </Grid>
                  <Grid item xs={12} sm={1}>
                    <Button
                      variant="outlined"
                      color="error"
                      size="small"
                      onClick={() => handleDelete(transaction.id)}
                    >
                      Delete
                    </Button>
                  </Grid>
                </Grid>
              </Paper>
            </Grid>
          ))}
        </Grid>
      </Paper>
    </Box>
  );
};

export default Settings;