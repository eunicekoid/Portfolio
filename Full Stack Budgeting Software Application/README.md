# **Personal Budgeting App**

## **Table of Contents**
1. [About the Application](#about-the-application)
2. [Features](#features)
3. [Technologies Used](#technologies-used)
4. [Installation](#installation)
5. [Usage](#usage)
6. [Configuration](#configuration)
7. [Project Structure](#project-structure)

## **About the Application**
**Personal Budgeting App** is a financial budgeting tool designed to help users track and manage their personal finances. This application provides an intuitive interface for budget planning, expense tracking, and financial analysis.

### **Target Users**
- Individuals looking to manage personal finances
- Budget-conscious users who want to track recurring expenses
- Users who travel frequently who need currency conversion
- Users who want to analyze their spending patterns

## **Features**
### **Key Features**
1. **Budget Management**
   - Set monthly budgets with customizable timeframes
   - Track budget progress in real-time
   - Visual indicators for budget status

2. **Transaction Management**
   - Add one-time and recurring transactions
   - Two-level categorization system
   - Automatic budget alignment
   - Detailed transaction history

3. **Recurring Transactions**
   - Set up monthly, quarterly, or yearly recurring expenses
   - Automatic transaction generation
   - Flexible date range selection
   - Easy modification of recurring transactions

4. **Currency Support**
   - Real-time currency conversion using ExchangeRate API
   - Support for multiple currencies
   - Automatic USD conversion for tracking

5. **Financial Overview**
   - Monthly budget tracking
   - Category-wise expense breakdown
   - Visual budget status indicators
   - Remaining budget calculations

6. **Smart Input Features**
   - Built-in mathematical expression evaluation
   - Wolfram Alpha API integration
   - Currency conversion on the fly

## **Technologies Used**
- **Backend**: Django, PostgreSQL (Database), Django REST Framework (API), JWT Authentication
- **Frontend**: React, Vite (Build tool), Material-UI (Component library), JavaScript 
- **APIs**
   - ExchangeRate API (Currency conversion). The app uses fallback rates when API limits are reached.
   - Wolfram Alpha API (Mathematical computations)
- **Development Tools**: Docker (Containerization), Postman (API testing), Git 
- **Deployment**: Docker, AWS (Cloud hosting)

## **Installation**

### **Prerequisites**
- Python 3.8+
- Node.js 14+
- Docker and Docker Compose
- Git

### **Local Installation**
1. **Clone the repository**
   ```bash
   git clone https://github.com/eunicekoid/euniceproj.git
   ```

2. **Set up Python environment**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **Run with Docker**
   ```bash
   docker-compose up --build
   ```

4. **Access the application**
   - Frontend: http://localhost:5173
   - Backend API: http://localhost:8000

### **Manual Installation (without Docker)**
1. **Set up the backend**
   ```bash
   cd backend
   python manage.py migrate
   python manage.py runserver
   ```

2. **Set up the frontend**
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

## **Usage**
1. **Initial Setup**: Create an account and log in

2. **Budget Management**: Navigate to the "Budgets" tab to create new budgets

3. **Transaction Management**
   - Use the "Add" tab for one-time transactions
   - Use the "Recurring" tab for recurring expenses
   - Enter amounts with mathematical expressions if needed
   - Select currencies for international transactions

4. **Financial Overview**
   - View your financial status in the "Overview" tab
   - Monitor budget utilization
   - Track category-wise expenses
   - Analyze spending patterns

## **Configuration**
### **Environment Variables**
Edit the `.env` file in the root directory with the following variables:
```env
EXCHANGE_RATE_API_KEY=your_exchange_rate_api_key
WOLFRAM_APP_ID=your_wolfram_alpha_app_id
```

### **API Keys Setup**
1. **ExchangeRate API**: Sign up at [ExchangeRate API](https://app.exchangerate-api.com/sign-up). Add your API key to the `.env` file.

2. **Wolfram Alpha API**: Sign up at [Wolfram Alpha Developer Portal](https://developer.wolframalpha.com/). Get your App ID, and ad it to the `.env` file.

## **Project Structure**

```
euniceproj/
│
├── backend/ 
│   ├── accounts/          
│   │   ├── apps.py     
│   │   ├── serializers.py
│   │   ├── tests.py
│   │   ├── urls.py
│   │   └── views.py          
│   │ 
│   ├── budgets_app/         
│   │   ├── apps.py    
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── tests.py
│   │   ├── urls.py
│   │   └── views.py          
│   │ 
│   ├── categories_app/         
│   │   ├── apps.py    
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── tests.py
│   │   ├── urls.py
│   │   └── views.py    
│   │ 
│   ├── euniceproj/         
│   │   ├── settings.py    
│   │   └── urls.py
│   │ 
│   ├── reports_app/         
│   │   ├── urls.py    
│   │   └── views.py
│   │ 
│   ├── subcategories_app/         
│   │   ├── apps.py    
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── tests.py
│   │   ├── urls.py
│   │   └── views.py   
│   │ 
│   ├── transactions_app/         
│   │   ├── apps.py    
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── tests.py
│   │   ├── urls.py
│   │   └── views.py  
│   │ 
│   ├── wolfram/         
│   │   ├── apps.py    
│   │   ├── services.py
│   │   ├── tests.py
│   │   ├── urls.py
│   │   └── views.py 
│   │ 
│   ├── manage.py  
│   ├── requirements.txt 
│   ├── setup_data.py
│   ├── setup.sh  
│   └── test_setup_data.py
│
├── frontend/  
│   ├── public/
│   ├── src/
│   │   ├── __tests__/   
│   │   │   └── Login.test.jsx
│   │   │
│   │   ├── components/  
│   │   │   ├── Layout.jsx
│   │   │   └── Navigation.jsx
│   │   │
│   │   ├── pages/  
│   │   │   ├── Budgets.jsx
│   │   │   ├── Input.jsx
│   │   │   ├── Login.jsx
│   │   │   ├── Overview.jsx
│   │   │   └── Settings.jsx
│   │   │
│   │   ├── App.css       
│   │   ├── App.jsx   
│   │   ├── index.css    
│   │   └── main.jsx  
│   │    
│   ├── Dockerfile      
│   ├── index.html       
│   ├── package.json    
│   ├── eslint.config.js      
│   └── vite.config.js    
│
├── .env   
├── requirements.txt         
├── docker-compose.yml  
└── README.md  
```