import React, { useState, useEffect } from 'react';
import { Container, Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, Box } from '@mui/material';

const Overview = () => {
    const [monthlyData, setMonthlyData] = useState({});
    const [months, setMonths] = useState([]);
    const [categories, setCategories] = useState([]);
    const [username, setUsername] = useState('');
    const [authToken, setAuthToken] = useState('');
    const [lastUpdate, setLastUpdate] = useState(0);

    const fetchOverviewData = async (token) => {
        try {
            console.log('Fetching overview data...');
            const response = await fetch('http://localhost:8000/reports/overview-data/', {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json',
                },
            });

            if (response.status === 401) {
                alert('Session expired. Please log in again.');
                window.location.href = '/';
                return;
            }

            const data = await response.json();
            console.log('Received overview data:', data);
            setMonthlyData(data.monthly_data);
            setMonths(data.months);
            
            // Get categories from all months
            const allCategories = new Set();
            Object.values(data.monthly_data).forEach(monthData => {
                console.log('Processing month data:', monthData);
                Object.keys(monthData).forEach(key => {
                    if (key !== 'budget' && key !== 'Recurring') {
                        console.log('Adding category:', key);
                        allCategories.add(key);
                    }
                });
            });
            const sortedCategories = Array.from(allCategories).sort();
            console.log('Updated categories:', sortedCategories);
            setCategories(sortedCategories);

        } catch (error) {
            console.error('Error fetching overview data:', error);
        }
    };

    // Effect for initial setup and token management
    useEffect(() => {
        console.log('Initial setup effect running...');
        const token = localStorage.getItem('authToken');
        if (!token) {
            alert('You need to log in to access this page.');
            window.location.href = '/';
            return;
        }
        setAuthToken(token);
        const storedUsername = localStorage.getItem('username');
        if (storedUsername) {
            setUsername(storedUsername);
        }
        
        const forceRefresh = localStorage.getItem('forceRefresh');
        console.log('Force refresh flag:', forceRefresh);
        if (forceRefresh) {
            localStorage.removeItem('forceRefresh');  
            setTimeout(() => {
                setLastUpdate(Date.now());  
            }, 100);
        } else {
            fetchOverviewData(token);
        }
    }, []); 

    useEffect(() => {
        console.log('Update effect running, lastUpdate:', lastUpdate);
        if (lastUpdate > 0) {  
            const token = localStorage.getItem('authToken');
            if (token) {
                fetchOverviewData(token);
            }
        }
    }, [lastUpdate]);

    useEffect(() => {
        const handleFocus = () => {
            setLastUpdate(Date.now());
        };

        window.addEventListener('focus', handleFocus);
        return () => window.removeEventListener('focus', handleFocus);
    }, []);

    const calculateRemaining = (month) => {
        if (!monthlyData[month]) return 0;

        const budget = parseFloat(monthlyData[month].budget) || 0;
        let totalExpenses = 0;
        let variableExpenses = 0;
        let recurringExpenses = 0;

        // Add variable expenses
        Object.entries(monthlyData[month]).forEach(([key, value]) => {
            if (key !== 'budget' && key !== 'Recurring') {
                const amount = parseFloat(value) || 0;
                variableExpenses += amount;
                // console.log(`${month} - ${key}: ${amount}`);
            }
        });

        // Add recurring expenses
        if (monthlyData[month]?.Recurring) {
            Object.entries(monthlyData[month].Recurring).forEach(([key, value]) => {
                const amount = parseFloat(value) || 0;
                recurringExpenses += amount;
                // console.log(`${month} - Recurring ${key}: ${amount}`);
            });
        }

        totalExpenses = variableExpenses + recurringExpenses;
        const remaining = Math.round(budget - totalExpenses);
        
        // console.log(`${month} Summary:`);
        // console.log(`Budget: ${budget}`);
        // console.log(`Variable Expenses: ${variableExpenses}`);
        // console.log(`Recurring Expenses: ${recurringExpenses}`);
        // console.log(`Total Expenses: ${totalExpenses}`);
        // console.log(`Remaining: ${remaining}`);
        
        return remaining;
    };

    const formatNumber = (value) => {
        return value ? value.toLocaleString() : '0';
    };

    return (
        <Container maxWidth="lg" sx={{ backgroundColor: '#f9f9f9', minHeight: '100vh', padding: 3 }}>
            <Box sx={{ backgroundColor: 'white', padding: 3, borderRadius: 2, boxShadow: 3 }}>
                {username && (
                    <Typography variant="h6" sx={{ mb: 4 }}>
                        {username}'s Overview
                    </Typography>
                )}
                
                <Paper elevation={3} sx={{ p: 3 }}>

                <TableContainer component={Paper}>
                    <Table>
                        <TableHead>
                            <TableRow sx={{ backgroundColor: '#e0f7fa' }}>
                                <TableCell sx={{ fontWeight: 'bold' }}>Month</TableCell>
                                {months.map((month) => (
                                    <TableCell key={month} sx={{ fontWeight: 'bold' }}>
                                        {month}
                                    </TableCell>
                                ))}
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            <TableRow sx={{ fontWeight: 'bold' }}>
                                <TableCell>Budget</TableCell>
                                {months.map((month) => (
                                    <TableCell key={month} sx={{ textAlign: 'center' }}>
                                        {formatNumber(monthlyData[month]?.budget)}
                                    </TableCell>
                                ))}
                            </TableRow>

                            <TableRow>
                                <TableCell colSpan={months.length + 1} sx={{ fontWeight: 'bold', textAlign: 'left', pt: 3, pb: 1 }}>
                                    Recurring Expenses
                                </TableCell>
                            </TableRow>

                            {/* Display the subcategories of the 'Recurring' category */}
                            {monthlyData[months[0]]?.Recurring && Object.keys(monthlyData[months[0]].Recurring).map((subcategory) => (
                                <TableRow key={subcategory}>
                                    <TableCell sx={{ textAlign: 'left' }}>{subcategory}</TableCell>
                                    {months.map((month) => (
                                        <TableCell key={month} sx={{ textAlign: 'center' }}>
                                            {formatNumber(monthlyData[month]?.Recurring?.[subcategory] || 0)}
                                        </TableCell>
                                    ))}
                                </TableRow>
                            ))}

                            <TableRow>
                                <TableCell colSpan={months.length + 1} sx={{ fontWeight: 'bold', textAlign: 'left', pt: 3, pb: 1 }}>
                                    Variable Expenses
                                </TableCell>
                            </TableRow>

                            {/* Variable expenses categories, excluding Recurring */}
                            {categories.sort().map((category) => {
                                console.log(`Rendering category row: ${category}`);
                                console.log(`Category data for all months:`, months.map(month => ({
                                    month,
                                    value: monthlyData[month]?.[category] || 0
                                })));
                                return (
                                    <TableRow key={category}>
                                        <TableCell sx={{ textAlign: 'left' }}>{category}</TableCell>
                                        {months.map((month) => {
                                            const value = monthlyData[month]?.[category] || 0;
                                            console.log(`  ${month} - ${category}: ${value}`);
                                            return (
                                                <TableCell key={month} sx={{ textAlign: 'center' }}>
                                                    {formatNumber(value)}
                                                </TableCell>
                                            );
                                        })}
                                    </TableRow>
                                );
                            })}

                            <TableRow sx={{ fontWeight: 'bold', borderTop: '2px solid black' }}>
                                <TableCell><b>REMAINING</b></TableCell>
                                {months.map((month) => {
                                    const remainingValue = calculateRemaining(month);
                                    console.log(`Remaining for ${month}:`, {
                                        budget: monthlyData[month]?.budget,
                                        expenses: Object.entries(monthlyData[month] || {})
                                            .filter(([key]) => key !== 'budget' && key !== 'Recurring')
                                            .reduce((sum, [_, value]) => sum + parseFloat(value || 0), 0),
                                        recurring: Object.values(monthlyData[month]?.Recurring || {})
                                            .reduce((sum, value) => sum + parseFloat(value || 0), 0),
                                        remaining: remainingValue
                                    });
                                    const isNegative = remainingValue < 0;
                                    return (
                                        <TableCell
                                            key={month}
                                            sx={{
                                                textAlign: 'center',
                                                backgroundColor: isNegative ? '#ffebee' : 'transparent',
                                                color: isNegative ? 'red' : 'black',
                                                fontWeight: isNegative ? 'bold' : 'normal',
                                            }}
                                        >
                                            {formatNumber(remainingValue)}
                                        </TableCell>
                                    );
                                })}
                            </TableRow>
                        </TableBody>
                    </Table>
                </TableContainer>
                </Paper>
            </Box>
        </Container>
    );
};

export default Overview;