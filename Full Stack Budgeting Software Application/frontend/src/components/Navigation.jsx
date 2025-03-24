import React from 'react';
import { Link as RouterLink, useNavigate } from 'react-router-dom';
import { AppBar, Toolbar, Button, Typography, Box } from '@mui/material';
import { Settings as SettingsIcon, Logout as LogoutIcon, Home as HomeIcon, Add as AddIcon } from '@mui/icons-material';

const Navigation = () => {
  const navigate = useNavigate();
  const token = localStorage.getItem('token');

  const handleLogout = () => {
    localStorage.removeItem('token');
    navigate("/", { replace: true });
  };

  if (!token) {
    return null;
  }

  return (
    <AppBar position="static">
      <Toolbar>
        <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
        </Typography>
        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button
            color="inherit"
            component={RouterLink}
            to="/overview"
            startIcon={<HomeIcon />}
          >
            Overview
          </Button>
          <Button
            color="inherit"
            component={RouterLink}
            to="/input"
            startIcon={<AddIcon />}
          >
            Add 
          </Button>
          <Button
            color="inherit"
            component={RouterLink}
            to="/budgets"
            startIcon={<SettingsIcon />}
          >
            Budgets
          </Button>
          <Button
            color="inherit"
            component={RouterLink}
            to="/settings"
            startIcon={<SettingsIcon />}
          >
            Recurring
          </Button>
          <Button
            color="inherit"
            onClick={handleLogout}
            startIcon={<LogoutIcon />}
          >
            Logout
          </Button>
        </Box>
      </Toolbar>
    </AppBar>
  );
};

export default Navigation; 