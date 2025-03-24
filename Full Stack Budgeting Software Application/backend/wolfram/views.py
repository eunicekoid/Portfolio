from django.http import JsonResponse
from rest_framework.views import APIView
from .services import WolframAlphaAPI
class WolframAlphaQueryView(APIView):
    def get(self, request):
        query = request.GET.get("query")
        if not query:
            return JsonResponse({"error": "Missing query parameter"}, status=400)

        wolfram = WolframAlphaAPI()
        result = wolfram.query(query)

        if not result or "queryresult" not in result:
            return JsonResponse({"error": "Failed to fetch data from Wolfram Alpha"}, status=500)

        try:
            result_pod = next(pod for pod in result["queryresult"]["pods"] if pod["title"] == "Result")
            answer = result_pod["subpods"][0]["plaintext"]
        except (KeyError, IndexError, StopIteration):
            answer = "No valid result found."

        return JsonResponse({"answer": answer})
class CurrencyConversionView(APIView):
    def get(self, request):
        amount = request.GET.get("amount")
        from_currency = request.GET.get("from_currency")
        to_currency = request.GET.get("to_currency")

        if not all([amount, from_currency, to_currency]):
            return JsonResponse({"error": "Missing required parameters"}, status=400)

        wolfram = WolframAlphaAPI()
        conversion_result = wolfram.get_currency_conversion(amount, from_currency, to_currency)

        if conversion_result.startswith("Error"):
            return JsonResponse({"error": conversion_result}, status=500)

        return JsonResponse({"conversion_result": conversion_result})

class BudgetAnalysisView(APIView):
    def get(self, request):
        budget_amount = request.GET.get("amount")

        if not budget_amount:
            return JsonResponse({"error": "Missing budget amount"}, status=400)

        wolfram = WolframAlphaAPI()
        analysis_result = wolfram.get_budget_analysis(budget_amount)

        if analysis_result.startswith("Error"):
            return JsonResponse({"error": analysis_result}, status=500)

        return JsonResponse({"budget_analysis": analysis_result})
