import React, { useState, useEffect } from "react";
import { Box, Button, Container, TextField, Typography, FormControl, InputLabel, Select, MenuItem, Grid, Alert, Paper } from '@mui/material';

const InputTransaction = () => {
  const [date, setDate] = useState("");
  const [categories, setCategories] = useState([]);
  const [subcategories, setSubcategories] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState("");
  const [selectedSubcategory, setSelectedSubcategory] = useState("");
  const [amount, setAmount] = useState("");
  const [currency, setCurrency] = useState("USD");
  const [description, setDescription] = useState("");
  const [alert, setAlert] = useState({ show: false, severity: 'success', message: '' });
  const [isCalculating, setIsCalculating] = useState(false);
  const [debounceTimer, setDebounceTimer] = useState(null);

  const supportedCurrencies = [
      "AFN", "ALL", "DZD", "AOA", "ARS", "AMD", "AWG", "AUD", "AZN", "BAM", 
      "BBD", "BDT", "BGN", "BHD", "BIF", "BMD", "BND", "BOB", "BRL", "BSD", 
      "BTN", "BWP", "BYN", "BZD", "CAD", "CDF", "CHF", "CLP", "CNY", "COP", 
      "CRC", "CUP", "CVE", "CZK", "DJF", "DKK", "DOP", "DZD", "EGP", "ERN", 
      "ETB", "EUR", "FJD", "FKP", "FOK", "GBP", "GEL", "GHS", "GIP", "GMD", 
      "GNF", "GTQ", "GYD", "HKD", "HNL", "HRK", "HTG", "HUF", "IDR", "ILS", 
      "INR", "IQD", "IRR", "ISK", "JMD", "JOD", "JPY", "KES", "KGS", "KHR", 
      "KMF", "KPW", "KRW", "KWD", "KYD", "KZT", "LAK", "LBP", "LKR", "LRD", 
      "LSL", "LTL", "LVL", "LYD", "MAD", "MDL", "MGA", "MKD", "MMK", "MNT", 
      "MOP", "MUR", "MVR", "MWK", "MXN", "MYR", "MZN", "NAD", "NGN", "NIO", 
      "NOK", "NPR", "NZD", "OMR", "PAB", "PEN", "PGK", "PHP", "PKR", "PLN", 
      "PYG", "QAR", "RON", "RSD", "RUB", "RWF", "SAR", "SBD", "SCR", "SDG", 
      "SEK", "SGD", "SHP", "SLL", "SOS", "SPL", "SRD", "SSP", "STN", "SYP", 
      "SZL", "THB", "TJS", "TMT", "TND", "TOP", "TRY", "TTD", "TWD", "TZS", 
      "UAH", "UGX", "USD", "UYU", "UZS", "VEF", "VND", "VUV", "WST", "XAF", 
      "XCD", "XOF", "XPF", "YER", "ZAR", "ZMW", "ZWL"
  ];

  const token = localStorage.getItem("authToken");

  useEffect(() => {
    if (!token) {
      showAlert('error', "You need to log in.");
      window.location.href = '/';
      return;
    }

    const today = new Date().toISOString().split("T")[0];
    setDate(today);

    fetchCategories();
  }, [token]);

  const showAlert = (severity, message) => {
    setAlert({ show: true, severity, message });
    setTimeout(() => setAlert({ show: false, severity: '', message: '' }), 5000);
  };

  const fetchCategories = async () => {
    if (!token) {
      console.error("No auth token found in localStorage");
      showAlert('error', "You need to log in.");
      window.location.href = "/";
      return;
    }

    try {
      const response = await fetch("http://localhost:8000/categories/", {
        method: "GET",
        credentials: "include",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      if (response.status === 401) {
        showAlert('error', "Session expired. Please log in again.");
        window.location.href = "/";
        return;
      }

      const data = await response.json();
      if (Array.isArray(data)) {
        setCategories(data);
      } else {
        console.error("Categories response is not an array.");
        showAlert('error', "Error loading categories");
      }
    } catch (error) {
      console.error("Error fetching categories:", error);
      showAlert('error', "Error loading categories");
    }
  };

  const handleCategoryChange = (event) => {
    const categoryId = event.target.value;
    setSelectedCategory(categoryId);
    setSelectedSubcategory("");
    if(categoryId){
      fetchSubcategories(categoryId);
    } else {
      setSubcategories([])
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

      if (response.status === 401) {
        showAlert('error', "Session expired. Please log in again.");
        window.location.href = "/";
        return;
      }

      const data = await response.json();
      setSubcategories(data);
    } catch (error) {
      console.error("Error fetching subcategories:", error);
      showAlert('error', "Error loading subcategories");
    }
  };

  const evaluateExpression = async (expression) => {
    try {
      setIsCalculating(true);
      const response = await fetch(`http://localhost:8000/wolfram/query/?query=${encodeURIComponent(expression)}`, {
        method: "GET",
        credentials: "include",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        throw new Error('Failed to evaluate expression');
      }

      const data = await response.json();
      if (data.answer) {
        // Extract the numeric value from the answer
        const numericValue = parseFloat(data.answer.replace(/[^0-9.-]+/g, ''));
        if (!isNaN(numericValue)) {
          setAmount(numericValue.toString());
          showAlert('success', `Calculated result: ${numericValue}`);
        } else {
          showAlert('error', 'Invalid calculation result');
        }
      } else {
        showAlert('error', 'Could not evaluate expression');
      }
    } catch (error) {
      console.error('Error evaluating expression:', error);
      showAlert('error', 'Error evaluating expression');
    } finally {
      setIsCalculating(false);
    }
  };

  const handleAmountChange = (e) => {
    const value = e.target.value;
    setAmount(value);

    // Clear any existing timer
    if (debounceTimer) {
      clearTimeout(debounceTimer);
    }

    // Check if the input contains mathematical operators
    if (/[+\-*/()]/.test(value)) {
      // If the input ends with an operator, don't evaluate yet
      if (/[+\-*/]$/.test(value)) {
        return;
      }
      
      // If the input contains a complete expression, set a timer to evaluate it
      if (/^[\d\s+\-*/()]+$/.test(value)) {
        // Set a new timer for 3 seconds delay
        const timer = setTimeout(() => {
          evaluateExpression(value);
        }, 3000);
        setDebounceTimer(timer);
      }
    }
  };

  // Cleanup timer on component unmount
  useEffect(() => {
    return () => {
      if (debounceTimer) {
        clearTimeout(debounceTimer);
      }
    };
  }, [debounceTimer]);

  const handleSubmit = async (e) => {
    e.preventDefault();

    // Validate required fields
    if (!selectedCategory || !selectedSubcategory || !amount || !date) {
      showAlert('error', "Please fill in all required fields (Category, Subcategory, Amount, and Date)");
      return;
    }

    const transactionData = {
      date,
      category: selectedCategory,
      subcategory: selectedSubcategory,
      amount_currency: parseFloat(amount),
      currency,
      description,
    };

    try {
      const response = await fetch("http://localhost:8000/transactions/", {
        method: "POST",
        credentials: "include",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(transactionData),
      });

      const responseData = await response.json();

      if (response.ok) {
        showAlert('success', "Transaction added successfully!");
        // Reset form
        setAmount("");
        setDescription("");
        setSelectedCategory("");
        setSelectedSubcategory("");
        setCurrency("USD");
        setTimeout(() => {
          window.location.href = "/overview";
        }, 1000);
      } else {
        console.error('Server error:', responseData);
        showAlert('error', "Error adding transaction: " + JSON.stringify(responseData));
      }
    } catch (error) {
      console.error("Error submitting transaction:", error);
      showAlert('error', "Error submitting transaction");
    }
  };

  return (
    <Box 
      sx={{ 
        p: 3, 
        minHeight: "100vh", 
        display: "flex", 
        flexDirection: "column", 
        alignItems: "center", 
        justifyContent: "center",
        backgroundColor: "#f0f0f0",
        width: "100%"
      }}
    >
      <Typography variant="h4" gutterBottom>
        Add Transaction
      </Typography>

      {alert.show && (
        <Alert severity={alert.severity} sx={{ mb: 2, width: "100%" }}>
          {alert.message}
        </Alert>
      )}

      <Paper elevation={3} sx={{ p: 3, width: "100%" }}>
        <form onSubmit={handleSubmit}>
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                margin="normal"
                label="Date"
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                InputLabelProps={{ shrink: true }}
                required
              />
            </Grid>

            <Grid item xs={12}>
              <TextField
                select
                fullWidth
                margin="normal"
                label="Category"
                value={selectedCategory}
                onChange={handleCategoryChange}
                required
              >
                <MenuItem value="">
                  <em>Select a category</em>
                </MenuItem>
                {categories
                  .sort((a, b) => a.category.localeCompare(b.category))
                  .map((cat) => (
                    <MenuItem key={cat.id} value={cat.id}>
                      {cat.category}
                    </MenuItem>
                  ))}
              </TextField>
            </Grid>

            <Grid item xs={12}>
              <TextField
                select
                fullWidth
                margin="normal"
                label="Subcategory"
                value={selectedSubcategory}
                onChange={(e) => setSelectedSubcategory(e.target.value)}
                disabled={!selectedCategory}
                required
              >
                <MenuItem value="">
                  <em>Select a subcategory</em>
                </MenuItem>
                {subcategories.map((sub) => (
                  <MenuItem key={sub.id} value={sub.id}>
                    {sub.subcategory_name}
                  </MenuItem>
                ))}
              </TextField>
            </Grid>

            <Grid item xs={12}>
              <TextField
                fullWidth
                margin="normal"
                label="Amount"
                type="text"
                value={amount}
                onChange={handleAmountChange}
                required
                disabled={isCalculating}
                helperText="Enter a number or mathematical expression"
              />
            </Grid>

            <Grid item xs={4}>
              <TextField
                select
                fullWidth
                margin="normal"
                label="Currency"
                value={currency}
                onChange={(e) => setCurrency(e.target.value)}
                required
              >
                {supportedCurrencies.map((curr) => (
                  <MenuItem key={curr} value={curr}>
                    {curr}
                  </MenuItem>
                ))}
              </TextField>
            </Grid>

            <Grid item xs={12}>
              <TextField
                fullWidth
                margin="normal"
                label="Description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                multiline
                rows={2}
              />
            </Grid>

            <Grid item xs={12}>
              <Button type="submit" variant="contained" color="primary" fullWidth>
                Add Transaction
              </Button>
            </Grid>
          </Grid>
        </form>
      </Paper>
    </Box>
  );
};

export default InputTransaction;
