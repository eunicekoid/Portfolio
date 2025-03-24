import React from 'react';
import { Container, Box } from '@mui/material';

const Layout = ({ children }) => {
  return (
    <Container
      maxWidth="sm"
      sx={{
        backgroundColor: "#f0f0f0",
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontFamily: "Verdana, sans-serif",
        textAlign: "center",
      }}
    >
      <Box
        sx={{
          backgroundColor: "white",
          padding: 3,
          borderRadius: 2,
          width: '100%',
          boxShadow: 3,
        }}
      >
        {children}
      </Box>
    </Container>
  );
};

export default Layout;
