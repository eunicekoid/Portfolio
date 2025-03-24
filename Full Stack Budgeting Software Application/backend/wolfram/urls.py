from django.urls import path
from .views import WolframAlphaQueryView, CurrencyConversionView, BudgetAnalysisView

urlpatterns = [
    path("query/", WolframAlphaQueryView.as_view(), name="query"),
    path("convert-currency/", CurrencyConversionView.as_view(), name="convert_currency"),
    path("analyze-budget/", BudgetAnalysisView.as_view(), name="analyze_budget"),
]
