from django.urls import path
from .views import OverviewDataView

urlpatterns = [
    path('overview-data/', OverviewDataView.as_view(), name='overview-data'),
]