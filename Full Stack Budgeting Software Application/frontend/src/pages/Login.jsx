import React, { useState } from "react";
import { Container, TextField, Button, Typography, Box, Paper, Grid, Alert } from "@mui/material";
import { useNavigate } from "react-router-dom"; 

const Login = ({ onLogin }) => {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [showSignup, setShowSignup] = useState(false);
  const navigate = useNavigate();
  
  const handleLogin = async () => {
    setError("");
    try {
      const response = await fetch("http://localhost:8000/accounts/login/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
        credentials: "include",
      });
  
      const data = await response.json();
      console.log("Login response:", data);
  
      if (data.access_token) {
        localStorage.setItem("authToken", data.access_token); 
        localStorage.setItem("username", username);
        console.log("Token saved:", localStorage.getItem("authToken")); 
  
        alert("Login successful!");
        onLogin(data.access_token); 
        // window.location.href = "/overview"; 
        navigate("/overview");
      } else {
        setError("Invalid credentials. No matching user found.");
      }
    } catch (err) {
      console.error("Login error:", err);
      setError("Something went wrong. Please try again.");
    }
  };
  
  

  const handleSignup = async () => {
    setError("");
    try {
      const response = await fetch("http://localhost:8000/accounts/signup/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });

      const data = await response.json();
      if (response.ok) {
        alert("Signup successful! Logging in now...");
        handleLogin(); 
      } else {
        setError(data.error || "Signup failed. Try a different username.");
      }
    } catch (err) {
      setError("Something went wrong. Please try again.");
    }
  };
 

  return (
    <Box 
      sx={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh', 
        width: '100%', 
        maxWidth: '100%',
        p: 3,
        fontFamily: 'Verdana, sans-serif',
        position: 'relative',
        backgroundColor: '#f0f0f0',
      }}
    >
      <Paper 
        elevation={3} 
        sx={{ 
          p: 3, 
          width: '100%', 
          maxWidth: '100%',
          display: 'flex', 
          flexDirection: 'column', 
          alignItems: 'center', 
          fontFamily: 'Verdana, sans-serif', 
          boxSizing: 'border-box',
          backgroundColor: 'white'
        }}
      >
        {/* Title at the top */}
        <Typography variant="h4" gutterBottom sx={{ textAlign: 'center' }}>
          {showSignup ? "Sign Up" : "Login"}
        </Typography>
  
        {/* Display error if any */}
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}
  
        {/* Form */}
        <form onSubmit={handleLogin}>
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
                sx={{ mb: 2 }}
              />
            </Grid>
  
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                sx={{ mb: 2 }}
              />
            </Grid>
  
            <Grid item xs={12}>
              <Button
                fullWidth
                variant="contained"
                color="primary"
                onClick={showSignup ? handleSignup : handleLogin}
              >
                {showSignup ? "Sign Up" : "Login"}
              </Button>
            </Grid>
  
            {/* Show Sign Up or Login Link */}
            {!showSignup && (
              <Grid item xs={12} sx={{ mt: 2 }}>
                <Typography variant="body2" sx={{ color: "black", textAlign: 'center' }}>
                  Don't have an account?{" "}
                  <Button color="secondary" onClick={() => setShowSignup(true)}>
                    Sign up here
                  </Button>
                </Typography>
              </Grid>
            )}
  
            {showSignup && (
              <Grid item xs={12} sx={{ mt: 2 }}>
                <Typography variant="body2" sx={{ color: "black", textAlign: 'center' }}>
                  Already have an account?{" "}
                  <Button color="secondary" onClick={() => navigate('/')}>
                    Return to login page
                  </Button>
                </Typography>
              </Grid>
            )}
          </Grid>
        </form>
      </Paper>
    </Box>
  );
};

export default Login;
