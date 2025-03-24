import requests
import os
from dotenv import load_dotenv
from django.conf import settings

load_dotenv()

WOLFRAM_API_URL = "http://api.wolframalpha.com/v2/query"

class WolframAlphaAPI:
    def __init__(self):
        self.app_id = os.getenv("WOLFRAM_APP_ID")  

    def query(self, input_query):
        params = {
            "input": input_query,
            "format": "plaintext",
            "output": "JSON",
            "appid": self.app_id
        }
        try:
            response = requests.get(WOLFRAM_API_URL, params=params)
            # print("Wolfram Alpha Response:", response.json())
            response.raise_for_status()  
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error with Wolfram Alpha API: {e}")
            return None

    def get_currency_conversion(self, amount, from_currency, to_currency):
        query = f"{amount} {from_currency} to {to_currency}"
        result = self.query(query)
        if result:
            try:
                return result["queryresult"]["pods"][1]["subpods"][0]["plaintext"]
            except (KeyError, IndexError):
                return "Conversion not available"
        return "Error retrieving conversion."

    def get_budget_analysis(self, budget_amount):
        query = f"analyze {budget_amount} budget"
        result = self.query(query)
        if result:
            try:
                return result["queryresult"]["pods"][0]["subpods"][0]["plaintext"]
            except (KeyError, IndexError):
                return "No analysis available"
        return "Error retrieving budget analysis."
