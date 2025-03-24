import React, { useState, useEffect } from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import Login from './pages/Login';
import Overview from './pages/Overview';
import Input from './pages/Input';
import Settings from './pages/Settings';
import Budget from './pages/Budgets';
import Navigation from './components/Navigation';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

const App = () => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [redirectToOverview, setRedirectToOverview] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem("token");
    if (token) {
      setIsAuthenticated(true);  
    }
  }, []);

  const handleLogin = (token) => {
    localStorage.setItem("token", token);
    setIsAuthenticated(true);
    setRedirectToOverview(true);  
  };

  const handleLogout = () => {
    localStorage.removeItem("token");
    setIsAuthenticated(false);
    setRedirectToOverview(false);  
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        {isAuthenticated && <Navigation />}

        <Routes>
          <Route
            path="/"
            element={
              isAuthenticated && redirectToOverview ? (
                <Navigate to="/overview" replace />
              ) : (
                <Login onLogin={handleLogin} />
              )
            }
          />
          <Route
            path="/overview"
            element={isAuthenticated ? <Overview /> : <Navigate to="/" />}
          />
          <Route
            path="/input"
            element={isAuthenticated ? <Input /> : <Navigate to="/" />}
          />
          <Route
            path="/settings"
            element={isAuthenticated ? <Settings /> : <Navigate to="/" />}
          />
          <Route
            path="/budgets"
            element={isAuthenticated ? <Budget /> : <Navigate to="/" />}
          />
        </Routes>
      </Router>
    </ThemeProvider>
  );
};

export default App;
